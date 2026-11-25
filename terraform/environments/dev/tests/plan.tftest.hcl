# Offline tests: run with `terraform test`.
# The azurerm provider is mocked, so no Azure credentials are needed and nothing is created.
mock_provider "azurerm" {
  # Resource IDs are validated by the provider, so mocks must return well-formed IDs.
  mock_resource "azurerm_container_registry" {
    defaults = {
      id           = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-rospin-agi-dev/providers/Microsoft.ContainerRegistry/registries/acrmock"
      login_server = "acrmock.azurecr.io"
    }
  }

  mock_resource "azurerm_user_assigned_identity" {
    defaults = {
      id           = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-rospin-agi-dev/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-mock"
      principal_id = "00000000-0000-0000-0000-000000000001"
      client_id    = "00000000-0000-0000-0000-000000000002"
    }
  }

  mock_resource "azurerm_container_app_environment" {
    defaults = {
      id             = "/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-rospin-agi-dev/providers/Microsoft.App/managedEnvironments/cae-mock"
      default_domain = "happyfield-1234abcd.germanywestcentral.azurecontainerapps.io"
    }
  }
}

variables {
  team_id         = "agi"
  subscription_id = "11111111-2222-3333-4444-555555555555"
}

run "names_follow_convention" {
  command = apply # against the mocked provider only

  assert {
    condition     = azurerm_resource_group.main.name == "rg-rospin-agi-dev"
    error_message = "Unexpected resource group name: ${azurerm_resource_group.main.name}"
  }

  assert {
    condition     = can(regex("^acrrospinagidev[0-9a-f]{4}$", local.acr_name))
    error_message = "ACR name must be alphanumeric with a 4-character suffix: ${local.acr_name}"
  }

  assert {
    condition     = can(regex("^rospin-api-agi-dev-[0-9a-f]{4}$", local.backend_app_name))
    error_message = "Unexpected backend app name: ${local.backend_app_name}"
  }

  assert {
    condition     = can(regex("^rospin-ui-agi-dev-[0-9a-f]{4}$", local.frontend_app_name))
    error_message = "Unexpected frontend app name: ${local.frontend_app_name}"
  }
}

run "registry_only_first_stage" {
  command = plan

  variables {
    create_web_apps = false
  }

  assert {
    condition     = length(module.container_apps) == 0
    error_message = "Apps must not be planned while create_web_apps is false."
  }
}

run "container_apps_are_wired_together" {
  command = apply # against the mocked provider only

  assert {
    condition     = length(module.container_apps) == 1
    error_message = "create_web_apps = true must create the Container Apps module."
  }

  assert {
    condition     = output.frontend_url == "https://rospin-ui-agi-dev-e6d3.happyfield-1234abcd.germanywestcentral.azurecontainerapps.io"
    error_message = "Unexpected frontend URL: ${output.frontend_url}"
  }

  assert {
    condition     = output.backend_url == "https://rospin-api-agi-dev-e6d3.happyfield-1234abcd.germanywestcentral.azurecontainerapps.io"
    error_message = "Unexpected backend URL: ${output.backend_url}"
  }
}
