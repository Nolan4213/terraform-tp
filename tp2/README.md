# TP2 — Terraform multi-cloud (AWS / Azure / GCP)

Sujet complet : [`tp_2_terraform.pdf`](./tp_2_terraform.pdf).

## Rendus PDF

Version PDF des deux README, captures incluses :

- [`rendus/TP2-exercice1-terraform-multicloud.pdf`](./rendus/TP2-exercice1-terraform-multicloud.pdf)
- [`rendus/TP2-exercice2-drbd-aws-azure.pdf`](./rendus/TP2-exercice2-drbd-aws-azure.pdf)

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
3_Cloud_Providers/shared/lvm-setup.sh.tftpl   # script LVM commun aux 3 clouds
```

## Exercice 2 — Réplication DRBD multi-cloud

Voir [`exo2-drbd/README.md`](./exo2-drbd/README.md).

Un LV LVM est répliqué par DRBD 9 entre une VM Rocky Linux 9 chez AWS
(`eu-west-3`) et une chez Azure (`norwayeast`), créées par un seul root
module Terraform. Le dimensionnement est volontairement minimal pour
consommer le moins de crédits possible.
