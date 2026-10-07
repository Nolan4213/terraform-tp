provider "google" {
  project = "your-project-id"
  region  = "us-central1"
}

resource "google_compute_instance" "vm" {
  name         = "rocky-linux-vm"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "rocky-linux-9-3-0-v20230215"
      size  = 20
    }
  }

  attached_disk {
    device_name = "disk1"
    size        = 20
    type        = "pd-standard"
  }

  attached_disk {
    device_name = "disk2"
    size        = 20
    type        = "pd-standard"
  }

  network_interface {
    network = "default"
    access_config {}
  }

  tags = ["rocky-linux-vm"]
}
