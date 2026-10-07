output "instance_id" {
  description = "ID de l'instance Compute Engine"
  value       = google_compute_instance.vm.id
}

output "public_ip" {
  description = "Adresse IP publique de la VM"
  value       = google_compute_instance.vm.network_interface[0].access_config[0].nat_ip
}

output "private_ip" {
  description = "Adresse IP privée de la VM"
  value       = google_compute_instance.vm.network_interface[0].network_ip
}
