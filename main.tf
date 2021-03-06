module "default_label" {
  source      = "git@github.com:GaiamTV/tf-null-label.git"
  enabled     = "${var.enabled}"
  namespace   = "${var.namespace}"
  environment = "${var.environment}"
  stage       = "${var.stage}"
  name        = "${var.name}"
  delimiter   = "${var.delimiter}"
  attributes  = "${var.attributes}"
  tags        = "${var.tags}"
}

resource "aws_s3_bucket" "default" {
  count         = "${var.enabled ? 1 : 0}"
  bucket        = "${module.default_label.id}"
  acl           = "${var.acl}"
  region        = "${var.region}"
  force_destroy = "${var.force_destroy}"
  policy        = "${var.policy}"

  versioning {
    enabled = "${var.versioning_enabled}"
  }

  lifecycle_rule {
    id      = "${module.default_label.id}"
    enabled = "${var.lifecycle_rule_enabled}"

    prefix = "${var.lifecycle_prefix}"
    tags   = "${var.lifecycle_tags}"

    noncurrent_version_expiration {
      days = "${var.noncurrent_version_expiration_days}"
    }

    dynamic "noncurrent_version_transition" {
      for_each = "${var.enable_glacier_transition ? [1] : []}"

      content {
        days          = "${var.noncurrent_version_transition_days}"
        storage_class = "GLACIER"
      }
    }

    transition {
      days          = "${var.standard_transition_days}"
      storage_class = "STANDARD_IA"
    }

    dynamic "transition" {
      for_each = "${var.enable_glacier_transition ? [1] : []}"

      content {
        days          = "${var.glacier_transition_days}"
        storage_class = "GLACIER"
      }
    }

    expiration {
      days = "${var.expiration_days}"
    }
  }

  # https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-encryption.html
  # https://www.terraform.io/docs/providers/aws/r/s3_bucket.html#enable-default-server-side-encryption
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "${var.sse_algorithm}"
        kms_master_key_id = "${var.kms_master_key_arn}"
      }
    }
  }

  tags = "${module.default_label.tags}"
}
