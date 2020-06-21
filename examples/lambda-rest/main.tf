# So much boilerplate, why not just use
# https://swizec.com/blog/typescript-serverless-lambda/swizec/9103
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

resource aws_api_gateway_rest_api example {
  name        = "ServerlessExample"
  description = "Terraform Serverless Application Example"
}

# ------------ GET /
resource aws_api_gateway_method root_get {
  rest_api_id   = aws_api_gateway_rest_api.example.id
  resource_id   = aws_api_gateway_rest_api.example.root_resource_id
  http_method   = "GET"
  authorization = "NONE"
}
resource aws_api_gateway_method_response resp_200 {
  rest_api_id = aws_api_gateway_rest_api.example.id
  resource_id = aws_api_gateway_method.root_get.resource_id
  http_method = aws_api_gateway_method.root_get.http_method

  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Cache-Control" = true
    "method.response.header.Content-Type"  = true
  }
}
resource aws_api_gateway_integration lambda {
  rest_api_id = aws_api_gateway_rest_api.example.id
  resource_id = aws_api_gateway_method.root_get.resource_id
  http_method = aws_api_gateway_method.root_get.http_method

  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.this.invoke_arn
}
resource aws_api_gateway_integration_response passthrough {
  rest_api_id = aws_api_gateway_rest_api.example.id
  resource_id = aws_api_gateway_rest_api.example.root_resource_id
  http_method = aws_api_gateway_method.root_get.http_method
  status_code = aws_api_gateway_method_response.resp_200.status_code

  response_parameters = {
    "method.response.header.Content-Type"  = "'application/json'",
    "method.response.header.Cache-Control" = "'no-store, must-revalidate'",
  }
  depends_on = [aws_api_gateway_method_response.resp_200]
}
# ------------ end

# ------------ GET /demo
resource aws_api_gateway_resource demo {
  rest_api_id = aws_api_gateway_rest_api.example.id
  parent_id   = aws_api_gateway_rest_api.example.root_resource_id
  path_part   = "demo"
}
resource aws_api_gateway_method demo_get {
  rest_api_id   = aws_api_gateway_rest_api.example.id
  resource_id   = aws_api_gateway_resource.demo.id
  http_method   = "GET"
  authorization = "NONE"
}
resource aws_api_gateway_method_response resp_demo_200 {
  rest_api_id = aws_api_gateway_rest_api.example.id
  resource_id = aws_api_gateway_resource.demo.id
  http_method = aws_api_gateway_method.demo_get.http_method

  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Cache-Control" = true
    "method.response.header.Content-Type"  = true
  }
}
resource aws_api_gateway_integration demo_lambda {
  rest_api_id = aws_api_gateway_rest_api.example.id
  resource_id = aws_api_gateway_resource.demo.id
  http_method = aws_api_gateway_method.demo_get.http_method

  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.this.invoke_arn
}
resource aws_api_gateway_integration_response demo_passthrough {
  rest_api_id = aws_api_gateway_rest_api.example.id
  resource_id = aws_api_gateway_resource.demo.id
  http_method = aws_api_gateway_method.demo_get.http_method
  status_code = aws_api_gateway_method_response.resp_demo_200.status_code

  response_parameters = {
    "method.response.header.Content-Type"  = "'application/json'",
    "method.response.header.Cache-Control" = "'no-store, must-revalidate'",
  }
  depends_on = [aws_api_gateway_method_response.resp_demo_200]
}
# ------------ end

# ============================ Deployment API Gateway
resource aws_api_gateway_deployment example {
  depends_on = [
    aws_api_gateway_integration.lambda,
  ]

  rest_api_id = aws_api_gateway_rest_api.example.id
  stage_name  = "alpha"

  # Need to redeploy everytime, can't tell if config has changed
  # Don't bother with hashing files because have to keep track
  # https://github.com/hashicorp/terraform/issues/6613
  variables = {
    deployed_at = timestamp()
  }
}
resource aws_lambda_permission apigw {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.example.execution_arn}/*/*"
}
output "base_url" {
  value = aws_api_gateway_deployment.example.invoke_url
}
