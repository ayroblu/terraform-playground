output bastion {
  value = <<EOT
%{for ip in module.bastion.public_ips}
ssh ubuntu@${ip}
%{endfor}
EOT
}
output static_ip {
  value = "ssh ubuntu@${aws_eip.static_ip.public_ip}"
}
output random_instance_ip {
  value = "ssh ubuntu@${aws_instance.random_instance.private_ip}"
}
