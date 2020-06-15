resource aws_s3_bucket backend {
  bucket = "terraform-state-nsd9d3n"
  acl    = "private"

  versioning {
    enabled = true
  }
  tags {
    Name = "backend bucket"
  }
}
