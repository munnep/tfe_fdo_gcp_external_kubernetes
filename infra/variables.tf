variable "tag_prefix" {
  description = "default prefix of names"
}

variable "vnet_cidr" {
  description = "which private subnet do you want to use for the VPC. Subnet mask of /16"
}

variable "gcp_region" {
  description = "region to create the environment"
}

variable "gcp_project" {
  description = "project for the resources to use"
}

variable "gcp_location" {
  description = "location where the bucket is stored"
}

variable "rds_password" {
  description = "password used to connect to database"
}