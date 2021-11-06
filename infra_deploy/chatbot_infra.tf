terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket = "<state_bucket_name>"
    key    = "chatbotinfrastate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}


module "s3-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "2.6.0"
  bucket= var.src_data_bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  force_destroy = true
}

resource "aws_s3_bucket_object" "glue_load_data" {
  key        = "data1.csv"
  bucket     = module.s3-bucket.s3_bucket_id
  source     = "${path.module}/data1.csv"
  etag       = filemd5("${path.module}/data1.csv")
}


#-------------------main dynamodb table for final record load
module "dynamodb_table" {
  source   = "terraform-aws-modules/dynamodb-table/aws"
  version = "1.1.0"

  for_each = toset( var.dyna_tables )

  name     = each.key
  hash_key = "date"

  billing_mode = "PROVISIONED"

  read_capacity = 10
  write_capacity = 10

  attributes = [
    {
      name = "date"
      type = "S"
    }
  ]

  tags = {
    Terraform   = "true"
  }
}

#-------------------end main dynamodb table for final record load



