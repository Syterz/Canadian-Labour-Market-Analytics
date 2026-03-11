# Security

## Credentials & Secrets

No credentials, API keys, or secrets are hardcoded in this repository.

### AWS
- S3 bucket names are passed as job parameters in AWS Glue, not hardcoded
- AWS credentials are managed via IAM roles attached to the Glue job
- No AWS access keys are stored in code

### Databricks
- S3 paths are passed via Databricks widgets, not hardcoded
- AWS credentials for S3 access are configured via Databricks Secrets Manager
- No tokens or passwords are stored in notebooks

## What To Do If You Clone This Repo
- Create your own S3 bucket and update the path parameters accordingly
- Configure your own IAM role with S3 read/write permissions
- Set up your own Databricks secret scope for AWS credentials

## Reporting Security Issues
If you discover a security vulnerability, please open a GitHub issue.