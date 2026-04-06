# Secure Terraform Pipeline

CI/CD pipeline for infrastructure deployment with security built in. OIDC authentication (no static AWS keys in CI), Checkov policy scanning on every PR, drift detection, and approval gates for production changes.

## Architecture

```
  Developer          GitHub Actions          AWS
  ┌──────┐     ┌───────────────────┐     ┌──────────┐
  │ Push │────▶│ 1. Lint (tflint)  │     │          │
  │  PR  │     │ 2. Scan (Checkov) │     │  OIDC    │
  └──────┘     │ 3. Plan           │◀───▶│  Trust   │
               │ 4. Approval Gate  │     │          │
               │ 5. Apply          │────▶│ AWS Infra│
               └───────────────────┘     └──────────┘
                        │
                   ┌────▼────┐
                   │ Slack   │
                   │ Alert   │
                   └─────────┘
```

## Why This Matters

| Problem | Solution |
|---|---|
| Static AWS keys in CI/CD | OIDC federation — GitHub assumes IAM role, no secrets stored |
| Insecure Terraform pushed to prod | Checkov scans every PR — blocks misconfigurations before merge |
| Config drift undetected | Scheduled drift detection — alerts when manual changes happen |
| No audit trail for infra changes | Every change goes through PR with plan output as comment |

## Structure

```
.
├── README.md
├── architecture.png
├── .github/
│   └── workflows/
│       ├── terraform-pr.yml       # PR: lint → scan → plan → comment
│       ├── terraform-apply.yml    # Merge to main: apply with approval
│       └── drift-detection.yml    # Scheduled: detect manual changes
├── terraform/
│   ├── main.tf
│   ├── providers.tf               # OIDC provider config
│   ├── backend.tf                 # S3 + DynamoDB state locking
│   ├── variables.tf
│   └── environments/
│       ├── dev.tfvars
│       ├── staging.tfvars
│       └── prod.tfvars
├── oidc/
│   ├── github-oidc-provider.tf    # IAM OIDC identity provider
│   ├── github-actions-role.tf     # Role with scoped permissions
│   └── trust-policy.json          # Restricts to specific repo/branch
├── checkov/
│   ├── .checkov.yml               # Custom policy config
│   └── custom-policies/
│       ├── require-encryption.py  # All resources must be encrypted
│       └── deny-public-access.py  # No public S3, no 0.0.0.0/0 SGs
└── docs/
    ├── oidc-setup.md              # How OIDC replaces static keys
    └── checkov-policies.md        # Custom policy documentation
```

## OIDC — How It Works

```
GitHub Actions                     AWS
┌────────────┐                ┌────────────────┐
│ Workflow    │──── JWT ──────▶│ IAM OIDC       │
│ requests   │                │ Provider       │
│ credentials│◀── Temp Creds──│ validates JWT  │
│            │                │ returns STS    │
└────────────┘                └────────────────┘
```

No AWS access keys stored in GitHub Secrets. The trust is established between GitHub's OIDC provider and an IAM role scoped to a specific repository and branch.

## Checkov Scan Output (Example)

```
Passed checks: 47
Failed checks: 0
Skipped checks: 2

Check: CKV_AWS_145: "Ensure S3 bucket has server-side encryption"
    PASSED for resource: aws_s3_bucket.state
Check: CKV_AWS_18: "Ensure the S3 bucket has access logging enabled"
    PASSED for resource: aws_s3_bucket.state
Check: CKV_AWS_21: "Ensure S3 bucket versioning is enabled"
    PASSED for resource: aws_s3_bucket.state
```

## Deployment

```bash
# 1. Bootstrap OIDC provider (run once from local)
cd oidc/
terraform init && terraform apply

# 2. All subsequent deploys happen via GitHub Actions
# Push to branch → PR → automated plan → review → merge → apply
```

## References

- [GitHub OIDC with AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [Checkov Documentation](https://www.checkov.io/1.Welcome/Quick%20Start.html)
- [Terraform State Security Best Practices](https://developer.hashicorp.com/terraform/language/settings/backends/s3)

---

*Built with Terraform + GitHub Actions | Zero static credentials*
