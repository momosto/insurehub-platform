# Cloudflare: proxied DNS for every public app on the k3s node, and Pages projects for the two SPAs.
terraform {
  required_version = ">= 1.6"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.48"
    }
  }
  backend "s3" {
    bucket                      = "insurehub-tfstate"
    key                         = "cloudflare/terraform.tfstate"
    region                      = "af-johannesburg-1"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
    use_path_style              = true
  }
}

provider "cloudflare" {
  # token from CLOUDFLARE_API_TOKEN (Zone:DNS:Edit, Account:Pages:Edit)
}

locals {
  # one A record per public endpoint served by Traefik on the node
  hosts = toset([
    "insurehub-api", "payments", "claimguard", "lendhub-api", "assist", "ussd", "argocd", "status",
  ])
}

resource "cloudflare_record" "app" {
  for_each = local.hosts
  zone_id  = var.zone_id
  name     = each.value
  type     = "A"
  content  = var.node_public_ip
  proxied  = true
  ttl      = 1
  comment  = "insurehub-platform (terraform)"
}

# SPAs on Cloudflare Pages (free, global CDN); built by each app repo's CI
resource "cloudflare_pages_project" "spa" {
  for_each          = var.pages_projects
  account_id        = var.account_id
  name              = each.key
  production_branch = "main"
  build_config {
    build_command   = each.value.build_command
    destination_dir = each.value.output_dir
    root_dir        = each.value.root_dir
  }
  deployment_configs {
    production {
      environment_variables = each.value.env
    }
  }
}

resource "cloudflare_pages_domain" "spa" {
  for_each     = var.pages_projects
  account_id   = var.account_id
  project_name = cloudflare_pages_project.spa[each.key].name
  domain       = "${each.value.subdomain}.${var.domain}"
}

resource "cloudflare_record" "spa" {
  for_each = var.pages_projects
  zone_id  = var.zone_id
  name     = each.value.subdomain
  type     = "CNAME"
  content  = "${each.key}.pages.dev"
  proxied  = true
  ttl      = 1
}

# Strict TLS end to end (cert-manager issues Let's Encrypt certificates on the node)
resource "cloudflare_zone_settings_override" "tls" {
  zone_id = var.zone_id
  settings {
    ssl                      = "strict"
    always_use_https         = "on"
    min_tls_version          = "1.2"
    automatic_https_rewrites = "on"
    security_header {
      enabled            = true
      max_age            = 31536000
      include_subdomains = true
      nosniff            = true
    }
  }
}
