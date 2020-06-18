provider aws {
  region = "eu-west-2"
}

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

