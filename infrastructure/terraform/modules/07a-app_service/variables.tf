# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

/*
  PARAMETERS
  Here are all the variables a user can override.
*/

##########################
# Budget Configuration  ##
##########################

variable "contact_emails" {
  type        = list(string)
  description = "The list of email addresses to be used for contact information for the policy assignments."
}

variable "budget_scope" {
  type        = string
  description = "The scope of the budget. This can be either a subscription, a resource group, or a management group."
}

variable "website_run_from_package" {
  type        = string
  description = "Specifies if the demonstration web application runs from a package."
}

variable "windows_app_site_config" {
  type        = string
  description = "value"
}

variable "enable_private_endpoint" {
  type        = bool
  description = "Controls if a private end-point should be created."
}