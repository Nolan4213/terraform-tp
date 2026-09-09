# Terraform TPs

Collection of Terraform practical exercises (TPs). Each TP lives in its own
top-level folder with its own Terraform configuration and README.

## TPs

- [`tp-libvirt/`](./tp-libvirt) — Provision a Debian 12 VM on a local
  libvirt/QEMU hypervisor (storage pool, base image, disk, cloud-init, VM).

More TPs will be added here as new folders following the same pattern:

```
<repo root>/
├── tp-<name>/
│   ├── main.tf
│   ├── ...
│   └── README.md
└── README.md
```

## Conventions

- One folder per TP, named `tp-<subject>`.
- Each TP folder has its own `README.md` explaining what it provisions and
  how to run it.
- `terraform.tfstate`, `terraform.tfstate.backup`, and `.terraform/` are
  never committed (see `.gitignore`) — they are local/environment-specific
  and can hold sensitive data.
