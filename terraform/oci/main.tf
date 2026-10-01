# Oracle Cloud Always Free: one Ampere A1 VM (2 OCPU / 12 GB, the June 2026 allowance) running k3s, plus an
# Object Storage bucket for nightly backups. Network: HTTP/HTTPS public, SSH only from the admin CIDR, kube API not exposed.

terraform {
  required_version = ">= 1.6"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 6.20"
    }
  }
  # Remote state in OCI Object Storage through its S3-compatible API (bucket created once by hand, see README).
  backend "s3" {
    bucket                      = "insurehub-tfstate"
    key                         = "oci/terraform.tfstate"
    region                      = "af-johannesburg-1"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
    use_path_style              = true
    # endpoints.s3 = "https://<namespace>.compat.objectstorage.af-johannesburg-1.oraclecloud.com" via -backend-config
  }
}

provider "oci" {
  region = var.region
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

# Latest Canonical Ubuntu 24.04 image built for Arm (A1 is aarch64)
data "oci_core_images" "ubuntu_arm" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  shape                    = local.shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

locals {
  shape = "VM.Standard.A1.Flex"
  tags  = { project = "insurehub-platform", environment = "demo", managed_by = "terraform" }
}

resource "oci_core_vcn" "main" {
  compartment_id = var.compartment_ocid
  cidr_blocks    = ["10.20.0.0/16"]
  display_name   = "insurehub-vcn"
  dns_label      = "insurehub"
  freeform_tags  = local.tags
}

resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "insurehub-igw"
  freeform_tags  = local.tags
}

resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "insurehub-public-rt"
  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
  freeform_tags = local.tags
}

resource "oci_core_security_list" "node" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "insurehub-node-sl"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  # Web traffic (Cloudflare proxies in front; Let's Encrypt HTTP-01 needs port 80)
  dynamic "ingress_security_rules" {
    for_each = [80, 443]
    content {
      source   = "0.0.0.0/0"
      protocol = "6"
      tcp_options {
        min = ingress_security_rules.value
        max = ingress_security_rules.value
      }
    }
  }

  # SSH from the admin's address only; the Kubernetes API (6443) is reached through an SSH tunnel, never exposed
  ingress_security_rules {
    source   = var.admin_cidr
    protocol = "6"
    tcp_options {
      min = 22
      max = 22
    }
  }

  freeform_tags = local.tags
}

resource "oci_core_subnet" "public" {
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.main.id
  cidr_block        = "10.20.1.0/24"
  display_name      = "insurehub-public"
  dns_label         = "public"
  route_table_id    = oci_core_route_table.public.id
  security_list_ids = [oci_core_security_list.node.id]
  freeform_tags     = local.tags
}

resource "oci_core_instance" "node" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[var.availability_domain_index].name
  display_name        = "insurehub-k3s-1"
  shape               = local.shape

  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_gb
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu_arm.images[0].id
    boot_volume_size_in_gbs = var.boot_volume_gb
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public.id
    assign_public_ip = true
    hostname_label   = "k3s1"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(templatefile("${path.module}/../../bootstrap/cloud-init.yaml", {
      admin_user       = var.admin_user
      ssh_public_key   = var.ssh_public_key
      k3s_version      = var.k3s_version
      cluster_hostname = var.cluster_hostname
    }))
  }

  # The boot image changes often; don't replace the node just because Canonical published a newer one
  lifecycle {
    ignore_changes = [source_details[0].source_id, metadata["user_data"]]
  }

  freeform_tags = local.tags
}

data "oci_objectstorage_namespace" "ns" {
  compartment_id = var.compartment_ocid
}

resource "oci_objectstorage_bucket" "backups" {
  compartment_id = var.compartment_ocid
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = "insurehub-backups"
  access_type    = "NoPublicAccess"
  versioning     = "Enabled"
  freeform_tags  = local.tags
}

# Keep 30 days of nightly dumps (RPO 24 h; restore drill monthly)
resource "oci_objectstorage_object_lifecycle_policy" "backups" {
  namespace = data.oci_objectstorage_namespace.ns.namespace
  bucket    = oci_objectstorage_bucket.backups.name
  rules {
    name        = "expire-after-30-days"
    action      = "DELETE"
    is_enabled  = true
    time_amount = 30
    time_unit   = "DAYS"
    target      = "objects"
  }
}
