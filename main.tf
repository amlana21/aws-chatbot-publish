terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket = "<state_bucket_name>"
    key    = "chatbotterraappstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

module "s3-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "2.6.0"
  bucket= var.src_bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  force_destroy = true
}


module "security_components" {
    source = "./security-module"
}

module "chatbot-alert-lambda" {
    source = "./chatbot_lambda"

    lambda_role = module.security_components.lambda_role
    lambda_bucket=var.src_bucket
    err_sns_topic=resource.aws_sns_topic.chatbot_topic.arn
    depends_on = [module.security_components,module.s3-bucket,resource.aws_sns_topic.chatbot_topic]
}

#--------------------------sns topic for chatbot
resource "aws_sns_topic" "chatbot_topic" {
  name = "chatbot-topic"
}

resource "aws_cloudwatch_event_rule" "track_glue_job_state" {
  name        = "track_glue_job_state"
  description = "Capture Glue job state change"

  event_pattern = <<EOF
{
  "source": ["aws.glue"],
  "detail-type": ["Glue Job State Change"]
}
EOF
}

resource "aws_cloudwatch_event_target" "track_job_lambda" {
  arn  = module.chatbot-alert-lambda.lambda_arn
  rule = aws_cloudwatch_event_rule.track_glue_job_state.id
}





