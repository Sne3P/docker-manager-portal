# Demo Web Service

## Description

Service web de démonstration basé sur Nginx pour la plateforme de gestion de containers. Interface web statique optimisée et sécurisée.

## Fonctionnalités

- **Interface moderne**: Design responsive et attractif
- **Health Check**: Endpoint de santé pour monitoring
- **Sécurité**: Headers de sécurité configurés
- **Performance**: Compression gzip et cache optimisé
- **Monitoring**: Logs détaillés avec informations client

## Endpoints

```
GET /           # Page d'accueil du service
GET /health     # Health check (JSON)
GET /nginx_status # Statut Nginx (monitoring interne)
```

## Configuration Nginx

- Compression gzip activée
- Headers de sécurité
- Cache des assets statiques (1 an)
- Pages d'erreur personnalisées
- Logs avec informations client

## Utilisation

### Docker
```bash
docker build -t demo-web-service .
docker run -p 8080:80 demo-web-service
```

### Test local
```bash
# Démarrer le container
docker run -d -p 8080:80 --name demo-web demo-web-service

# Tester l'interface
curl http://localhost:8080

# Health check
curl http://localhost:8080/health
```

## Personnalisation par client

Le service accepte un paramètre `client` dans l'URL pour personnaliser l'affichage :

```
http://localhost:8080/?client=client-1
```

## Monitoring

- Logs Nginx avec format personnalisé incluant l'ID client
- Endpoint de health check pour surveillance automatique
- Métriques Nginx via `/nginx_status` (accès restreint)

## Sécurité

- Headers de sécurité (X-Frame-Options, X-Content-Type-Options, etc.)
- Déni d'accès aux fichiers sensibles
- Utilisateur non-root dans le container
- Image basée sur Alpine Linux (surface d'attaque réduite)