# DATA SOURCES (lookup existing info)

data "aws_caller_identity" "current" {

}

data "aws_region" "current" {

}

# LOCAL VARIABLES (computed values)

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name

  cloudtrail_bucket_name = "healthflow-cloudtrail-logs-${local.account_id}-${local.region}"
}

# S3 BUCKET FOR CLOUDTRAIL LOGS
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = local.cloudtrail_bucket_name

  tags = {
    Name       = "CloudTrail Organization Logs"
    Purpose    = "audit-logs"
    Compliance = "HIPAA"
    Retention  = "${var.cloud_trail_log_retention_days} days"
  }
}

# Block ALL public access (HIPAA requirement)
resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning (protects against accidental deletion)
resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption (HIPAA requirement)
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lifecycle policy (automatic deletion after retention period)
resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    id     = "delete-old-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = var.cloud_trail_log_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# S3 BUCKET POLICY (allows CloudTrail to write logs)
resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_logs.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_cloudtrail" "organization_trail" {
  name                          = "healthflow-organization-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  is_multi_region_trail         = true
  include_global_service_events = true
  is_organization_trail         = var.organization_id != "" ? true : false
  enable_log_file_validation    = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::*/"]
    }
  }

  insight_selector {
    insight_type = "ApiCallRateInsight"
  }

  tags = {
    Name       = "Organization Trail"
    Purpose    = "audit-logs"
    Compliance = "HIPAA"
  }

  depends_on = [aws_s3_bucket_policy.cloudtrail_logs]

}

# GUARDDUTY (intelligent threat detection)

resource "aws_guardduty_detector" "main" {
  count                        = var.enable_guardduty ? 1 : 0
  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = false
      }
    }

    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }

  tags = {
    Name    = "HealthFlow GuardDuty Detector"
    purpose = "threat-detection"
  }

}

# SECURITY HUB (compliance dashboard)

resource "aws_securityhub_account" "main" {
  count = var.enable_securityhub ? 1 : 0

  enable_default_standards = true
  auto_enable_controls     = true
  depends_on               = [aws_guardduty_detector.main]
}

resource "aws_securityhub_standards_subscription" "cis" {
  count         = var.enable_securityhub ? 1 : 0
  standards_arn = "arn:aws:securityhub:${local.region}::standards/cis-aws-foundations-benchmark/v/1.4.0"
  depends_on    = [aws_guardduty_detector.main]
}

resource "aws_securityhub_standards_subscription" "pci_dss" {
  count = var.enable_securityhub ? 1 : 0

  standards_arn = "arn:aws:securityhub:${local.region}::standards/pci-dss/v/3.2.1"

  depends_on = [aws_securityhub_account.main]
}

resource "aws_securityhub_finding_aggregator" "main" {
  count        = var.enable_securityhub ? 1 : 0
  linking_mode = "ALL_REGIONS"

  depends_on = [aws_securityhub_account.main]
}

# AWS CONFIG (resource configuration tracking)

resource "aws_config_configuration_recorder" "main" {
  count    = var.enable_config ? 1 : 0
  name     = "healthflow-config-recorder"
  role_arn = aws_iam_role.config[0].arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "main" {
  count = var.enable_config ? 1 : 0

  name           = "healthflow-config-delivery"
  s3_bucket_name = aws_s3_bucket.config_logs[0].id

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_configuration_recorder_status" "main" {
  count      = var.enable_config ? 1 : 0
  name       = aws_config_configuration_recorder.main[0].name
  is_enabled = true
  depends_on = [aws_config_configuration_recorder.main]
}

# S3 bucket for Config logs
resource "aws_s3_bucket" "config_logs" {
  count = var.enable_config ? 1 : 0

  bucket = "healthflow-config-logs-${local.account_id}"

  tags = {
    Name    = "AWS Config Logs"
    Purpose = "compliance-tracking"
  }
}

resource "aws_s3_bucket_public_access_block" "config_logs" {
  count = var.enable_config ? 1 : 0

  bucket = aws_s3_bucket.config_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM role for Config
resource "aws_iam_role" "config" {
  count = var.enable_config ? 1 : 0

  name = "healthflow-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "config.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "config" {
  count = var.enable_config ? 1 : 0

  role       = aws_iam_role.config[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/ConfigRole"
}

resource "aws_iam_role_policy" "config_s3" {
  count = var.enable_config ? 1 : 0

  name = "config-s3-policy"
  role = aws_iam_role.config[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:PutObject",
        "s3:GetBucketAcl"
      ]
      Resource = [
        aws_s3_bucket.config_logs[0].arn,
        "${aws_s3_bucket.config_logs[0].arn}/*"
      ]
    }]
  })
}