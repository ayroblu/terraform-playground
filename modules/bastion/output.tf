output public_ips {
  value = aws_instance.bastion.*.public_ip
}
output key_name {
  value = aws_key_pair.bastion.key_name
}
output bastion_id {
  value = aws_instance.bastion.*.id
}
