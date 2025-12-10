# 🤖 Cloud Agent - Guide Complet

## Qu'est-ce qu'un Cloud Agent ?

Un **Cloud Agent** (Agent Cloud) est un composant logiciel qui s'exécute dans l'infrastructure cloud (Azure dans notre cas) et qui sert d'intermédiaire intelligent entre les utilisateurs et les ressources Docker. Il agit comme un gestionnaire automatisé qui orchestre et surveille les conteneurs Docker pour plusieurs clients simultanément.

## 🎯 Rôle et Objectifs

### Rôle Principal
Le Cloud Agent de cette plateforme est responsable de :

1. **Gestion Multi-tenant** : Isoler et gérer les conteneurs de plusieurs clients sur la même infrastructure
2. **Orchestration Docker** : Créer, démarrer, arrêter et supprimer des conteneurs Docker de manière sécurisée
3. **Surveillance en Temps Réel** : Monitorer les performances (CPU, mémoire, réseau) de chaque conteneur
4. **Sécurité** : Assurer l'isolation entre les ressources des différents clients
5. **API Gateway** : Exposer des endpoints REST pour permettre la gestion via l'interface web

### Objectifs
- ✅ **Automatisation** : Réduire les interventions manuelles dans la gestion des conteneurs
- ✅ **Scalabilité** : Gérer des centaines de conteneurs pour plusieurs clients
- ✅ **Fiabilité** : Assurer la disponibilité des services avec monitoring et health checks
- ✅ **Sécurité** : Isolation stricte entre les ressources de chaque client

## 🏗️ Architecture Technique

### Composants du Cloud Agent

```
┌─────────────────────────────────────────────────┐
│           Frontend (Next.js)                    │
│           Port: 3000                            │
└────────────────┬────────────────────────────────┘
                 │ HTTP/WebSocket
                 ▼
┌─────────────────────────────────────────────────┐
│     Cloud Agent Backend (Node.js + Express)     │
│     - API REST                                  │
│     - Authentification JWT                      │
│     - Gestion Multi-tenant                      │
│     Port: 5000                                  │
└────────────────┬────────────────────────────────┘
                 │ Docker SDK
                 ▼
┌─────────────────────────────────────────────────┐
│         Docker Engine                           │
│         - Création de conteneurs                │
│         - Gestion du cycle de vie               │
│         - Monitoring des ressources             │
└─────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│    Conteneurs Client                            │
│    - Nginx, Node.js, Python, Databases, etc.    │
└─────────────────────────────────────────────────┘
```

### Stack Technique

**Backend (Cloud Agent Core)**
- **Node.js 18+** : Environnement d'exécution JavaScript côté serveur
- **TypeScript** : Typage statique pour la fiabilité du code
- **Express.js** : Framework web pour l'API REST
- **Dockerode** : SDK Docker officiel pour Node.js
- **JWT** : Authentification sécurisée par token
- **PostgreSQL** : Base de données pour la persistance

**Infrastructure Cloud**
- **Azure App Service** : Hébergement de l'agent backend
- **Azure PostgreSQL** : Base de données managée avec SSL
- **Azure Container Registry** : Stockage des images Docker
- **Docker Engine** : Moteur de conteneurisation

## 🔄 Fonctionnement

### 1. Authentification
```typescript
// L'utilisateur se connecte via l'interface web
POST /api/auth/login
{
  "email": "client@example.com",
  "password": "password123"
}

// Le Cloud Agent valide les credentials et retourne un JWT
Response: {
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": { "id": "123", "role": "client" }
}
```

### 2. Création de Conteneur
```typescript
// Le client demande la création d'un service Nginx
POST /api/containers/create
Authorization: Bearer <JWT>
{
  "serviceType": "nginx",
  "name": "my-web-server"
}

// Le Cloud Agent :
// 1. Vérifie les quotas du client
// 2. Crée le conteneur avec labels client
// 3. Démarre le conteneur
// 4. Retourne l'URL d'accès
Response: {
  "containerId": "abc123...",
  "url": "http://client123-nginx.localhost:8080",
  "status": "running"
}
```

