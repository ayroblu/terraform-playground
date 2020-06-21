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

module group_local_admin {
  source = "../modules/groups"
  name   = "local_admin"
  # Maybe should look at https://github.com/flosell/iam-policy-json-to-terraform
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
        }, {
        # https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_examples_aws_deny-requested-region.html
        Effect = "Deny"
        # Necessary because global things aren't in eu-west-2
        NotAction = [
          "cloudfront:*",
          "iam:*",
          "sts:*",
          "route53:*",
          "support:*"
        ],
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = [
              "eu-west-2"
            ]
          }
        }
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
      Resource = "arn:aws:iam::${aws_organizations_account.test_dev.id}:role/${module.role_dev_rw.name}"
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
      Resource = "arn:aws:iam::${aws_organizations_account.test_dev.id}:role/${module.role_dev_ro.name}"
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
    groups       = [module.group_local_admin.name]
  })
}

provider aws {
  region = "eu-west-2"
  alias  = "dev"

  assume_role {
    role_arn = "arn:aws:iam::${aws_organizations_account.test_dev.id}:role/admin"
  }
}

module role_dev_rw {
  providers = { aws = aws.dev }

  source      = "../modules/env_role"
  name        = "dev_rw"
  account_ids = [aws_organizations_account.test_ops.id]
  policy = jsonencode({
    Version : "2012-10-17"
    Statement : [{
      Effect   = "Allow"
      Action   = "*"
      Resource = "*"
      Condition = {
        StringEqualsIfExists = {
          "aws:RequestedRegion" = "eu-west-2"
        }
      }
      }, {
      Effect   = "Deny"
      Action   = ["iam:*", "cloudtrail:*", "workspaces:*"]
      Resource = "*"
    }]
  })
}

module role_dev_ro {
  providers = { aws = aws.dev }

  source      = "../modules/env_role"
  name        = "dev_ro"
  account_ids = [aws_organizations_account.test_ops.id]
  policy = jsonencode({
    Version : "2012-10-17"
    Statement : [{
      Effect   = "Deny"
      Action   = ["iam:*", "cloudtrail:*", "workspaces:*"]
      Resource = "*"
      }, {
      Effect   = "Deny"
      Action   = "*"
      Resource = "*"
      Condition = {
        StringNotEqualsIfExists = {
          "aws:RequestedRegion" = "eu-west-2"
        }
      }
    }]
  })
  policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
}
