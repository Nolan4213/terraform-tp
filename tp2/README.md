# TP2 — Terraform multi-cloud (AWS / Azure / GCP)

Sujet complet : [`tp_2_terraform.pdf`](./tp_2_terraform.pdf).

## Exercice 1 — Fichiers conformes à des attentes professionnelles

Voir [`3_Cloud_Providers/README.md`](./3_Cloud_Providers/README.md).

Point de départ : des fichiers Terraform générés par ChatGPT pour déployer
la même VM Rocky Linux 9.3 (2 vCPU, 2 Go RAM, 2 disques de 20 Go en LVM)
sur AWS, Azure et GCP. Le travail consiste à relever les problèmes de ces
fichiers (sécurité, dimensionnement, bugs, absence de bonnes pratiques) et
à produire une version professionnelle, sans supprimer l'original — pour
que la différence reste visible.

Structure par provider :

```
3_Cloud_Providers/<PROVIDER>/
├── main.tf       # fichier d'origine (ChatGPT), inchangé
└── pro/          # version corrigée : versions.tf, variables.tf, main.tf,
                   # outputs.tf, terraform.tfvars.example
```

## Exercice 2 — Réplication DRBD multi-cloud

Pas encore traité.
