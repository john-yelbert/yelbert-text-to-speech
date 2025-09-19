variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "audio_bucket_name" {
  description = "S3 bucket name for storing audio files"
  type        = string
  default     = "yelbert-tts-audio-bucket"
}

variable "frontend_bucket_name" {
  description = "S3 bucket name for hosting static website"
  type        = string
  default     = "yelbert-tts-static-website-bucket"
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "yelbert-tts-lambda-function"
}

variable "api_gateway_name" {
  description = "Name of the API Gateway"
  type        = string
  default     = "yelbert-tts-api-gateway"
}

variable "lambda_execution_role_name" {
  description = "Name of the Lambda execution role"
  type        = string
  default     = "yelbert-tts-lambda-execution-role"
}

variable "lambda_policy_name" {
  description = "Name of the Lambda policy"
  type        = string
  default     = "yelbert-lambda-policy"
}