# 1. Install keybase and aws-vault
# 2. Decrypt secret access key:
#$ echo "${aws_iam_access_key.user.encrypted_secret}" | base64 --decode | keybase pgp decrypt
#...secret_access_key...
# 3. Execute command below:
#$ aws-vault add aiden
# 4. And input (stdin):
#Enter Access Key ID: ${aws_iam_access_key.user.id}
#Enter Secret Access Key: ...secret_access_key...

output access_key_encrypted_secret {
  description = "encrypted secret"
  value       = aws_iam_access_key.user.encrypted_secret
}
output access_key_id {
  description = "access key id"
  value       = aws_iam_access_key.user.id
}
