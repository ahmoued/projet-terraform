# 🎓 TP : Infrastructure as Code (IaC) et Pipelines CI/CD

## 📋 Présentation
Ce projet implémente une infrastructure complète utilisant **Terraform** pour orchestrer des conteneurs **Docker** (PostgreSQL + Application Web Nginx) avec un pipeline **CI/CD automatisé** via **GitHub Actions**.

## 🏗️ Structure du Projet

```
tp-iac-local/
├── main.tf                    # Définition des ressources et du provider Docker
├── variables.tf               # Paramètres configurables (ports, credentials)
├── outputs.tf                 # Informations de sortie après déploiement
├── Dockerfile_app             # Blueprint de l'image de l'application web
├── .gitignore                 # Fichiers à ignorer par Git
├── .github/
│   └── workflows/
│       └── main.yml          # Pipeline CI/CD GitHub Actions
└── README.md                  # Cette documentation
```

## 🚀 Partie I : Déploiement Local avec Terraform

### Prérequis
- Docker Desktop (ou Docker Engine) installé et démarré
- Terraform CLI (version ≥ 1.0)
- Git

### Cycle de Vie du Déploiement (DLC)

#### 1. Initialisation
```powershell
terraform init
```
**Résultat attendu** : Téléchargement du provider Docker et initialisation du backend local.

#### 2. Planification
```powershell
terraform plan
```
**Résultat attendu** : Affichage des ressources qui seront créées (2 images Docker, 2 conteneurs).

#### 3. Application
```powershell
terraform apply -auto-approve
```
**Résultat attendu** : Création de :
- Conteneur PostgreSQL (`tp-db-postgres`) sur le port 5432
- Conteneur Application Web (`tp-app-web`) sur le port 8080

#### 4. Validation
Accédez à l'application web :
```
http://localhost:8080
```
Vous devriez voir : **"Application Deployed via Terraform IaC!"**

Vérifiez les conteneurs actifs :
```powershell
docker ps
```

#### 5. Destruction
```powershell
terraform destroy -auto-approve
```
**Résultat attendu** : Suppression complète des conteneurs et nettoyage de l'infrastructure.

---

## 🔄 Partie II : Pipeline CI/CD avec GitHub Actions

### Configuration du Pipeline

1. **Initialiser le dépôt Git** :
```powershell
git init
git add .
git commit -m "Initial commit: Infrastructure IaC complète"
```

2. **Créer un dépôt GitHub** et pusher le code :
```powershell
git remote add origin https://github.com/VOTRE_USERNAME/tp-iac-local.git
git branch -M main
git push -u origin main
```

3. **Configuration des Secrets GitHub** (Optionnel) :
   - Allez dans `Settings` > `Secrets and variables` > `Actions`
   - Ajoutez un secret `DB_PASSWORD` avec la valeur de votre choix

### Étapes du Pipeline

Le fichier `.github/workflows/main.yml` automatise le DLC :

| Étape Pipeline | Commande Exécutée | Rôle dans le DLC |
|----------------|-------------------|------------------|
| **Setup Terraform** | Installation de Terraform | Préparation |
| **Init** | `terraform init` | Initialisation de l'état |
| **Validate** | `terraform validate` | Vérification syntaxe |
| **Plan** | `terraform plan` | Détection des changements |
| **Apply** | `terraform apply -auto-approve` | Déploiement automatique |
| **Outputs** | `terraform output` | Affichage des résultats |

### Test de l'Automatisation

1. Modifiez une variable dans `variables.tf` :
```hcl
variable "db_password" {
  default = "nouveau_mot_de_passe_2024"
}
```

2. Commitez et poussez :
```powershell
git add variables.tf
git commit -m "Update: Changement du mot de passe DB"
git push
```

3. Observez le pipeline s'exécuter automatiquement dans l'onglet **Actions** de votre dépôt GitHub.

---

## 📝 Réponses aux Questions d'Approfondissement

### 1. Définition d'État : Impact de `terraform destroy` sur `terraform.tfstate`

**Réponse** :
La commande `terraform destroy` supprime toutes les ressources définies dans la configuration Terraform et met à jour le fichier `terraform.tfstate` en le vidant (ou en marquant toutes les ressources comme supprimées).

**Rôle du fichier tfstate** :
- Il sert de **source de vérité** pour Terraform, mappant les ressources réelles (conteneurs Docker) aux configurations déclarées dans les fichiers `.tf`.
- Lors d'un `terraform apply`, Terraform compare l'état désiré (code) avec l'état actuel (tfstate) pour déterminer les changements à appliquer.
- Après un `destroy`, le fichier tfstate est vide, indiquant qu'aucune ressource n'est actuellement gérée.

**Réconciliation** :
Si le fichier tfstate est perdu ou désynchronisé, Terraform ne peut plus gérer correctement les ressources existantes, ce qui peut conduire à des duplications ou des erreurs lors du prochain `apply`.

