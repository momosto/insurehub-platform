variable "zone_id" {
  type = string
}

variable "account_id" {
  type = string
}

variable "domain" {
  description = "e.g. insurehub.example.org"
  type        = string
}

variable "node_public_ip" {
  description = "Output node_public_ip from terraform/oci"
  type        = string
}

variable "pages_projects" {
  description = "Static front ends deployed to Cloudflare Pages"
  type = map(object({
    subdomain     = string
    root_dir      = string
    build_command = string
    output_dir    = string
    env           = map(string)
  }))
  default = {
    "insurehub-web" = {
      subdomain     = "www"
      root_dir      = "frontend"
      build_command = "npm ci && npm run build"
      output_dir    = "dist"
      env           = { VITE_API_URL = "https://insurehub-api.insurehub.example.org" }
    }
    "lendhub-web" = {
      subdomain     = "lendhub"
      root_dir      = "web"
      build_command = "npm ci && npx ng build --configuration production && echo \"window.__env = { apiUrl: 'https://lendhub-api.insurehub.example.org' };\" > dist/web/browser/env.js"
      output_dir    = "dist/web/browser"
      env           = {}
    }
  }
}
