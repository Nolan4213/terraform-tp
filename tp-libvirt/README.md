# TP LibVirt — VM provisioning with Terraform

This TP provisions a single Debian 12 (Bookworm) virtual machine on a local
libvirt/QEMU hypervisor using Terraform and the
[`dmacvicar/libvirt`](https://registry.terraform.io/providers/dmacvicar/libvirt/latest)
provider.

## What it does

`main.tf` declares the following resources:

| Resource | Purpose |
|---|---|
| `libvirt_pool.tp_pool` | A dedicated storage pool (`tp-pool`) at `/var/lib/libvirt/images/tp-pool` for all disks used by this TP. |
| `libvirt_volume.debian_base` | Downloads the official Debian 12 generic cloud image (qcow2) as a base volume. |
| `libvirt_volume.vm_disk` | A 10 GiB volume cloned (backed) from the base image — this is the VM's actual disk. |
| `libvirt_cloudinit_disk.cloudinit` | A cloud-init ISO built from `cloud_init.cfg`, used to configure the VM on first boot. |
| `libvirt_domain.tp_vm` | The VM itself: 1 vCPU, 1024 MB RAM, attached disk + cloud-init, one NIC on the `default` libvirt network, and a serial console. |

An `output "vm_ip"` block exposes the IP address leased to the VM's first
network interface once it boots.

## Cloud-init configuration

`cloud_init.cfg` creates a `debian` user with passwordless sudo and installs
an SSH public key so the VM is reachable immediately after boot, with no
manual password setup.

## Usage

```bash
terraform init
terraform plan
terraform apply
```

Once applied, retrieve the VM's IP with:

```bash
terraform output vm_ip
```

Then connect with:

```bash
ssh debian@<vm_ip>
```

To tear everything down:

```bash
terraform destroy
```

## Requirements

- A working libvirt/QEMU host (`qemu:///system` accessible to the user
  running Terraform, normally via membership in the `libvirt` group).
- Terraform >= the version pinned by `.terraform.lock.hcl` for the
  `dmacvicar/libvirt` provider (`0.7.6`).
- Outbound internet access to fetch the Debian cloud image on first run.

## Notes

- `terraform.tfstate` and the `.terraform/` plugin cache are **not**
  committed — state files can contain sensitive data and are
  environment-specific, and the provider cache is easily regenerated with
  `terraform init`.
