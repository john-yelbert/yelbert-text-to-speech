resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "audio" {
  bucket        = "${var.audio_bucket_name}-${random_id.bucket_suffix.hex}"
  force_destroy = true
}

resource "aws_s3_bucket" "frontend" {
  bucket        = "${var.frontend_bucket_name}-${random_id.bucket_suffix.hex}"
  force_destroy = true
}

# Disable block public access for static website hosting
resource "aws_s3_bucket_public_access_block" "frontend_pab" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Enable public access (only for static site hosting, otherwise use CloudFront!)
resource "aws_s3_bucket_policy" "frontend_policy" {
  depends_on = [aws_s3_bucket_public_access_block.frontend_pab]
  bucket     = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })
}

# Enable static website hosting
resource "aws_s3_bucket_website_configuration" "frontend_config" {
  bucket = aws_s3_bucket.frontend.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

output "website_endpoint" {
  value = aws_s3_bucket_website_configuration.frontend_config.website_endpoint
}