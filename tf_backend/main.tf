terraform {
  backend "s3" {
    bucket = "terraform-state-nsd9d3n"
    key    = "terraform-course/demo4"
    region = "eu-west-2"
  }
}
