# TP LibVirt — Provisionnement d'une VM avec Terraform

Ce TP provisionne une machine virtuelle Debian 12 (Bookworm) sur un
hyperviseur libvirt/QEMU local, avec Terraform et le provider
[`dmacvicar/libvirt`](https://registry.terraform.io/providers/dmacvicar/libvirt/latest).

## Ce que ça fait

`main.tf` déclare les ressources suivantes :

| Ressource | Rôle |
|---|---|
| `libvirt_pool.tp_pool` | Pool de stockage dédié (`tp-pool`) dans `/var/lib/libvirt/images/tp-pool` pour tous les disques du TP. |
| `libvirt_volume.debian_base` | Télécharge l'image cloud officielle Debian 12 generic (qcow2), utilisée comme image de base. |
| `libvirt_volume.vm_disk` | Volume de 10 Go cloné (backed) depuis l'image de base — c'est le disque réel de la VM. |
| `libvirt_cloudinit_disk.cloudinit` | ISO cloud-init construite à partir de `cloud_init.cfg`, utilisée pour configurer la VM au premier démarrage. |
| `libvirt_domain.tp_vm` | La VM elle-même : 1 vCPU, 1024 Mo de RAM, disque + cloud-init attachés, une interface réseau sur le réseau `default` de libvirt, et une console série. |

Un bloc `output "vm_ip"` expose l'adresse IP attribuée à la première
interface réseau de la VM une fois démarrée.

## Configuration cloud-init

`cloud_init.cfg` crée un utilisateur `debian` avec sudo sans mot de passe et
installe une clé publique SSH, pour que la VM soit joignable immédiatement
après démarrage, sans configuration manuelle de mot de passe.

## Utilisation

```bash
terraform init
terraform plan
terraform apply
```

Une fois appliqué, récupérer l'IP de la VM avec :

```bash
terraform output vm_ip
```

Puis se connecter avec :

```bash
ssh debian@<vm_ip>
```

Pour tout détruire :

```bash
terraform destroy
```

## Prérequis

- Un hôte libvirt/QEMU fonctionnel (`qemu:///system` accessible à
  l'utilisateur qui exécute Terraform, normalement via l'appartenance au
  groupe `libvirt`).
- Terraform, avec la version du provider `dmacvicar/libvirt` figée par
  `.terraform.lock.hcl` (`0.7.6`).
- Accès internet sortant pour récupérer l'image cloud Debian au premier
  lancement.

## Notes

- `terraform.tfstate` et le cache de plugins `.terraform/` ne sont **pas**
  commités — les fichiers de state peuvent contenir des données sensibles
  et sont spécifiques à l'environnement, et le cache provider se régénère
  facilement avec `terraform init`.
