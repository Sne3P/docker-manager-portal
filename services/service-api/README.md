# Demo API Service

## Description

Service API de démonstration pour la plateforme de gestion de containers. Fournit des endpoints REST simples pour tester la gestion des containers.

## Fonctionnalités

- **Health Check**: Endpoint de santé pour monitoring
- **Users API**: Gestion des utilisateurs (lecture seule)
- **Products API**: Gestion des produits (lecture seule)
- **Echo Service**: Test des requêtes POST
- **Stats**: Statistiques du service

## Endpoints

```
GET  /              # Informations du service
GET  /health        # Health check
GET  /users         # Liste des utilisateurs
GET  /users/:id     # Utilisateur spécifique
GET  /products      # Liste des produits
GET  /products/:id  # Produit spécifique
POST /echo          # Echo des données
GET  /stats         # Statistiques du service
```

## Variables d'environnement

```
PORT=3001                    # Port d'écoute
SERVICE_NAME="Demo API"      # Nom du service
CLIENT_ID=client-1           # ID du client propriétaire
NODE_ENV=production          # Environnement
```

## Utilisation

### Docker
```bash
docker build -t demo-api-service .
docker run -p 3001:3001 -e CLIENT_ID=client-1 demo-api-service
```

### Local
```bash
npm install
npm start
```

## Exemples d'appels

```bash
# Health check
curl http://localhost:3001/health

# Liste des utilisateurs
curl http://localhost:3001/users

# Statistiques
curl http://localhost:3001/stats

# Echo test
curl -X POST http://localhost:3001/echo \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello World"}'
```