variable "acr_sku" {
  description = "Azure Container Registry SKU."
  type        = string
  default     = "Basic"
}

variable "create_web_apps" {
  description = "Create the Container Apps environment and the two apps. Set to false only for the very first apply, before the first images exist in ACR."
  type        = bool
  default     = true
  nullable    = false
}

variable "environment" {
  description = "Environment name used in resource names and tags."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev"], var.environment)
    error_message = "Only the dev environment exists; add a new environments/<name> folder for others."
  }
}

variable "location" {
  description = "Azure region. Azure for Students subscriptions only allow a few regions (bootstrap.sh checks the policy)."
  type        = string
  default     = "germanywestcentral"
}

variable "project_name" {
  description = "Short project name used as a prefix in resource names."
  type        = string
  default     = "rospin"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,9}$", var.project_name))
    error_message = "Project name must be 2-10 lowercase letters/digits, starting with a letter."
  }
}

variable "team_id" {
  description = "Team code used in every resource name (2-5 lowercase letters/digits), e.g. agi."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,4}$", var.team_id))
    error_message = "Team code must be 2-5 lowercase letters/digits, starting with a letter, e.g. agi or t01."
  }
}

variable "subscription_id" {
  description = "Azure subscription ID to deploy into (not a secret; set by bootstrap.sh)."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.subscription_id))
    error_message = "Subscription ID must be a GUID."
  }
}
