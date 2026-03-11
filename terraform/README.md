# Terraform Infrastructure

This Terraform stack provisions local infrastructure for `dev`, `staging`, and `prod` using workspaces. It manages a Minikube profile, PostgreSQL container, Jenkins container, and shared Docker resources.

## Layout
- `modules/`: reusable infrastructure modules
- `env/`: environment-specific `tfvars`
- `terraform.tfstate.d/`: workspace-separated local state created by Terraform
- `state/`: placeholder directory for manual state backups

## Workspaces
Use these exact workspace names:
- `dev`
- `staging`
- `prod`

## Commands
```bash
cd terraform
terraform init
terraform workspace new dev || terraform workspace select dev
terraform plan -var-file=env/dev.tfvars
terraform apply -var-file=env/dev.tfvars
terraform output
terraform output -json > outputs-dev.json
```

Repeat with `staging` or `prod` by selecting the matching workspace and `tfvars` file.

## State Management
This stack uses the `local` backend. Terraform will keep workspace state under `terraform.tfstate.d/<workspace>/terraform.tfstate`.

The local backend does not provide native state locking. Treat Terraform operations as single-user and do not run concurrent `plan` or `apply` commands against the same workspace.

## Backup Procedure
1. Stop all Terraform activity for the target workspace.
2. Copy `terraform.tfstate`, `terraform.tfstate.d/`, and `.terraform/` metadata if present.
3. Store backups in a timestamped folder under `state/`, for example `state/2026-03-11-dev/`.
4. To restore, replace the workspace state file with the backup copy and rerun `terraform init`.

## CI/CD Output Retrieval
Use outputs to feed Jenkins and later Kubernetes stages:

```bash
terraform output
terraform output -json
terraform output -json > outputs-dev.json
```

Recommended Jenkins usage:
- parse `terraform output -json` with `jq`
- export `jenkins_url`, `postgres_connection_string`, `image_repository_prefix`, `minikube_kubeconfig_context`
- pass values into pipeline environment variables
