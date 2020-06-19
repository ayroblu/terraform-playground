# This is just for testing purposes
resource aws_instance random_instance {
  ami           = "ami-0eb89db7593b5d434"
  instance_type = "t2.micro"

  subnet_id = aws_subnet.main-private-1.id

  vpc_security_group_ids = [aws_security_group.allow-ssh.id]

  key_name = module.bastion.key_name

  tags = {
    Name = "random_internal_instance"
  }
}
resource "aws_security_group" "allow-ssh" {
  vpc_id      = aws_vpc.main.id
  name        = "allow-ssh"
  description = "security group that allows ssh and all egress traffic"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow-ssh"
  }
}

resource aws_eip static_ip {
  instance = module.bastion.bastion_id[0]
  vpc      = true
}
