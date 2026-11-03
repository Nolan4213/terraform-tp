# Les IP publiques des deux VM sont créées avant les VM elles-mêmes :
# chaque nœud connaît ainsi l'adresse de son pair dès le premier démarrage
# (configuration DRBD et règles pare-feu), sans dépendance circulaire.

data "http" "my_ip" {
  count = var.admin_cidr == "" ? 1 : 0
  url   = "https://checkip.amazonaws.com"
}

locals {
  admin_cidr     = var.admin_cidr != "" ? var.admin_cidr : "${chomp(data.http.my_ip[0].response_body)}/32"
  ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key_path)))

  common_tags = {
    project    = var.project_name
    managed_by = "terraform"
    exercise   = "tp2-exo2-drbd"
  }

  # Paramètres communs du script de démarrage ; seuls le rôle et l'identité
  # du nœud changent d'un cloud à l'autre.
  drbd_common = {
    resource     = "r0"
    port         = var.drbd_port
    disk_size_gb = var.data_disk_size_gb
    lv_size      = var.drbd_lv_size
    vg_name      = "vg_drbd"
    lv_name      = "lv_drbd"
    mount_point  = "/srv/drbd"
    aws_name     = "drbd-aws"
    azure_name   = "drbd-azure"
    aws_ip       = aws_eip.node.public_ip
    azure_ip     = azurerm_public_ip.node.ip_address
  }
}
