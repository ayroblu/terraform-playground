resource aws_instance bastion {
  count         = length(var.subnet_ids)
  ami           = var.ami
  instance_type = "t2.micro"

  subnet_id = var.subnet_ids[count.index]

  vpc_security_group_ids = [aws_security_group.bastion.id]

  user_data = <<EOT
#!/bin/bash
# upload my ssh public keys to terraform
echo "${file("${path.module}/ssh/mykey")}" > /home/ubuntu/.ssh/id_rsa
echo "${file("${path.module}/ssh/mykey.pub")}" > /home/ubuntu/.ssh/id_rsa.pub
echo "${var.authorized_keys}" > /home/ubuntu/.ssh/authorized_keys
chown ubuntu: /home/ubuntu/.ssh/authorized_keys
chmod 700 /home/ubuntu/.ssh
chmod 600 /home/ubuntu/.ssh/authorized_keys
EOT

  tags = {
    Name = "bastion_${count.index}"
  }
}

resource aws_key_pair bastion {
  key_name   = "bastion"
  public_key = file("${path.module}/ssh/mykey.pub")
}

resource aws_security_group bastion {
  vpc_id      = var.vpc_id
  name        = "ecs"
  description = "security group for ecs"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Internal Access
  #ingress {
  #  protocol    = -1
  #  from_port   = 0
  #  to_port     = 0
  #  cidr_blocks = [aws_vpc.main.cidr_block]
  #}

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion"
  }
}

