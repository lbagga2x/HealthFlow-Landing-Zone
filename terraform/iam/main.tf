# DATA SOURCES

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_organizations_organization" "main" {}

# LOCAL VARIABLES]
locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

# SCP 1: PREVENT CLOUDTRAIL DELETION
resource "aws_organizations_policy" "prevent_cloudtrail_deletion" {
  count = var.enable_scp_cloudtrail_protection ? 1 : 0

  name        = "prevent-cloudtrail-deletion"
  description = "Prevents anyone from disabling CloudTrail logging"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "PreventCloudTrailDeletion"
        Effect = "Deny"
        Action = [
          "cloudtrail:DeleteTrail",
          "cloudtrail:StopLogging",
          "cloudtrail:UpdateTrail"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name       = "Prevent CloudTrail Deletion"
    Purpose    = "audit-protection"
    Compliance = "HIPAA"
  }
}

resource "aws_organizations_policy_attachment" "prevent_cloudtrail_deletion" {
  count = var.enable_scp_cloudtrail_protection ? 1 : 0

  policy_id = aws_organizations_policy.prevent_cloudtrail_deletion[0].id
  target_id = var.organization_root_id
}

# SCP 2: REQUIRE ENCRYPTION
# ─────────────────────────────────────────

resource "aws_organizations_policy" "require_encryption" {
  count = var.enable_scp_encryption_enforcement ? 1 : 0

  name        = "require-encryption"
  description = "Requires encryption for S3 and RDS"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyUnencryptedS3Uploads"
        Effect   = "Deny"
        Action   = "s3:PutObject"
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = ["AES256", "aws:kms"]
          }
        }
      },
      {
        Sid    = "DenyUnencryptedRDS"
        Effect = "Deny"
        Action = [
          "rds:CreateDBInstance",
          "rds:CreateDBCluster"
        ]
        Resource = "*"
        Condition = {
          Bool = {
            "rds:StorageEncrypted" = "false"
          }
        }
      }
    ]
  })

  tags = {
    Name       = "Require Encryption"
    Purpose    = "data-protection"
    Compliance = "HIPAA"
  }
}

resource "aws_organizations_policy_attachment" "require_encryption" {
  count = var.enable_scp_encryption_enforcement ? 1 : 0

  policy_id = aws_organizations_policy.require_encryption[0].id
  target_id = var.organization_root_id
}

# SCP 3: RESTRICT REGIONS
# ─────────────────────────────────────────

resource "aws_organizations_policy" "restrict_regions" {
  count = var.enable_scp_region_restriction ? 1 : 0

  name        = "restrict-regions"
  description = "Restricts resource creation to approved regions"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyAllOutsideAllowedRegions"
        Effect = "Deny"
        NotAction = [
          "iam:*",
          "organizations:*",
          "route53:*",
          "cloudfront:*",
          "support:*",
          "sts:*"
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = var.allowed_regions
          }
        }
      }
    ]
  })

  tags = {
    Name    = "Restrict Regions"
    Purpose = "compliance"
  }
}

resource "aws_organizations_policy_attachment" "restrict_regions" {
  count = var.enable_scp_region_restriction ? 1 : 0

  policy_id = aws_organizations_policy.restrict_regions[0].id
  target_id = var.organization_root_id
}

# SCP 4: BLOCK PUBLIC S3 BUCKETS
# ─────────────────────────────────────────

resource "aws_organizations_policy" "block_public_s3" {
  count = var.enable_scp_public_s3_block ? 1 : 0

  name        = "block-public-s3"
  description = "Prevents making S3 buckets publicly accessible"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyPublicS3Buckets"
        Effect = "Deny"
        Action = [
          "s3:PutBucketPublicAccessBlock",
          "s3:PutAccountPublicAccessBlock"
        ]
        Resource = "*"
        Condition = {
          Bool = {
            "s3:BlockPublicAcls"       = "false"
            "s3:BlockPublicPolicy"     = "false"
            "s3:IgnorePublicAcls"      = "false"
            "s3:RestrictPublicBuckets" = "false"
          }
        }
      },
      {
        Sid    = "DenyPublicACLs"
        Effect = "Deny"
        Action = [
          "s3:PutBucketAcl",
          "s3:PutObjectAcl"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = [
              "public-read",
              "public-read-write",
              "authenticated-read"
            ]
          }
        }
      }
    ]
  })

  tags = {
    Name       = "Block Public S3"
    Purpose    = "data-protection"
    Compliance = "HIPAA"
  }
}

resource "aws_organizations_policy_attachment" "block_public_s3" {
  count = var.enable_scp_public_s3_block ? 1 : 0

  policy_id = aws_organizations_policy.block_public_s3[0].id
  target_id = var.organization_root_id
}

# SCP 5: REQUIRE MFA
# ─────────────────────────────────────────

resource "aws_organizations_policy" "require_mfa" {
  count = var.enable_scp_mfa_requirement ? 1 : 0

  name        = "require-mfa"
  description = "Requires MFA for console access and sensitive operations"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyAllWithoutMFA"
        Effect = "Deny"
        NotAction = [
          "iam:CreateVirtualMFADevice",
          "iam:EnableMFADevice",
          "iam:GetUser",
          "iam:ListMFADevices",
          "iam:ListVirtualMFADevices",
          "iam:ResyncMFADevice",
          "sts:GetSessionToken"
        ]
        Resource = "*"
        Condition = {
          BoolIfExists = {
            "aws:MultiFactorAuthPresent" = "false"
          }
        }
      }
    ]
  })

  tags = {
    Name       = "Require MFA"
    Purpose    = "access-control"
    Compliance = "HIPAA"
  }
}

resource "aws_organizations_policy_attachment" "require_mfa" {
  count = var.enable_scp_mfa_requirement ? 1 : 0

  policy_id = aws_organizations_policy.require_mfa[0].id
  target_id = var.organization_root_id
}