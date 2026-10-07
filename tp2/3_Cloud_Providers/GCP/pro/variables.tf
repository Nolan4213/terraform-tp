variable "gcp_project" {
  description = "ID du projet GCP (pas de valeur par défaut, propre à chaque compte)"
  type        = string
}

variable "gcp_region" {
  description = "Région GCP de déploiement"
  type        = string
  default     = "europe-west1"
}

variable "gcp_zone" {
  description = "Zone GCP de déploiement"
  type        = string
  default     = "europe-west1-b"
}

variable "environment" {
  description = "Nom de l'environnement (dev, staging, prod...)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Nom du projet, utilisé pour préfixer et étiqueter les ressources"
  type        = string
  default     = "rocky-linux-tp"
}

variable "machine_cpus" {
  description = "Nombre de vCPU (type personnalisé e2-custom)"
  type        = number
  default     = 2
}

variable "machine_memory_mb" {
  description = "RAM en Mo (type personnalisé e2-custom) — 2048 = 2 Go, conforme au besoin"
  type        = number
  default     = 2048
}

variable "ssh_username" {
  description = "Utilisateur administrateur créé via clé SSH"
  type        = string
  default     = "rockyadmin"
}

variable "ssh_public_key" {
  description = "Clé publique SSH utilisée pour l'authentification (pas de mot de passe)"
  type        = string
}

variable "admin_cidr" {
  description = "Bloc CIDR autorisé à se connecter en SSH (ex: votre IP publique en /32) — ne jamais laisser 0.0.0.0/0"
  type        = string
}

variable "boot_disk_size_gb" {
  description = "Taille du disque de boot en Go"
  type        = number
  default     = 20
}

variable "lvm_disk_size_gb" {
  description = "Taille de chaque disque dédié au LVM, en Go"
  type        = number
  default     = 20
}

variable "lvm_disk_count" {
  description = "Nombre de disques dédiés au LVM"
  type        = number
  default     = 2
}
