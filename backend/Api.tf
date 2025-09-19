# Create REST API
resource "aws_api_gateway_rest_api" "text_to_speech_api" {
  name        = var.api_gateway_name
  description = "REST API for Text-to-Speech Lambda"
}

# Root resource (/speech)
resource "aws_api_gateway_resource" "speech" {
  rest_api_id = aws_api_gateway_rest_api.text_to_speech_api.id
  parent_id   = aws_api_gateway_rest_api.text_to_speech_api.root_resource_id
  path_part   = "speech"
}

# Method (POST /speech)
resource "aws_api_gateway_method" "post_speech" {
  rest_api_id   = aws_api_gateway_rest_api.text_to_speech_api.id
  resource_id   = aws_api_gateway_resource.speech.id
  http_method   = "POST"
  authorization = "NONE"
}

# Integration (Lambda backend)
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.text_to_speech_api.id
  resource_id             = aws_api_gateway_resource.speech.id
  http_method             = aws_api_gateway_method.post_speech.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.text_to_speech.invoke_arn
}

# Method response for POST
resource "aws_api_gateway_method_response" "post_response" {
  rest_api_id = aws_api_gateway_rest_api.text_to_speech_api.id
  resource_id = aws_api_gateway_resource.speech.id
  http_method = aws_api_gateway_method.post_speech.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

# Integration response for POST
resource "aws_api_gateway_integration_response" "post_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.text_to_speech_api.id
  resource_id = aws_api_gateway_resource.speech.id
  http_method = aws_api_gateway_method.post_speech.http_method
  status_code = aws_api_gateway_method_response.post_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  depends_on = [aws_api_gateway_integration.lambda_integration]
}

# Lambda permission (allow API Gateway to call it)
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.text_to_speech.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.text_to_speech_api.execution_arn}/*/*"
}

# Deployment
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_integration.options_integration,
    aws_api_gateway_method_response.post_response,
    aws_api_gateway_integration_response.post_integration_response
  ]

  rest_api_id = aws_api_gateway_rest_api.text_to_speech_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.speech.id,
      aws_api_gateway_method.post_speech.id,
      aws_api_gateway_method.options.id,
      aws_api_gateway_integration.lambda_integration.id,
      aws_api_gateway_integration.options_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Stage
resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.text_to_speech_api.id
  stage_name    = "prod"
}
# OPTIONS method for CORS
resource "aws_api_gateway_method" "options" {
  rest_api_id   = aws_api_gateway_rest_api.text_to_speech_api.id
  resource_id   = aws_api_gateway_resource.speech.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# Mock integration to handle OPTIONS
resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id = aws_api_gateway_rest_api.text_to_speech_api.id
  resource_id = aws_api_gateway_resource.speech.id
  http_method = aws_api_gateway_method.options.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# Method response
resource "aws_api_gateway_method_response" "options_response" {
  rest_api_id = aws_api_gateway_rest_api.text_to_speech_api.id
  resource_id = aws_api_gateway_resource.speech.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# Integration response
resource "aws_api_gateway_integration_response" "options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.text_to_speech_api.id
  resource_id = aws_api_gateway_resource.speech.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = aws_api_gateway_method_response.options_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# Output API endpoint
output "rest_api_endpoint" {
  value = "${aws_api_gateway_stage.prod.invoke_url}/speech"
}