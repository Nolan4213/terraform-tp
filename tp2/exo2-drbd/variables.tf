variable "project_name" {
  description = "Préfixe des ressources"
  type        = string
  default     = "drbd-tp"
}

variable "admin_cidr" {
  description = "CIDR autorisé en SSH. Vide = IP publique détectée automatiquement (/32)"
  type        = string
  default     = ""
}

variable "ssh_public_key_path" {
  description = "Clé publique SSH injectée sur les deux VM"
  type        = string
  default     = "~/.ssh/tp_vm.pub"
}

variable "admin_username" {
  description = "Utilisateur administrateur (identique sur les deux VM)"
  type        = string
  default     = "rocky"
}

# ---------------------------------------------------------------- AWS
variable "aws_region" {
  description = "Région AWS"
  type        = string
  default     = "eu-west-3"
}

variable "aws_instance_type" {
  description = "Type d'instance. t3.micro = 2 vCPU / 1 Go, le moins cher éligible à l'offre gratuite"
  type        = string
  default     = "t3.micro"
}

# -------------------------------------------------------------- Azure
variable "azure_subscription_id" {
  description = "ID de l'abonnement Azure (az account show --query id -o tsv)"
  type        = string
}

variable "azure_location" {
  description = "Région Azure. Norway East : seule région autorisée par l'abonnement Student où la série B est disponible"
  type        = string
  default     = "norwayeast"
}

variable "azure_vm_size" {
  description = "Taille de VM. Standard_B2ats_v2 = 2 vCPU / 1 Go, la moins chère éligible à l'offre gratuite"
  type        = string
  default     = "Standard_B2ats_v2"
}

# --------------------------------------------------------------- DRBD
variable "data_disk_size_gb" {
  description = "Taille du disque de données (PV LVM) sur chaque VM, en Go"
  type        = number
  default     = 4
}

variable "drbd_lv_size" {
  description = "Taille du LV répliqué par DRBD. Petit = synchro initiale rapide et peu de trafic sortant facturé"
  type        = string
  default     = "1G"
}

variable "drbd_port" {
  description = "Port TCP de la ressource DRBD"
  type        = number
  default     = 7789
}
