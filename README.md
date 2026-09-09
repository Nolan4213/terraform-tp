# TPs Terraform

Collection de travaux pratiques (TP) Terraform. Chaque TP a son propre
dossier avec sa configuration Terraform et son README.

## TPs

- [`tp-libvirt/`](./tp-libvirt) — Provisionne une VM Debian 12 sur un
  hyperviseur libvirt/QEMU local (pool de stockage, image de base, disque,
  cloud-init, VM).

D'autres TPs seront ajoutés ici sous forme de nouveaux dossiers suivant le
même schéma :

```
<racine du repo>/
├── tp-<nom>/
│   ├── main.tf
│   ├── ...
│   └── README.md
└── README.md
```

## Conventions

- Un dossier par TP, nommé `tp-<sujet>`.
- Chaque dossier de TP a son propre `README.md` expliquant ce qu'il
  provisionne et comment l'exécuter.
- `terraform.tfstate`, `terraform.tfstate.backup` et `.terraform/` ne sont
  jamais commités (voir `.gitignore`) — fichiers locaux/spécifiques à
  l'environnement, pouvant contenir des données sensibles.
