resource aws_iam_user user {
  name = var.user_name
}
resource aws_iam_access_key user {
  user    = aws_iam_user.user.name
  pgp_key = "keybase:${var.keybase_name}"
}

resource aws_iam_user_group_membership user {
  user = aws_iam_user.user.name

  groups = var.groups
}