### 3. Monitoring
```typescript
// Le Cloud Agent collecte les métriques en continu
GET /api/containers/:id/stats

Response: {
  "cpu": { "usage": 15.5 },
  "memory": { 
    "usage": 134217728,
    "limit": 536870912,
    "percent": 25.0,
    "usageFormatted": "128 MB",
    "limitFormatted": "512 MB"
  },
  "network": {
    "rxBytes": 1048576,
    "txBytes": 2097152,
    "rxFormatted": "1 MB",
    "txFormatted": "2 MB"
  }
}
```

## 🔐 Sécurité et Isolation

### Isolation Multi-tenant

Le Cloud Agent assure l'isolation entre clients via :

1. **Labels Docker** : Chaque conteneur est taggé avec l'ID client
```typescript
labels: {
  clientId: "client-123",
  serviceType: "nginx",
  "com.container-manager.managed": "true"
}
```

2. **Filtrage des Requêtes** : Les clients ne voient que leurs propres conteneurs
```typescript
// Le middleware vérifie que containerId appartient au client
if (container.labels.clientId !== user.clientId) {
  return res.status(403).json({ error: "Access denied" });
}
```

3. **Quotas** : Limitation du nombre de conteneurs par client
```typescript
if (client.usedContainers >= client.containerQuota) {
  throw new Error("Container quota exceeded");
}
```

### Authentification JWT

```typescript
// Génération du token avec expiration
const token = jwt.sign(
  { userId: user.id, role: user.role, clientId: user.clientId },
  JWT_SECRET,
  { expiresIn: '24h' }
);

// Validation sur chaque requête
const middleware = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  const decoded = jwt.verify(token, JWT_SECRET);
  req.user = decoded;
  next();
};
```

## 📊 Services Gérés

Le Cloud Agent peut créer et gérer plusieurs types de services :

### 1. Nginx Web Server
```yaml
Image: nginx:alpine
Port: 80 → Host dynamique
Usage: Serveur web statique, reverse proxy
```

### 2. Node.js Application
```yaml
Image: node:18-alpine
Port: 3000 → Host dynamique
Usage: Applications JavaScript backend
```

### 3. Python Application
```yaml
Image: python:3.11-alpine
Port: 8000 → Host dynamique
Usage: Applications Python, APIs Flask/FastAPI
```

### 4. Database Service
```yaml
Image: postgres:15-alpine
Port: 5432 → Host dynamique
Usage: Base de données relationnelle
```

## 🚀 Déploiement sur Azure

### Déploiement Automatisé

Le Cloud Agent est déployé automatiquement via :

```bash
# Déploiement complet en une commande
.\deploy-production.ps1
```

Ce script :
1. ✅ Configure l'infrastructure Azure (App Service, PostgreSQL, Container Registry)
2. ✅ Compile les applications (Backend + Frontend)
3. ✅ Déploie le Cloud Agent sur Azure App Service
4. ✅ Configure les variables d'environnement
5. ✅ Initialise la base de données
6. ✅ Active le monitoring et health checks

### Infrastructure Créée

```
Azure Resource Group
├── App Service Plan (Linux)
│   ├── Backend Web App (Cloud Agent)
│   │   └── Node.js 18 Runtime
│   └── Frontend Web App
│       └── Next.js Static Export
├── PostgreSQL Flexible Server
│   └── Database: containerdb
└── Container Registry (ACR)
    └── Images Docker privées
```

## 🔧 Configuration

### Variables d'Environnement

```bash
# Backend (Cloud Agent)
PORT=5000
NODE_ENV=production
DATABASE_URL=postgresql://user:pass@host:5432/db
JWT_SECRET=your-secure-secret-key
DOCKER_SOCKET=/var/run/docker.sock

# Frontend
NEXT_PUBLIC_API_URL=https://api.example.com
NEXT_PUBLIC_WS_URL=wss://api.example.com
```

### Fichier docker-compose.yml

```yaml
services:
  backend:
    # Cloud Agent Backend
    build: ./dashboard-backend
    ports:
      - "5000:5000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - JWT_SECRET=${JWT_SECRET}
    
  frontend:
    # Interface utilisateur
    build: ./dashboard-frontend
    ports:
      - "3000:3000"
    environment:
      - NEXT_PUBLIC_API_URL=http://backend:5000
```

## 📈 Monitoring et Health Checks

### Endpoints de Santé

```typescript
// Vérifier l'état du Cloud Agent
GET /api/health

Response: {
  "status": "healthy",
  "timestamp": "2025-12-10T10:00:00Z",
  "services": {
    "database": "connected",
    "docker": "available"
  },
  "version": "1.0.0"
}
```

