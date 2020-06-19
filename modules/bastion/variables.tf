variable ami {
  type        = string
  description = "The AMI code for an aws image"
  # The eu-west-2 ubuntu 18 image
  default = "ami-0eb89db7593b5d434"
}

variable subnet_ids {
  type        = list(string)
  description = "Where to host your bastion, public subnet only"
}
variable vpc_id {
  type        = string
  description = "What is your network vpc id"
}
variable authorized_keys {
  type        = string
  description = "file('path/to/authorized_keys')"
}
