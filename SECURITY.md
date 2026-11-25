# Security Policy

This is a teaching project. It contains no secrets: Azure access uses GitHub OIDC with a managed identity.

Found a vulnerability or a leaked credential? Do not open a public issue. Use **Security -> Report a vulnerability** on this repository (private vulnerability reporting).

Never commit `terraform.tfvars`, `backend.hcl`, `bootstrap.env`, Terraform state or `.env` files. They are in `.gitignore`.