---

### 2. Immuabilité : Signification dans le contexte IaC

**Réponse** :
L'**Immuabilité de l'Infrastructure** signifie que les ressources ne sont jamais modifiées en place après leur création. Au lieu de mettre à jour une ressource existante, on la **détruit et la recrée** avec la nouvelle configuration.

**Avantages** :
- **Fiabilité** : Élimine les risques de configurations corrompues ou d'états incohérents.
- **Traçabilité** : Chaque changement est un déploiement complet et versionné.
- **Reproductibilité** : L'infrastructure peut être recréée à l'identique à tout moment.

**Exemple** :
Si vous changez le mot de passe PostgreSQL dans `variables.tf`, Terraform détruira le conteneur DB existant et en créera un nouveau avec le nouveau mot de passe, plutôt que de modifier le conteneur en cours d'exécution.

---

### 3. Planification : Pourquoi l'étape `Plan` est-elle essentielle ?

**Réponse** :
L'étape `terraform plan` est la **porte d'entrée (gate)** du DLC en production car elle permet de :

1. **Prévisualiser les changements** : Affiche exactement quelles ressources seront créées, modifiées ou détruites **avant** toute action réelle.

2. **Validation par les équipes** : En environnement de production, le plan peut être revu par plusieurs parties prenantes (développeurs, ops, sécurité) avant validation.

3. **Prévention des erreurs catastrophiques** : Évite les destructions accidentelles de ressources critiques (ex: bases de données de production).

4. **Conformité** : Permet de vérifier que les changements respectent les politiques de sécurité et de gouvernance.

**En CI/CD** : Le pipeline peut être configuré pour exiger une **approbation manuelle** après l'étape `plan` et avant `apply`, surtout en production.

---

### 4. Alternative : Création d'un réseau Docker avec Terraform

**Réponse** :
Pour créer un réseau Docker personnalisé et y connecter les conteneurs, il faut utiliser la ressource **`docker_network`** de Terraform.

**Exemple d'implémentation** :

```hcl
# Création d'un réseau Docker personnalisé
resource "docker_network" "app_network" {
  name = "tp-network"
  driver = "bridge"
}

# Modification du conteneur DB pour l'attacher au réseau
resource "docker_container" "db_container" {
  name  = "tp-db-postgres"
  image = docker_image.postgres_image.image_id
  
  networks_advanced {
    name = docker_network.app_network.name
    aliases = ["database"]  # Nom DNS interne
  }
  
  # ... reste de la configuration
}

# Modification du conteneur App pour l'attacher au réseau
resource "docker_container" "app_container" {
  name  = "tp-app-web"
  image = docker_image.app_image.image_id
  
  networks_advanced {
    name = docker_network.app_network.name
  }
  
  # L'application peut maintenant accéder à la DB via "database:5432"
  
  # ... reste de la configuration
}
```

**Avantages** :
- **Isolation réseau** : Les conteneurs ne sont visibles que dans ce réseau.
- **Résolution DNS automatique** : Les conteneurs peuvent se contacter par leur nom au lieu d'adresses IP.
- **Sécurité** : Meilleur contrôle des communications inter-conteneurs.

---

## ✅ Critères d'Évaluation

| Critère | Description | Pondération |
|---------|-------------|-------------|
| **1. Maîtrise IaC** | Clarté et exactitude des fichiers `.tf` et du `Dockerfile_app` | 40% |
| **2. Exécution DLC** | Documentation des 5 étapes (Init → Destroy) et validation | 30% |
| **3. Pipeline CI/CD** | Fichier de pipeline correct, exécution réussie | 30% |

---

## 🔧 Dépannage

### Problème : Erreur "port already allocated"
**Solution** : Un autre service utilise le port 8080 ou 5432.
```powershell
# Changer le port dans variables.tf
variable "app_port_external" {
  default = 9090  # Au lieu de 8080
}
```

### Problème : Docker daemon non accessible
**Solution** : Assurez-vous que Docker Desktop est démarré.
```powershell
docker ps  # Doit retourner une liste (même vide)
```

### Problème : Terraform ne détecte pas les changements
**Solution** : Supprimez le cache et réinitialisez.
```powershell
Remove-Item -Recurse -Force .terraform
terraform init
```

---

## 📚 Ressources Complémentaires

- [Documentation Terraform Provider Docker](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs)
- [Guide GitHub Actions](https://docs.github.com/en/actions)
- [Docker Compose vs Terraform](https://www.terraform.io/use-cases/docker)

---

## 👨‍🎓 Auteur
Travail Pratique - Ingénierie Génie Logiciel / DevOps  
**Durée estimée** : 6 heures  
**Objectif** : Maîtrise du Cycle de Vie du Déploiement (DLC) complet et automatisé

---

## 📄 Licence
Ce projet est à usage éducatif uniquement.
