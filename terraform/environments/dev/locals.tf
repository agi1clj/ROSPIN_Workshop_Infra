locals {
  # Base used in all names: <project>-<initials>-<environment>, e.g. rospin-agi-dev.
  name_base = "${var.project_name}-${var.team_id}-${var.environment}"

  # ACR and container app names must be globally unique. Initials alone can collide between
  # students, so a short suffix is derived from the subscription ID. It is deterministic:
  # local runs and CI always compute the same names.
  unique_suffix = substr(sha1("${var.subscription_id}-${var.team_id}"), 0, 4)

  resource_group_name = "rg-${local.name_base}"
  acr_name            = "acr${replace(local.name_base, "-", "")}${local.unique_suffix}"
  container_env_name  = "cae-${local.name_base}"
  identity_name       = "id-${local.name_base}-apps"
  backend_app_name    = "${var.project_name}-api-${var.team_id}-${var.environment}-${local.unique_suffix}"
  frontend_app_name   = "${var.project_name}-ui-${var.team_id}-${var.environment}-${local.unique_suffix}"

  tags = {
    project     = var.project_name
    environment = var.environment
    owner       = var.team_id
    workshop    = "ROSPIN Space Talks"
    managed_by  = "terraform"
  }
}
