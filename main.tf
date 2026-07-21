terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket = "nitin-cloud-resume-bucket-2026"
    key    = "terraform/state.tfstate"
    region = "eu-north-1"
  }
}

provider "aws" {
  region = "eu-north-1"
}

resource "aws_s3_bucket" "my_first_bucket" {
  bucket = "nitin-cloud-resume-bucket-2026"
}

resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.my_first_bucket.id
  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.my_first_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "allow_public_access" {
  bucket = aws_s3_bucket.my_first_bucket.id

  depends_on = [aws_s3_bucket_public_access_block.public_access]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.my_first_bucket.arn}/*"
      }
    ]
    }

  )


}

resource "aws_s3_object" "upload_index" {
  bucket       = aws_s3_bucket.my_first_bucket.id
  source       = "${path.module}/website/index.html"
  key          = "index.html"
  content_type = "text/html"
}

resource "aws_s3_object" "style" {
  bucket       = aws_s3_bucket.my_first_bucket.id
  key          = "style.css"
  source       = "${path.module}/website/style.css"
  content_type = "text/css"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.my_first_bucket.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.my_first_bucket.id}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.my_first_bucket.id}"

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  aliases = ["nitincloud.co.uk"]

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"

}

resource "aws_route53_zone" "primary" {
  name = "nitincloud.co.uk"

}

resource "aws_acm_certificate" "cert" {
  provider          = aws.us-east-1
  domain_name       = "nitincloud.co.uk"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.primary.zone_id

}

resource "aws_acm_certificate_validation" "cert" {
  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "nitincloud.co.uk"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }

}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.s3_distribution.id
}

resource "aws_dynamodb_table" "visitor_counter" {
  name         = "cloud-resume-counter"
  billing_mode = "PAY_PER_REQUEST" # This keeps it completely free unless millions of people visit
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S" # "S" means String data type
  }

  tags = {
    Environment = "production"
    Project     = "cloud-resume-challenge"
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda_function.py"
  output_path = "${path.module}/lambda/lambda_function.zip"
}

resource "aws_iam_role" "lambda_role" {
  name = "cloud-resume-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}


resource "aws_iam_role_policy" "lambda_inline_policy" {
  name = "cloud-resume-dynamodb-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:UpdateItem",
        "dynamodb:GetItem"
      ]
      Resource = aws_dynamodb_table.visitor_counter.arn
    }]
  })
}

resource "aws_lambda_function" "visitor_counter_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "visitor-counter-function"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler" # Looks for lambda_function.py -> lambda_handler function
  runtime          = "python3.11"

  lifecycle {
    ignore_changes = [
      source_code_hash,
    ]
  }
}

resource "aws_apigatewayv2_api" "lambda_api" {
  name          = "cloud-resume-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"] # Allows your resume domain to safely make calls
    allow_methods = ["GET", "OPTIONS"]
    allow_headers = ["content-type"]
  }
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.lambda_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.visitor_counter_lambda.arn
}

resource "aws_apigatewayv2_route" "lambda_route" {
  api_id    = aws_apigatewayv2_api.lambda_api.id
  route_key = "GET /"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_lambda_permission" "api_gw_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_counter_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.lambda_api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_stage" "lambda_stage" {
  api_id      = aws_apigatewayv2_api.lambda_api.id
  name        = "$default"
  auto_deploy = true
}

output "api_url" {
  value       = "${aws_apigatewayv2_api.lambda_api.api_endpoint}/"
  description = "The public HTTP URL for your visitor counter API"
}
