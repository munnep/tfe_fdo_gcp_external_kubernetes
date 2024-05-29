
locals {
  namespace  = "terraform-enterprise"
  full_chain = "${acme_certificate.certificate.certificate_pem}${acme_certificate.certificate.issuer_pem}"
}


resource "kubernetes_namespace" "terraform-enterprise" {
  metadata {
    name = local.namespace
  }
}

resource "kubernetes_secret" "example" {
  metadata {
    name      = local.namespace
    namespace = local.namespace
  }

  data = {
    ".dockerconfigjson" = <<DOCKER
{
  "auths": {
    "images.releases.hashicorp.com": {
      "auth": "${base64encode("terraform:${var.tfe_license}")}"
    }
  }
}
DOCKER
  }

  type = "kubernetes.io/dockerconfigjson"
}

# # # optional code to use the local repository download of the helm chart
# # # resource "helm_release" "tfe" {
# # #   name      = "terraform-enterprise"
# # #   chart     = "${path.module}/terraform-enterprise-helm"
# # #   namespace = "terraform-enterprise"

# # #   values = [
# # #     "${file("${path.module}/overrides.yaml")}"
# # #   ]

# # #   depends_on = [
# # #     kubernetes_secret.example, kubernetes_namespace.terraform-enterprise
# # #   ]
# # # }

# # # The default for using the helm chart from internet
resource "helm_release" "tfe" {
  name       = local.namespace
  repository = "helm.releases.hashicorp.com"
  chart      = "hashicorp/terraform-enterprise"
  namespace  = local.namespace

  force_update = true
cleanup_on_fail = true
replace = true
  values = [
    templatefile("${path.module}/overrides.yaml", {
      replica_count = var.replica_count
      region        = data.terraform_remote_state.infra.outputs.region
      enc_password  = var.tfe_encryption_password
      pg_dbname     = data.terraform_remote_state.infra.outputs.pg_dbname
      pg_user       = data.terraform_remote_state.infra.outputs.pg_user
      pg_password   = data.terraform_remote_state.infra.outputs.pg_password
      pg_address    = data.terraform_remote_state.infra.outputs.pg_address
      fqdn          = "${var.dns_hostname}.${var.dns_zonename}"
      google_bucket = data.terraform_remote_state.infra.outputs.google_bucket
      gcp_project   = var.gcp_project
      cert_data     = "${base64encode(local.full_chain)}"
      key_data      = "${base64encode(nonsensitive(acme_certificate.certificate.private_key_pem))}"
      ca_cert_data  = "${base64encode(local.full_chain)}"
      redis_host    = data.terraform_remote_state.infra.outputs.redis_host
      redis_port    = data.terraform_remote_state.infra.outputs.redis_port
      tfe_license   = var.tfe_license
      tfe_release   = var.tfe_release
    })
  ]
  depends_on = [
    kubernetes_secret.example, kubernetes_namespace.terraform-enterprise
  ]
}

# data "kubernetes_service" "example" {
#   metadata {
#     name      = local.namespace
#     namespace = local.namespace
#   }
#   depends_on = [helm_release.tfe]
# }


# resource "aws_route53_record" "tfe" {
#   zone_id = data.aws_route53_zone.selected.zone_id
#   name    = var.dns_hostname
#   type    = "CNAME"
#   ttl     = "300"
#   records = [data.kubernetes_service.example.status.0.load_balancer.0.ingress.0.hostname]

#   depends_on = [helm_release.tfe]
# }

