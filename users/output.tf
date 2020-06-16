output access_key_instructions {
  description = "access key instructions"
  value       = <<EOT
%{for id in module.users.access_key_ids}
=== ${module.users.names[index(module.users.access_key_ids, id)]} ===
 1. Install keybase and aws-vault
 2. Decrypt secret access key:
$ echo "${module.users.access_key_encrypted_secrets[index(module.users.access_key_ids, id)]}" | base64 --decode | keybase pgp decrypt
...secret_access_key...
 3. Execute command below:
$ aws-vault add example
 4. And input (stdin):
Enter Access Key ID: ${id}
Enter Secret Access Key: ...secret_access_key...
%{endfor}
EOT
}
