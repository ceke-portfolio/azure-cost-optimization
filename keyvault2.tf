# Reference an existing Azure Key Vault
data "azurerm_key_vault" "kv" {
  name                = "TerraformKeyVault325"
  resource_group_name = "EnterpriseRG"
}

# Retrieve the VM Admin Password from Key Vault
data "azurerm_key_vault_secret" "vm_password" {
  name         = "admin-password"  # Ensure this matches the actual stored secret name
  key_vault_id = data.azurerm_key_vault.kv.id
}
