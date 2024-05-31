variable "tfe_password" {
  description = "password for tfe user"
}

variable "dns_hostname" {
  type        = string
  description = "DNS name you use to access the website"
}

variable "dns_zonename" {
  type        = string
  description = "DNS zone the record should be created in"
}

variable "tfe_release" {
  description = "Which release version of TFE to install"
}

variable "tfe_license" {
  description = "the TFE license as a string"
}

variable "aws_region" {
  description = "region to create the environment"
}

variable "certificate_email" {
  description = "email address to register the certificate"
}


variable "tfe_encryption_password" {
  description = "TFE encryption password"
}

variable "replica_count" { 
}
