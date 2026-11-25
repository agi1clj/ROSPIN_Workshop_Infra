resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location

  tags = local.tags
}

module "container_registry" {
  source = "../../modules/container-registry"

  name                = local.acr_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.acr_sku
  tags                = local.tags
}

# The apps are created only after the first images exist in ACR (see docs/walkthrough.md, Step 6).
module "container_apps" {
  source = "../../modules/container-apps"
  count  = var.create_web_apps ? 1 : 0

  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  environment_name                = local.container_env_name
  identity_name                   = local.identity_name
  backend_app_name                = local.backend_app_name
  frontend_app_name               = local.frontend_app_name
  container_registry_id           = module.container_registry.id
  container_registry_login_server = module.container_registry.login_server
  tags                            = local.tags
}
