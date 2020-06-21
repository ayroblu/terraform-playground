provider aws {
  region = "eu-west-2"
}

# https://hackernoon.com/terraform-with-aws-assume-role-21567505ea98
# Best practice to have completely separate dev, staging and prod accounts
# 1. Ops [Jump AWS account or I call it as Bastion AWS account]
# 2. Dev AWS account
# 3. Stage AWS account
# 4. Prod AWS account
# Groups
module group_admin {
  source = "../modules/groups"
  name   = "admin"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",
      "Resource": "*"
    }
  ]
}
EOF
}

module group_dev {
  source = "../modules/groups"
  name   = "admin"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": [
      "arn:aws:iam::${var.dev_account}:role/infra@dev",
    ]
  }
}

EOF
}

# Users
module "users" {
  source = "../modules/users"
  user_details = list({
    user_name    = "benlu"
    keybase_name = "benlu"
    groups       = [module.group_admin.name]
    }, {
    user_name    = "ayroblu"
    keybase_name = "ayroblu"
    groups       = [module.group_admin.name]
  })
}

