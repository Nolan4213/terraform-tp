# Exercice 1 — Fichiers conformes à des attentes professionnelles

Chaque dossier provider (`AWS/`, `AZURE/`, `GCP/`) contient :

- `main.tf` à la racine : **fichier d'origine**, généré par ChatGPT, non
  modifié — conservé pour comparaison.
- `pro/` : version corrigée et structurée, avec `versions.tf`,
  `variables.tf`, `main.tf`, `outputs.tf` et `terraform.tfvars.example`.

Objectif commun à conserver sur les 3 providers : VM Rocky Linux 9.3,
2 vCPU, 2 Go de RAM, 2 disques dédiés de 20 Go destinés à un LVM.

## Pourquoi le fichier d'origine n'est pas « professionnel »

### AWS (`AWS/main.tf`)

| Problème | Correction dans `pro/` |
|---|---|
| Tout est codé en dur (région, AMI, nom de clé) : rien n'est réutilisable ni paramétrable. | Variables pour région, AMI, type d'instance, clé SSH, CIDR admin, tailles de disque. |
| `t3.medium` = 2 vCPU / 4 Go RAM, ne correspond pas au besoin (2 Go). | `t3.small` = 2 vCPU / 2 Go RAM exactement. |
| Règle SSH ouverte à `0.0.0.0/0` (tout Internet). | CIDR restreint à `var.admin_cidr`. |
| Les 2 disques LVM sont dupliqués bloc par bloc (`ebs_block_device` × 2 copiés-collés). | Un seul `dynamic "ebs_block_device"` généré à partir de `var.lvm_disk_count`. |
| Pas de version de provider figée → risque de breaking change silencieux. | `versions.tf` avec `required_providers` et contrainte `~> 5.0`. |
| Pas de tags → ressources impossibles à identifier/facturer proprement. | Tags `Name/Project/Environment/ManagedBy/OS` cohérents sur toutes les ressources. |
| Disques non chiffrés. | `encrypted = true` sur le disque racine et les disques LVM. |
| Aucun output. | `instance_id`, `public_ip`, `private_ip`. |

### Azure (`AZURE/main.tf`)

| Problème | Correction dans `pro/` |
|---|---|
| **Mot de passe en clair dans le code** (`admin_password = "Azure1234!@"`) — secret commité en Git, faille de sécurité majeure. | Authentification par clé SSH uniquement (`disable_password_authentication = true` + `admin_ssh_key`). |
| **Aucune IP publique** définie : la VM telle que décrite est injoignable depuis l'extérieur. | Ajout de `azurerm_public_ip`, associée à la carte réseau. |
| **Aucun NSG** (Network Security Group) : pas de contrôle explicite du trafic entrant. | `azurerm_network_security_group` limitant le SSH à `var.admin_cidr`, associé à la NIC. |
| `Standard_B2ms` = 2 vCPU / 8 Go RAM, loin du besoin (2 Go). | `Standard_B2s` = 2 vCPU / 4 Go, le SKU B-series le plus proche — Azure ne propose pas de 2 vCPU / 2 Go exact (documenté dans `variables.tf`). |
| Noms de ressources en dur, pas de tags. | Nommage via `local.name`, tags `project/environment/managed_by/os` partout. |
| Pas de version de provider figée. | `versions.tf` avec contrainte `~> 3.90`. |

### GCP (`GCP/main.tf`)

| Problème | Correction dans `pro/` |
|---|---|
| **Bug réel** : le bloc `attached_disk { size = ... type = ... }` n'est pas valide — `attached_disk` attend un `source` vers un disque existant, pas des attributs de taille. Ce fichier ne passerait pas `terraform validate` tel quel. | Les disques sont créés comme ressources `google_compute_disk` à part entière, puis attachés via `source = google_compute_disk.lvm[*].id`. |
| `e2-medium` = 2 vCPU / 4 Go RAM, ne correspond pas au besoin (2 Go). | Type personnalisé `e2-custom-2-2048` = exactement 2 vCPU / 2 Go. |
| Image figée sur une version précise (`rocky-linux-9-3-0-v20230215`), jamais patchée. | Famille d'image `rocky-linux-cloud/rocky-linux-9` : dernier correctif automatiquement. |
| `project = "your-project-id"` codé en dur, placeholder non fonctionnel. | Variable obligatoire `gcp_project`, sans valeur par défaut. |
| Pas de clé SSH ni de règle firewall explicite : connexion non garantie. | Clé SSH injectée via métadonnées (`ssh-keys`), règle `google_compute_firewall` limitée à `var.admin_cidr`. |
| Pas de labels, pas de version de provider figée. | Labels cohérents + `versions.tf` avec contrainte `~> 5.0`. |

## Vérification effectuée

`terraform fmt` et `terraform validate` (sans backend, sans credentials
cloud) passent sur les 3 configurations `pro/`. Aucun `terraform plan`/
`apply` réel n'a été fait : les variables sans valeur par défaut
(AMI, project ID, clé SSH...) sont propres à l'environnement de chacun et
doivent être renseignées via `terraform.tfvars` (voir les fichiers
`terraform.tfvars.example`).
