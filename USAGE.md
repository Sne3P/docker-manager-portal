# Exemples d'utilisation - Portail Cloud Container

## 🚀 Déploiement Local

### Windows PowerShell
```powershell
# Option 1: Script universel (recommandé)
bash ./deploy-universal.sh

# Option 2: Commande Docker directe
docker build -f Dockerfile.simple -t portail-deploy . ; docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock -v ${PWD}:/workspace -v portail-azure-credentials:/root/.azure portail-deploy ./deploy-optimized.sh

# Option 3: Direct sur machine (peut poser problèmes)
bash ./deploy-optimized.sh
```

### Linux/macOS
```bash
# Option 1: Script universel (recommandé)
./deploy-universal.sh

# Option 2: Commande Docker directe
docker build -f Dockerfile.simple -t portail-deploy . && docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock -v $(pwd):/workspace -v portail-azure-credentials:/root/.azure portail-deploy ./deploy-optimized.sh

# Option 3: Direct sur machine
./deploy-optimized.sh
```

## 🤖 CI/CD Pipelines

### GitHub Actions
```yaml
name: Deploy Portail Cloud
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Deploy to Azure
        run: bash ./deploy-universal.sh
        env:
          AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
          AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
          AZURE_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
```

### GitLab CI
```yaml
deploy:
  stage: deploy
  image: docker:latest
  services:
    - docker:dind
  script:
    - bash ./deploy-universal.sh
  only:
    - main
```

### Azure DevOps
```yaml
trigger:
- main

pool:
  vmImage: 'ubuntu-latest'

steps:
- script: bash ./deploy-universal.sh
  displayName: 'Deploy Portail Cloud'
```

### Jenkins
```groovy
pipeline {
    agent any
    stages {
        stage('Deploy') {
            steps {
                sh 'bash ./deploy-universal.sh'
            }
        }
    }
}
```

## 🔧 Configurations Avancées

### Déploiement avec paramètres personnalisés
```bash
# Clean deploy (supprime tout avant)
./deploy-universal.sh --clean

# Skip build (garde les images existantes)
./deploy-universal.sh --skip-build
```

### Variables d'environnement
```bash
# Configuration Azure personnalisée
export AZURE_SUBSCRIPTION_ID="votre-subscription-id"
export AZURE_RESOURCE_GROUP_PREFIX="mon-prefix"
./deploy-universal.sh
```

## 🐛 Résolution de Problèmes

### Si Docker n'est pas installé
```bash
# Ubuntu/Debian
sudo apt-get update && sudo apt-get install docker.io

# macOS
brew install docker

# Windows
# Installer Docker Desktop depuis docker.com
```

### Si la connexion Azure échoue
```bash
# Dans le container, faire manuellement:
docker run -it portail-deploy bash
az login --use-device-code
./deploy-optimized.sh
```

### Redémarrage complet
```bash
# Supprimer toutes les ressources Azure et recommencer
./deploy-universal.sh --clean
```