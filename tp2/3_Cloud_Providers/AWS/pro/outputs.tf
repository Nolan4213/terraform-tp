output "instance_id" {
  description = "ID de l'instance EC2"
  value       = aws_instance.vm.id
}

output "ami" {
  description = "AMI Rocky Linux retenue"
  value       = "${data.aws_ami.rocky.id} (${data.aws_ami.rocky.name})"
}

output "public_ip" {
  description = "Adresse IP publique de la VM"
  value       = aws_instance.vm.public_ip
}

output "private_ip" {
  description = "Adresse IP privée de la VM"
  value       = aws_instance.vm.private_ip
}
