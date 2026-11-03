# Exercice 1 — Fichiers conformes à des attentes professionnelles

Chaque dossier provider (`AWS/`, `AZURE/`, `GCP/`) contient :

- `main.tf` à la racine : **fichier d'origine**, généré par ChatGPT, non
  modifié — conservé pour comparaison.
- `pro/` : version corrigée et structurée, avec `versions.tf`,
  `variables.tf`, `main.tf`, `outputs.tf` et `terraform.tfvars.example`.

Objectif commun à conserver sur les 3 providers : VM Rocky Linux 9,
2 vCPU, 2 Go de RAM, 2 disques dédiés de 20 Go assemblés en LVM.

### Points communs aux 3 corrections

- **LVM réellement configuré.** L'original attachait des disques, mais ne
  créait ni VG ni LV. Le script `shared/lvm-setup.sh.tftpl` est rendu par
  `templatefile()` et passé en `user_data` (AWS), `custom_data` (Azure) ou
  `metadata_startup_script` (GCP). Il crée `vg_data/lv_data` en XFS sur
  `/data`. Il repère les disques par taille, car leur nom change selon le
  cloud (`nvme1n1`, `sdc`...), et il est idempotent.
- **Rocky Linux 9.3 n'est plus distribuable tel quel.** La RESF ne maintient
  que la dernière version mineure de la branche 9, et les AMI 9.3 ont
  disparu d'AWS. AWS et GCP prennent donc la dernière 9.x. Azure garde
  `9.3.20231113`, encore publiée, via la variable `rocky_image_version`.

## Pourquoi le fichier d'origine n'est pas « professionnel »

### AWS (`AWS/main.tf`)

| Problème | Correction dans `pro/` |
|---|---|
| Tout est codé en dur (région, AMI, nom de clé) : rien n'est réutilisable ni paramétrable. | Variables pour région, type d'instance, clé SSH, CIDR admin, tailles de disque. |
| AMI codée en dur, valable dans une seule région (et Rocky 9.3 n'est plus publiée). | Data source `aws_ami` sur le compte officiel RESF (`792107900819`), dernière 9.x. |
| Dépend implicitement du VPC par défaut, qui peut ne pas exister (c'est le cas sur le compte de test : `no matching EC2 VPC found`). | VPC dédié, subnet public, Internet Gateway, table de routage. Pas de NAT Gateway. |
| `security_groups` (noms) au lieu de `vpc_security_group_ids`. | `vpc_security_group_ids`. Descriptions en ASCII : l'API EC2 refuse les accents. |
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
| `Standard_B2ms` = 2 vCPU / 8 Go RAM, loin du besoin (2 Go). | `Standard_B2als_v2` = 2 vCPU / 4 Go, la taille la plus proche disponible. Azure ne propose pas de 2 vCPU / 2 Go exact (documenté dans `variables.tf`). |
| **Image inexistante** : `openlogic/rocky-linux/9.3` n'est pas publiée, donc l'`apply` échoue. | Image officielle `resf:rockylinux-x86_64:9-base`, avec le bloc `plan` exigé par le Marketplace. |
| **Bug réel** : NIC sans bloc `ip_configuration`, et blocs `data_disk` inexistants sur `azurerm_linux_virtual_machine`. `terraform validate` échoue. | `ip_configuration` complet ; disques en `azurerm_managed_disk` + `azurerm_virtual_machine_data_disk_attachment`. |
| Région `East US` en dur. | Variable `location`, défaut `norwayeast` : l'abonnement Azure for Students limite les régions, et la série B n'y est pas ouverte en France Central. |
| Noms de ressources en dur, pas de tags. | Nommage via `local.name`, tags `project/environment/managed_by/os` partout. |
| Pas de version de provider figée. | `versions.tf` avec contrainte `~> 4.0`. La 3.x refusait les clés SSH ed25519. La 4.x exige `subscription_id`. |

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

- `terraform fmt -check` et `terraform validate` passent sur les 3
  configurations `pro/`.
- `terraform plan` passe avec de vrais credentials sur AWS (`eu-west-3`) et
  Azure (abonnement Student). C'est ce `plan` qui a révélé l'absence de VPC
  par défaut, les accents refusés par l'API EC2 et le rejet des clés ed25519
  par azurerm 3.x.
- GCP : `validate` seulement, faute de projet GCP.
- Aucun `apply` : l'exercice porte sur la qualité des fichiers. Les fichiers
  `.terraform.lock.hcl` sont commités pour figer les versions de providers.
