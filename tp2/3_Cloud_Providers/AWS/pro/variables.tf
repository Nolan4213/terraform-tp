variable "aws_region" {
  description = "Région AWS de déploiement"
  type        = string
  default     = "eu-west-3"
}

variable "vpc_cidr" {
  description = "Plage d'adresses du VPC dédié"
  type        = string
  default     = "10.0.0.0/16"
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

variable "instance_type" {
  description = "Type d'instance EC2. t3.small = 2 vCPU / 2 Go RAM, conforme au besoin"
  type        = string
  default     = "t3.small"
}

variable "rocky_ami_name_pattern" {
  description = <<-EOT
    Motif de nom de l'AMI Rocky Linux officielle (compte RESF 792107900819).
    Les AMI 9.3 ne sont plus publiées : Rocky ne maintient que la dernière
    version mineure de la branche 9, donc on prend la plus récente 9.x.
  EOT
  type        = string
  default     = "Rocky-9-EC2-Base-9.*"
}

variable "key_name" {
  description = "Nom de la paire de clés EC2 existante, utilisée pour l'accès SSH (pas de mot de passe)"
  type        = string
}

variable "admin_cidr" {
  description = "Bloc CIDR autorisé à se connecter en SSH (ex: votre IP publique en /32) — ne jamais laisser 0.0.0.0/0"
  type        = string
}

variable "root_volume_size" {
  description = "Taille du disque racine en Go"
  type        = number
  default     = 20
}

variable "lvm_disk_size" {
  description = "Taille de chaque disque dédié au LVM, en Go"
  type        = number
  default     = 20
}

variable "lvm_disk_count" {
  description = "Nombre de disques dédiés au LVM"
  type        = number
  default     = 2
}
