# Frontend Container Manager Dashboard

## 📋 Description

Interface utilisateur moderne développée avec Next.js et TypeScript pour la gestion des containers Docker multi-tenant. Interface intuitive et responsive avec monitoring en temps réel.

## 🚀 Fonctionnalités

### Interface Utilisateur
- Dashboard responsive avec Tailwind CSS
- Thème moderne avec dark mode support
- Composants réutilisables optimisés

### Authentification
- Connexion sécurisée avec JWT
- Gestion des sessions persistantes
- Redirection automatique selon les rôles

### Gestion des Containers
- Vue d'ensemble des containers par client
- Actions en temps réel (start/stop/restart/delete)
- Monitoring des performances (CPU, RAM, Network)
- Logs en direct via WebSocket

### Monitoring & Analytics
- Graphiques de performance avec Recharts
- Statistiques système en temps réel
- Alertes et notifications

## 🛠️ Technologies

- **Framework**: Next.js 14 avec App Router
- **Langage**: TypeScript pour la sécurité des types
- **Styling**: Tailwind CSS pour un design moderne
- **State Management**: React Query pour la gestion des données
- **Temps Réel**: Socket.IO client
- **UI Components**: HeadlessUI + Heroicons
- **Forms**: React Hook Form avec validation
- **Notifications**: React Hot Toast

## 📁 Structure

```
src/
├── components/          # Composants réutilisables
│   ├── ui/             # Composants UI de base
│   ├── layout/         # Layout et navigation
│   ├── dashboard/      # Composants dashboard
│   └── containers/     # Composants containers
├── pages/              # Pages Next.js
├── hooks/              # Custom React hooks
├── lib/                # API client et utilitaires
├── types/              # Types TypeScript
├── utils/              # Fonctions utilitaires
└── styles/             # Styles globaux
```

## 🚀 Installation

```bash
# Installation des dépendances
npm install

# Configuration environnement
cp .env.example .env.local

# Développement
npm run dev

# Build production
npm run build
npm start
```

## ⚙️ Configuration

### Variables d'environnement

```env
NEXT_PUBLIC_API_URL=http://localhost:5000/api
NEXT_PUBLIC_SOCKET_URL=http://localhost:5000
NEXT_PUBLIC_APP_NAME="Container Manager"
```

## 🎨 Pages Principales

### `/dashboard` - Tableau de bord
- Vue d'ensemble système
- Statistiques containers
- Activité récente

### `/containers` - Gestion containers
- Liste complète des containers
- Filtrage par statut/client
- Actions groupées

### `/monitoring` - Surveillance
- Graphiques de performance
- Utilisation des ressources
- Logs système

### `/clients` - Gestion clients (Admin)
- CRUD complet des clients
- Quotas et permissions
- Statistiques par client

## 🔒 Sécurité

- Authentification JWT avec refresh automatique
- Validation des formulaires côté client
- Protection CSRF et XSS
- Permissions basées sur les rôles

## 📱 Responsive Design

- Design mobile-first avec Tailwind
- Breakpoints optimisés pour tous écrans
- Navigation adaptative
- Touch-friendly sur mobile

## 🎯 Performance

- Server-Side Rendering avec Next.js
- Code splitting automatique
- Lazy loading des composants
- Images optimisées
- Caching intelligent avec React Query

## 🧪 Tests & Qualité

```bash
# Type checking
npm run type-check

# Linting
npm run lint
```

## 🐳 Docker

```bash
# Build de l'image
docker build -t container-manager-frontend .

# Lancement
docker run -p 3000:3000 container-manager-frontend
```