### Métriques Système

```typescript
// Statistiques globales de la plateforme
GET /api/admin/stats

Response: {
  "totalContainers": 45,
  "runningContainers": 38,
  "totalClients": 12,
  "activeClients": 10,
  "systemLoad": {
    "cpu": 35.5,
    "memory": 62.3,
    "disk": 45.8
  }
}
```

## 💡 Cas d'Usage

### Scénario 1 : Hébergement Multi-tenant
Une entreprise héberge des sites web pour plusieurs clients. Le Cloud Agent :
- Crée un conteneur Nginx isolé par client
- Assigne des ports uniques automatiquement
- Surveille la consommation de ressources
- Applique les quotas définis

### Scénario 2 : Environnements de Développement
Des développeurs ont besoin d'environnements temporaires. Le Cloud Agent :
- Provisionne rapidement des conteneurs Node.js/Python
- Fournit des URLs d'accès direct
- Nettoie automatiquement les ressources inutilisées

### Scénario 3 : Tests et CI/CD
Exécution de tests dans des conteneurs éphémères. Le Cloud Agent :
- Crée des environnements de test isolés
- Collecte les logs et métriques
- Supprime les conteneurs après les tests

## 🎓 Pour les Débutants

### C'est quoi un Agent ?
Un **agent** en informatique est un programme qui agit de manière autonome pour accomplir des tâches. Pensez-y comme un **assistant robotique** qui travaille pour vous sans intervention constante.

### Pourquoi "Cloud" ?
Parce que cet agent s'exécute dans le **cloud** (Azure, AWS, etc.) plutôt que sur votre ordinateur local. Cela signifie :
- 🌍 Accessible de n'importe où
- ⚡ Haute disponibilité (24/7)
- 📈 Scalable selon les besoins
- 💰 Paiement à l'usage

### Analogie Simple
Le Cloud Agent est comme un **concierge intelligent d'un immeuble** :
- Il gère plusieurs appartements (conteneurs) pour plusieurs locataires (clients)
- Il s'assure que chaque locataire ne peut accéder qu'à son propre appartement
- Il surveille l'état des installations (CPU, mémoire)
- Il peut créer ou fermer des appartements à la demande
- Il garde un registre de toutes les activités

## 📚 Ressources

### Code Source
- **Backend** : `/dashboard-backend/src/services/dockerService.ts`
- **Routes API** : `/dashboard-backend/src/routes/`
- **Types** : `/dashboard-backend/src/types/index.ts`

### Documentation API
```
POST   /api/auth/login              - Authentification
GET    /api/containers              - Lister les conteneurs
POST   /api/containers/create       - Créer un conteneur
POST   /api/containers/:id/start    - Démarrer un conteneur
POST   /api/containers/:id/stop     - Arrêter un conteneur
DELETE /api/containers/:id          - Supprimer un conteneur
GET    /api/containers/:id/logs     - Obtenir les logs
GET    /api/containers/:id/stats    - Obtenir les métriques
```

### Références Externes
- [Docker SDK for Node.js (Dockerode)](https://github.com/apocas/dockerode)
- [Azure App Service Documentation](https://docs.microsoft.com/azure/app-service/)
- [Multi-tenant Architecture Patterns](https://docs.microsoft.com/azure/architecture/patterns/multi-tenancy)

## 🔮 Évolutions Futures

### Fonctionnalités Planifiées
- [ ] Auto-scaling des conteneurs selon la charge
- [ ] Snapshots et backups automatiques
- [ ] Intégration de Kubernetes pour orchestration avancée
- [ ] Dashboard de métriques en temps réel avec graphiques
- [ ] Alertes et notifications (email, Slack, Teams)
- [ ] Support de Docker Compose multi-conteneurs
- [ ] API GraphQL en complément de REST

## 🤝 Contribuer

Pour améliorer le Cloud Agent :

1. Fork le repository
2. Créer une branche feature (`git checkout -b feature/amelioration`)
3. Commit les changes (`git commit -m 'Ajout fonctionnalité X'`)
4. Push vers la branche (`git push origin feature/amelioration`)
5. Ouvrir une Pull Request

---

**💼 Support** : Pour toute question, ouvrir une issue sur GitHub
**📧 Contact** : [Voir README.md](./README.md)
**📄 Licence** : Voir [LICENSE](./LICENSE)
