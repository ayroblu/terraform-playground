resource aws_iam_user user {
  user_name = var.user_name
}
resource aws_iam_group admin_group {
  group_name = "admin"
}
resource "aws_iam_group_policy" "admin_policy" {
  name  = "admin_policy"
  group = "${aws_iam_group.admin_group.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:Describe*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
resource aws_iam_access_key user_access_key {
  user    = aws_iam_user.user.name
  pgp_key = "keybase:benlu"
}
