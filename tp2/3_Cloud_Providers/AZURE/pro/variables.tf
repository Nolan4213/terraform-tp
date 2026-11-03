variable "subscription_id" {
  description = "ID de l'abonnement Azure (az account show --query id -o tsv)"
  type        = string
}

variable "location" {
  description = "Région Azure de déploiement"
  type        = string
  # Les abonnements « Azure for Students » imposent une liste de régions et
  # n'ouvrent pas la série B en France Central : Norway East est la région
  # autorisée la plus proche où elle est disponible.
  default = "norwayeast"
}

variable "environment" {
  description = "Nom de l'environnement (dev, staging, prod...)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Nom du projet, utilisé pour préfixer et taguer les ressources"
  type        = string
  default     = "rocky-linux-tp"
}

variable "vm_size" {
  description = <<-EOT
    Taille de la VM. Azure ne propose pas de SKU exact 2 vCPU / 2 Go RAM :
    Standard_B2als_v2 (2 vCPU / 4 Go) est la plus proche disponible.
  EOT
  type        = string
  default     = "Standard_B2als_v2"
}

variable "admin_username" {
  description = "Utilisateur administrateur de la VM"
  type        = string
  default     = "rockyadmin"
}

variable "admin_ssh_public_key" {
  description = "Clé publique SSH utilisée pour l'authentification (pas de mot de passe)"
  type        = string
}

variable "admin_cidr" {
  description = "Bloc CIDR autorisé à se connecter en SSH (ex: votre IP publique en /32) — ne jamais laisser 0.0.0.0/0"
  type        = string
}

variable "rocky_image_version" {
  description = "Version de l'image Marketplace resf:rockylinux-x86_64:9-base (9.3 = 9.3.20231113, ou \"latest\")"
  type        = string
  default     = "9.3.20231113"
}

variable "os_disk_size_gb" {
  description = "Taille du disque OS en Go"
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
