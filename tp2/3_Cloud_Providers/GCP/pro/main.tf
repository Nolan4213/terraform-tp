provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

locals {
  name = "${var.project_name}-${var.environment}"

  common_labels = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
    os          = "rocky-linux-9-3"
  }
}

# Le fichier d'origine utilisait "attached_disk { size = ... type = ... }"
# sur google_compute_instance : ce bloc n'accepte en réalité qu'un
# "source" pointant vers un disque existant, pas des attributs de taille.
# Les disques doivent donc être créés comme ressources à part entière.
resource "google_compute_disk" "lvm" {
  count  = var.lvm_disk_count
  name   = "${local.name}-lvm-${count.index + 1}"
  zone   = var.gcp_zone
  type   = "pd-ssd"
  size   = var.lvm_disk_size_gb
  labels = local.common_labels
}

resource "google_compute_firewall" "ssh" {
  name    = "${local.name}-allow-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.admin_cidr]
  target_tags   = [local.name]
}

resource "google_compute_instance" "vm" {
  name = "${local.name}-vm"
  zone = var.gcp_zone

  # Type personnalisé : seul moyen d'obtenir exactement 2 vCPU / 2 Go RAM,
  # contrairement à "e2-medium" (2 vCPU / 4 Go) utilisé dans l'original.
  machine_type = "e2-custom-${var.machine_cpus}-${var.machine_memory_mb}"

  tags   = [local.name]
  labels = local.common_labels

  boot_disk {
    initialize_params {
      # Famille d'image plutôt qu'une version figée : récupère
      # automatiquement le dernier correctif Rocky Linux 9 disponible.
      image = "rocky-linux-cloud/rocky-linux-9"
      size  = var.boot_disk_size_gb
      type  = "pd-ssd"
    }
  }

  dynamic "attached_disk" {
    for_each = google_compute_disk.lvm
    content {
      source = attached_disk.value.id
    }
  }

  network_interface {
    network = "default"
    access_config {} # IP publique éphémère
  }

  metadata = {
    ssh-keys = "${var.ssh_username}:${var.ssh_public_key}"
  }
}
