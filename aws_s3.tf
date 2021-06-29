module "s3_bucket_logs" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket_prefix                  = "${local.cluster_name}-logs-"
  acl                            = "log-delivery-write"
  attach_lb_log_delivery_policy  = true
  attach_elb_log_delivery_policy = true



  # S3 bucket-level Public Access Block configuration
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_kms_key" "splunk" {
  description             = "${local.cluster_name}-splunk-key"
  deletion_window_in_days = 10
}

data "aws_iam_policy_document" "s3_splunk_policy" {
  statement {
    sid    = "SmartStoreFullAccess"
    effect = "Allow"

    actions = [
      "s3:GetLifecycleConfiguration",
      "s3:DeleteObjectVersion",
      "s3:ListBucketVersions",
      "s3:GetBucketLogging",
      "s3:RestoreObject",
      "s3:ListBucket",
      "s3:GetBucketVersioning",
      "s3:PutObject",
      "s3:GetObject",
      "s3:PutLifecycleConfiguration",
      "s3:GetBucketCORS",
      "s3:DeleteObject",
      "s3:GetBucketLocation",
      "s3:GetObjectVersion"
    ]

    resources = ["${module.s3_bucket_splunk.s3_bucket_arn}/*", module.s3_bucket_splunk.s3_bucket_arn]
  }
  statement {
    sid    = "SmartStoreListBucket"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:HeadBucket"
    ]

    resources = [module.s3_bucket_splunk.s3_bucket_arn]
  }

  statement {
    sid    = "KMSEncryptDecrypt"
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:ReEncrypt*",
      "kms:DescribeKey"
    ]

    resources = [aws_kms_key.splunk.arn]
  }
}

resource "aws_iam_policy" "s3_splunk_policy" {
  name_prefix = "s3-splunk-s1-policy-${module.eks.cluster_id}"
  description = "Access to S3 for smartstore"
  policy      = data.aws_iam_policy_document.s3_splunk_policy.json
  #path        = var.iam_path
  #tags        = var.tags
}


module "s3_bucket_splunk" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket_prefix = "${local.cluster_name}-splunk-"

  acl = "private"

  versioning = {
    enabled = true
  }

  logging = {
    target_bucket = module.s3_bucket_logs.s3_bucket_id
    target_prefix = "log/s3/splunk"
  }



  # S3 bucket-level Public Access Block configuration
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}