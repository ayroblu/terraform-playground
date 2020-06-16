provider aws {
  region = "eu-west-2"
}

variable name {
  type    = string
  default = "my_lambda"
}

# Use the module
resource aws_lambda_function this {
  filename         = "${path.module}/lambda.zip"
  function_name    = var.name
  role             = aws_iam_role.this.arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("${path.module}/lambda.zip")
  runtime          = "nodejs12.x"
}

resource aws_iam_role this {
  name = var.name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

