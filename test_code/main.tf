terraform {
  cloud {
    hostname = "tfe29.aws.munnep.com"
    organization = "test"

    workspaces {
      name = "test"
    }
  }
}

resource "null_resource" "name" {
}