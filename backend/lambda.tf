resource "aws_lambda_function" "text_to_speech" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda.handler"
  runtime       = "python3.11"

  filename         = "lambda.zip"
  source_code_hash = filebase64sha256("lambda.zip")

  environment {
    variables = {
      AUDIO_BUCKET = aws_s3_bucket.audio.bucket
    }
  }
}