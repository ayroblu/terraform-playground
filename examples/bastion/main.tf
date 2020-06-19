provider aws {
  region = "eu-west-2"
}
module bastion {
  source          = "../../modules/bastion"
  vpc_id          = aws_vpc.main.id
  subnet_ids      = [aws_subnet.main-public-1.id]
  authorized_keys = file("ssh/authorized_keys")
}

