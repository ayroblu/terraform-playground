terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "terraform-state-11jnjrt91"
    key            = "terraform-playground/org"
    region         = "eu-west-2"
    dynamodb_table = "terraform-state-lock"
  }
}
