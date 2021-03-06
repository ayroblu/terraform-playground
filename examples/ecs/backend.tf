terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "terraform-state-nsd9d3n"
    key            = "terraform-playground/examples/ecs"
    region         = "eu-west-2"
    dynamodb_table = "terraform-state-lock"
  }
}

