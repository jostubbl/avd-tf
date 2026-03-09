###############################################################################
# modules/identity/variables.tf – D1 Identity (Azure AD Domain Services)
###############################################################################

variable "resource_group_name" {
  description = "Name of the resource group for identity resources."
  type        = string
}

variable "location" {
  description = "Azure Government region for identity resources."
  type        = string
}

variable "identity_subnet_id" {
  description = "Resource ID of the dedicated Identity subnet (from hub-networking module)."
  type        = string
}

variable "deploy_aadds" {
  description = <<-EOT
    Deploy Azure Active Directory Domain Services (AADDS).
    Requires an Azure AD tenant with Premium P1 or P2 licenses.
    AADDS takes 30-45 minutes to provision.
    Set to false to skip AADDS deployment and manage identity externally.
  EOT
  type        = bool
  default     = false
}

variable "aadds_domain_name" {
  description = "FQDN of the managed AADDS domain (e.g. 'aadds.contoso.gov').  Required when deploy_aadds = true."
  type        = string
  default     = ""
}

variable "aadds_sku" {
  description = "AADDS SKU: Standard, Enterprise, or Premium.  Standard is sufficient for most AVD deployments."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Enterprise", "Premium"], var.aadds_sku)
    error_message = "aadds_sku must be 'Standard', 'Enterprise', or 'Premium'."
  }
}

variable "aadds_notification_emails" {
  description = "Additional e-mail addresses that receive AADDS health and alert notifications."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to all identity resources."
  type        = map(string)
  default     = {}
}
