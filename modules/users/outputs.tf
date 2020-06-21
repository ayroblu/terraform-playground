output names {
  description = "names"
  value       = aws_iam_user.user.*.name
}
output access_key_ids {
  description = "access key ids"
  value       = aws_iam_access_key.user.*.id
}
output access_key_encrypted_secrets {
  description = "access key secrets"
  value       = aws_iam_access_key.user.*.encrypted_secret
}
