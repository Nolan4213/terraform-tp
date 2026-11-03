output "aws_public_ip" {
  description = "IP publique du nœud AWS (primaire DRBD)"
  value       = aws_eip.node.public_ip
}

output "azure_public_ip" {
  description = "IP publique du nœud Azure (secondaire DRBD)"
  value       = azurerm_public_ip.node.ip_address
}

output "aws_ami" {
  description = "AMI Rocky Linux utilisée"
  value       = data.aws_ami.rocky.name
}

output "admin_cidr" {
  description = "CIDR autorisé en SSH"
  value       = local.admin_cidr
}

output "ssh_aws" {
  value = "ssh -i ${trimsuffix(var.ssh_public_key_path, ".pub")} ${var.admin_username}@${aws_eip.node.public_ip}"
}

output "ssh_azure" {
  value = "ssh -i ${trimsuffix(var.ssh_public_key_path, ".pub")} ${var.admin_username}@${azurerm_public_ip.node.ip_address}"
}
