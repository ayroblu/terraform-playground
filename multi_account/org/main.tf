# https://blog.kylegalbraith.com/2018/11/20/simplify-your-aws-billing-for-multiple-accounts-using-organizations/
provider aws {
  region  = "eu-west-2"
  profile = "ops"
}

# ------------- Accounts ----------------
resource aws_organizations_organization test_org {
  feature_set = "CONSOLIDATED_BILLING"
}

resource aws_organizations_account test_ops {
  name  = "test-ops"
  email = "test-ops@ayroblu.anonaddy.com"
}

resource aws_organizations_account test_dev {
  name      = "test-dev"
  email     = "aws-test-dev@ayroblu.anonaddy.com"
  role_name = "admin"
}

# --------------- Users -----------------
# # https://hackernoon.com/terraform-with-aws-assume-role-21567505ea98
# Best practice to have completely separate dev, staging and prod accounts
# 1. Ops [Jump AWS account or I call it as Bastion AWS account]
# 2. Dev AWS account
# 3. Stage AWS account
# 4. Prod AWS account
# Groups
module group_admin {
  source = "../modules/groups"
  name   = "infra_admin"
  # Maybe should look at https://github.com/flosell/iam-policy-json-to-terraform
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      }
    ]
  })
}

module group_dev_rw {
  source = "../modules/groups"
  name   = "dev_rw"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sts:AssumeRole"
      Resource = "arn:aws:iam::${aws_organizations_account.test_dev.id}:role/${aws_iam_role.dev_rw.name}"
    }]
  })
}

module group_dev_ro {
  source = "../modules/groups"
  name   = "dev_ro"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sts:AssumeRole"
      Resource = "arn:aws:iam::${aws_organizations_account.test_dev.id}:role/${aws_iam_role.dev_ro.name}"
    }]
  })
}

# Users
module users {
  source = "../modules/users"
  user_details = list({
    user_name    = "benlu"
    keybase_name = "benlu"
    groups       = [module.group_admin.name]
    }, {
    user_name    = "ayroblu"
    keybase_name = "ayroblu"
    groups       = [module.group_dev_ro.name]
  })
}

provider aws {
  region = "eu-west-2"
  alias  = "dev"

  assume_role {
    role_arn = "arn:aws:iam::${aws_organizations_account.test_dev.id}:role/admin"
  }
}

resource aws_iam_role dev_rw {
  name = "dev_rw"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        "AWS" = "arn:aws:iam::${aws_organizations_account.test_ops.id}:root"
      }
    }]
  })
  provider = aws.dev
}

resource aws_iam_role_policy dev_rw {
  name = "dev_rw"
  role = aws_iam_role.dev_rw.id

  policy = jsonencode({
    Version : "2012-10-17"
    Statement : [{
      Effect   = "Allow"
      Action   = "*"
      Resource = "*"
      }, {
      Effect   = "Deny"
      Action   = ["iam:*", "cloudtrail:*", "workspaces:*"]
      Resource = "*"
    }]
  })
  provider = aws.dev
}

resource aws_iam_role dev_ro {
  name = "dev_ro"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        "AWS" = "arn:aws:iam::${aws_organizations_account.test_ops.id}:root"
      }
    }]
  })
  provider = aws.dev
}

resource aws_iam_role_policy dev_ro {
  name = "dev_ro"
  role = aws_iam_role.dev_ro.id

  policy = jsonencode({
    Version : "2012-10-17"
    Statement : [{
      Effect   = "Deny"
      Action   = ["iam:*", "cloudtrail:*", "workspaces:*"]
      Resource = "*"
    }]
  })
  provider = aws.dev
}

resource aws_iam_role_policy_attachment dev_ro {
  role = aws_iam_role.dev_ro.id
  # Provided by AWS, managed policy
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  provider   = aws.dev
}
