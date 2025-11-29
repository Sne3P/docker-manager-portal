# Backend Container Manager API

## 📋 Description

API REST pour la gestion des containers Docker multi-tenant. Développée avec Express.js et TypeScript pour une performance optimale et une maintenance simplifiée.

## 🚀 Fonctionnalités

### Authentification & Autorisation
- JWT-based authentication
- Gestion multi-tenant (Admin/Client)
- Middleware d'autorisation par rôle

### Gestion des Containers
- CRUD complet des containers Docker
- Support multi-clients avec isolation
- Actions: start, stop, restart, remove
- Monitoring en temps réel

### API Endpoints

#### Authentication
```
POST /api/auth/login          # Connexion utilisateur
GET  /api/auth/me             # Informations utilisateur
POST /api/auth/logout         # Déconnexion
```

#### Containers
```
GET    /api/containers        # Liste des containers
POST   /api/containers        # Créer un container
GET    /api/containers/:id    # Détails d'un container
POST   /api/containers/:id/start   # Démarrer
POST   /api/containers/:id/stop    # Arrêter
POST   /api/containers/:id/restart # Redémarrer
DELETE /api/containers/:id    # Supprimer
GET    /api/containers/:id/logs    # Logs
GET    /api/containers/:id/stats   # Statistiques
```

#### Clients (Admin only)
```
GET    /api/clients           # Liste des clients
POST   /api/clients           # Créer un client
GET    /api/clients/:id       # Détails d'un client
PUT    /api/clients/:id       # Modifier un client
DELETE /api/clients/:id       # Supprimer un client
```

#### Monitoring
```
GET /api/monitoring/system     # Statistiques système
GET /api/monitoring/resources  # Usage des ressources
GET /api/monitoring/health     # Health check
```

## 🛠️ Installation

```bash
# Installation des dépendances
npm install

# Configuration environnement
cp .env.example .env

# Build TypeScript
npm run build

# Développement avec hot reload
npm run dev

# Production
npm start
```

## ⚙️ Configuration

### Variables d'environnement

```env
NODE_ENV=development
PORT=5000
JWT_SECRET=your-jwt-secret
DOCKER_SOCKET_PATH=/var/run/docker.sock
FRONTEND_URL=http://localhost:3000
```

### Comptes de test

**Admin:**
- Email: `admin@containerplatform.com`
- Password: `admin123`

**Clients:**
- Email: `client1@example.com` / Password: `client123`
- Email: `client2@example.com` / Password: `client123`

## 🐳 Docker

```bash
# Build de l'image
docker build -t container-manager-backend .

# Lancement avec Docker Compose
docker-compose up backend
```

## 📊 Monitoring & Logs

- Logs structurés avec Winston
- Métriques temps réel via Socket.IO
- Health checks intégrés
- Rate limiting et sécurité

## 🔒 Sécurité

- Helmet.js pour les headers de sécurité
- CORS configuré
- Rate limiting
- Validation des inputs avec express-validator
- JWT avec expiration

## 🧪 Tests

```bash
# Tests unitaires
npm test

# Linting
npm run lint
```

## 📝 Architecture

```
src/
├── routes/           # Routes API
├── services/         # Services métier
├── middleware/       # Middlewares Express
├── types/           # Types TypeScript
├── utils/           # Utilitaires
└── server.ts        # Point d'entrée
```