# 🚀 Portail Cloud Container

## 📋 Description du Projet

**Infrastructure Azure complète** avec dashboard web pour **gérer des containers Azure automatiquement**. 

### 🎯 Objectif
Depuis le dashboard, vous pouvez :
- **Créer** des containers avec des applications automatiquement
- **Manager** vos containers (start/stop/delete/create)
- **Monitorer** l'état et les performances en temps réel
- **Déployer** des applications conteneurisées sur Azure Container Apps

### 🏗️ Infrastructure Déployée
- **Dashboard Frontend** (Next.js) + **API Backend** (Node.js)
- **Base de données** PostgreSQL sur Azure
- **Registry** Docker privé Azure
- **Container Apps** pour hébergement scalable
- **Authentification** JWT + intégration Azure AD
- **Monitoring** + logs centralisés

---

## ⚡ Déploiement (3 Options)
ATTENTION: les déploiements docker peuvent faire des erreurs timeout car long, sur toutes les options, l'installation est très longue et le deploiement peut dépasser 10 minutes car tout est automatique. Veriifez si vous utiliser le script "deploy-optimized" à bien regarder la fenêtre Azure dérrière qui s'ouvre pour vous connecter (regardez dérriere toutes les fenêtres du bureau). 

### 🎯 Option 1: Script Universel (Recommandé)
```bash
bash ./deploy-universal.sh
```
✅ **Portable partout** (Linux, macOS, Windows, CI/CD)  
✅ **Isolation complète** dans container Docker  
✅ **Aucun conflit** avec votre système  

### 🔧 Option 2: Commande Docker Directe
```bash
docker build -f Dockerfile.simple -t portail-deploy . && docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock -v $(pwd):/workspace -v portail-azure-credentials:/root/.azure portail-deploy ./deploy-optimized.sh
```
✅ **Même résultat** que l'option 1  
✅ **Contrôle total** de la commande Docker

### 🖥️ Option 3: Déploiement Direct (Machine Locale)
```bash
bash ./deploy-optimized.sh
```
⚠️ **Peut poser des problèmes de compatibilité**  
⚠️ **Installe des outils** directement sur votre machine  
✅ **Normalement fonctionne** et installe tout automatiquement

---

## 🔄 Que Font Ces Scripts ?

1. **Installation automatique** : Terraform, Azure CLI, Docker CLI, jq
2. **Connexion Azure** : Vous demande de vous connecter à votre compte
3. **Infrastructure Terraform** : Crée toute l'infrastructure Azure
4. **Build & Push Docker** : Construit et pousse les images sur Azure Registry
5. **Déploiement Apps** : Déploie dashboard + API sur Container Apps
6. **Vérifications finales** : CORS, MSI Azure, endpoints API

## 🛠️ Prérequis

- **Compte Azure** (avec permissions Contributor)
- **Docker Desktop** (pour options 1 et 2)

## 📋 CI/CD Ready

```yaml
# Compatible tous pipelines : GitHub Actions, GitLab CI, Azure DevOps...
- run: bash ./deploy-universal.sh
```

## 🚀 Améliorations pour Production Enterprise

