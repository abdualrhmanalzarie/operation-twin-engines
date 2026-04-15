output "frontend_external_ip" {
  value = google_compute_instance.frontend_vm.network_interface[0].access_config[0].nat_ip
}

output "frontend_internal_ip" {
  value = google_compute_instance.frontend_vm.network_interface[0].network_ip
}

output "backend_external_ip" {
  value = google_compute_instance.backend_vm.network_interface[0].access_config[0].nat_ip
}

output "backend_internal_ip" {
  value = google_compute_instance.backend_vm.network_interface[0].network_ip
}