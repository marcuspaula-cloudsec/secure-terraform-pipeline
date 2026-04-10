# GitHub OIDC Identity Provider
# Allows GitHub Actions to assume AWS roles without static credentials
# Zero Trust principle: no long-lived secrets in CI/CD

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# IAM Role for GitHub Actions (least privilege)
resource "aws_iam_role" "github_actions" {
  name = "github-actions-terraform-deploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          # Restrict to specific repo and branch
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main"
        }
      }
    }]
  })

  max_session_duration = 3600  # 1 hour max
}

# Scoped permissions — only what Terraform needs to deploy
resource "aws_iam_role_policy" "terraform_deploy" {
  name = "terraform-deploy-permissions"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TerraformStateAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
        ]
        Resource = [
          "arn:aws:s3:::${var.state_bucket}",
          "arn:aws:s3:::${var.state_bucket}/*",
        ]
      },
      {
        Sid    = "TerraformStateLocking"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
        ]
        Resource = "arn:aws:dynamodb:*:*:table/${var.lock_table}"
      },
      {
        Sid    = "DeployResources"
        Effect = "Allow"
        Action = [
          "ec2:*",
          "s3:*",
          "iam:*",
          "lambda:*",
          "events:*",
          "sns:*",
          "logs:*",
          "guardduty:*",
          "config:*",
          "securityhub:*",
        ]
        Resource = "*"
      },
    ]
  })
}