**Note :** Cette implémentation privilégie la **simplicité et portabilité** pour répondre aux contraintes du projet académique (déploiement depuis n'importe quel environnement). Pour une **automatisation cloud complète** en production, les améliorations suivantes seraient nécessaires :

### 🔄 Pipeline CI/CD Complet
- **GitHub Actions/Jenkins** : Déclenchement automatique sur `git push`
- **Tests automatisés** : Unit tests, integration tests, security scans
- **Environnements multiples** : dev/staging/prod avec promotion automatique
- **Approval gates** : Validation manuelle pour production

### 📊 Versioning & Rollback  
- **Semantic versioning** : Tags Git automatiques (v1.2.3)
- **Blue/Green deployment** : Zéro downtime avec rollback instantané
- **Database migrations** : Scripts de migration versionnés
- **Container image tagging** : Images taguées par commit SHA

### 🛡️ Sécurité & Monitoring
- **Service Principal** : Authentification non-interactive
- **Azure Key Vault** : Secrets centralisés et rotation automatique  
- **Policy compliance** : Validation automatique des règles sécurité
- **Monitoring avancé** : Alertes, dashboards, SLA tracking

**Choix architectural :** Nous avons opté pour un **script universel** qui fonctionne partout (Windows/Linux/macOS/CI) avec `az login` simple, permettant au professeur de redéployer facilement sans configuration complexe.

## 📋 Que fait le script ?

### 🔧 Configuration automatique
- ✅ Installe Azure CLI, Terraform, jq si manquants
- ✅ Vous connecte à Azure (`az login`)
- ✅ Génère un ID unique depuis votre email
- ✅ Enregistre les providers Azure requis
- ✅ Démarre Docker si nécessaire

### 🏗️ Infrastructure déployée
- 🗃️ **Base de données** PostgreSQL (mots de passe auto-générés)
- 🐳 **Container Registry** Azure (ACR)
- 🌐 **Container Apps** Backend + Frontend
- 📊 **Monitoring** Log Analytics
- 🔒 **Sécurité** HTTPS automatique + JWT

### 🎯 Résultat final
- **URLs publiques HTTPS** fonctionnelles
- **Base de données** initialisée avec utilisateurs test
- **Applications** complètement opérationnelles
- **Durée** : 5-8 minutes | **Coût** : ~2-3€/jour

## 🐛 Debugging & Maintenance

### 🧹 Redémarrer à zéro
```bash
bash ./deploy-optimized.sh --clean
```
Supprime toutes les ressources Azure et redéploie proprement.

### 🔄 Après une erreur
```bash
# Relancer directement après une erreur
bash ./deploy-optimized.sh
```
Le script gère automatiquement les états existants et reprend où il s'est arrêté.

### 📊 Validation complète
```powershell
.\validate-deployment-clean.ps1
```

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐
│   Frontend      │◄───┤    Backend      │
│   (Next.js)     │    │   (Node.js)     │
│   Container App │    │   Container App │
└─────────────────┘    └─────────────────┘
         │                       │
         └───────────────────────┼──────────────┐
                                 │              │
              ┌─────────────────┐│   ┌─────────────────┐
              │  PostgreSQL     ││   │ Container       │
              │  Database       ││   │ Registry (ACR)  │
              └─────────────────┘│   └─────────────────┘
                                 │
              ┌─────────────────┐│
              │ Log Analytics   ││
              │ Workspace       ││
              └─────────────────┘│
```

## 🔑 Utilisateurs de Test Créés

| Rôle | Email | Mot de passe |
|------|--------|---------------|
| Admin | `admin@portail-cloud.com` | `admin123` |
| Client | `client1@portail-cloud.com` | `client123` |
| Client | `client2@portail-cloud.com` | `client123` |
| Client | `client3@portail-cloud.com` | `client123` |

## 🛠️ Technologies

- **Frontend** : Next.js 14, TypeScript, Tailwind CSS
- **Backend** : Node.js, Express, TypeScript
- **Base de données** : PostgreSQL Flexible Server
- **Infrastructure** : Azure Container Apps, Terraform
- **Monitoring** : Azure Log Analytics
- **CI/CD** : Scripts Bash optimisés

## 📁 Structure Projet

```
portail-cloud-container/
├── 🚀 deploy-optimized.sh       # Script de déploiement principal
├── 🔧 setup-prerequisites.sh    # Configuration automatique des outils
├── 📊 validate-deployment-clean.ps1  # Script de validation
├── 🌐 dashboard-frontend/       # Application Next.js
├── ⚙️  dashboard-backend/        # API Node.js
├── 🏗️ terraform/azure/          # Infrastructure Terraform
├── 🐳 docker-images/           # Images Docker de démonstration
└── 🔧 nginx/                   # Configuration Nginx
```

## 🎯 Endpoints Utiles

Une fois déployé :
- **Frontend** : `https://frontend-[votre-id].azurecontainerapps.io`
- **Backend API** : `https://backend-[votre-id].azurecontainerapps.io/api`
- **Health Check** : `https://backend-[votre-id].azurecontainerapps.io/api/health`
- **Database Status** : `https://backend-[votre-id].azurecontainerapps.io/api/health/db-status`

## ❓ Problèmes Courants

| Problème | Solution |
|----------|----------|
| Docker pas démarré | Lancer Docker Desktop manuellement |
| Erreur Azure CLI | `az logout` puis relancer le script |
| Timeout Terraform | Relancer `bash ./deploy-optimized.sh` |
| Conflit de ressources | `bash ./deploy-optimized.sh --clean` |

## 🏷️ Versions

- **Terraform** : 1.5.7
- **Azure CLI** : Dernière version
- **Node.js** : 18 LTS
- **Next.js** : 14.x

---

💡 **Astuce** : Le système utilise votre email Azure pour générer un ID unique. Toutes les ressources seront nommées `resource-[vos-8-premiers-chars]`.
# Supprimer toutes les ressources Azure
az group delete --name portail-cloud-dev-rg --yes
```

## 📊 Stack technique

- **Frontend** : Next.js, TypeScript, Tailwind CSS
- **Backend** : Node.js, Express, Socket.io
- **Database** : PostgreSQL 15
- **Cloud** : Azure Container Apps, Terraform
- **DevOps** : Infrastructure as Code, déploiement automatisé

## 🎯 Avantages Azure

- **Serverless** : Scaling automatique 0-N instances
- **Économique** : Pay-per-use, gratuit avec Azure Student  
- **Sécurisé** : HTTPS, isolation réseau
- **Monitoring** : Logs et métriques intégrés
- **Simple** : Un seul script pour tout déployer

---

> **Prêt à déployer ?** Lancez `.\deploy-simple.ps1` et votre app sera en ligne en quelques minutes ! 🎉
