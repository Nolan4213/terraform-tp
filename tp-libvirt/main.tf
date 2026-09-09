terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.6"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_pool" "tp_pool" {
  name = "tp-pool"
  type = "dir"
  path = "/var/lib/libvirt/images/tp-pool"
}

resource "libvirt_volume" "debian_base" {
  name   = "debian-base.qcow2"
  pool   = libvirt_pool.tp_pool.name
  source = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
  format = "qcow2"
}

resource "libvirt_volume" "vm_disk" {
  name           = "vm-disk.qcow2"
  pool           = libvirt_pool.tp_pool.name
  base_volume_id = libvirt_volume.debian_base.id
  size           = 10 * 1024 * 1024 * 1024
}

resource "libvirt_cloudinit_disk" "cloudinit" {
  name      = "cloudinit.iso"
  pool      = libvirt_pool.tp_pool.name
  user_data = file("${path.module}/cloud_init.cfg")
}

resource "libvirt_domain" "tp_vm" {
  name   = "tp-vm"
  memory = 1024
  vcpu   = 1

  disk {
    volume_id = libvirt_volume.vm_disk.id
  }

  cloudinit = libvirt_cloudinit_disk.cloudinit.id

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }
}

output "vm_ip" {
  value = libvirt_domain.tp_vm.network_interface[0].addresses[0]
}
