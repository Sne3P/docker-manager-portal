# Demo Worker Service

## Description

Service worker de démonstration pour la plateforme de gestion de containers. Exécute des tâches de fond programmées et génère des logs détaillés pour le monitoring.

## Fonctionnalités

- **Exécution de tâches programmées**: Utilise node-cron pour planifier les tâches
- **Simulation de traitement de données**: Différents types de tâches avec durées variables
- **Logging détaillé**: Logs structurés avec informations client
- **Monitoring intégré**: Suivi des performances et erreurs
- **Arrêt gracieux**: Gestion propre des signaux SIGTERM/SIGINT

## Types de tâches

1. **Data Processing**: Traitement de lots de données clients
2. **Email Sending**: Envoi de notifications par email
3. **Report Generation**: Génération de rapports quotidiens
4. **Database Cleanup**: Nettoyage des données temporaires

## Variables d'environnement

```
SERVICE_NAME="Demo Worker Service"   # Nom du service
CLIENT_ID=client-1                   # ID du client propriétaire
TASK_INTERVAL="*/30 * * * * *"       # Intervalle d'exécution (cron format)
LOG_LEVEL=info                       # Niveau de log (debug, info, warn, error)
NODE_ENV=production                  # Environnement
```

## Formats de logs

Les logs incluent automatiquement :
- Timestamp ISO
- Niveau de log
- ID du client
- Détails de la tâche
- Métriques de performance

Exemple :
```
[2024-01-15T10:30:00.000Z] [INFO] [client-1] Starting task: data_processing | Data: {"taskId":"task_1705320600000_abc123","description":"Process customer data batch"}
```

## Utilisation

### Docker
```bash
docker build -t demo-worker-service .
docker run -e CLIENT_ID=client-1 -e TASK_INTERVAL="*/60 * * * * *" demo-worker-service
```

### Local
```bash
npm install
npm start
```

## Monitoring

Le service maintient automatiquement :
- Compteur de tâches exécutées
- Historique des 100 dernières tâches
- Liste des erreurs rencontrées
- Métriques système (CPU, mémoire)

## Intervalles de tâches

Le format cron supporte :
- `*/30 * * * * *` : Toutes les 30 secondes
- `0 */5 * * * *` : Toutes les 5 minutes  
- `0 0 */1 * * *` : Toutes les heures
- `0 0 0 * * *` : Une fois par jour

## Sécurité

- Utilisateur non-root dans le container
- Gestion des erreurs non catchées
- Arrêt gracieux sur signal système
- Logs sécurisés sans données sensibles