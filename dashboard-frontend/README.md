# Container Manager

Multi-tenant Docker container management platform with web dashboard.

## Quick Start

```bash
docker-compose up -d --build
```

Access: http://localhost

## Login

- **Admin**: admin@containerplatform.com / admin123
- **Client**: client1@example.com / client123

## Features

- JWT Authentication
- Docker Container Management
- Multi-tenant Support
- Web Dashboard

## Services

- **Backend**: Node.js API (port 5000)
- **Frontend**: Next.js Web App (port 3000)
- **Nginx**: Reverse Proxy (port 80)
- **Redis**: Cache & Sessions (port 6379)

## Container Operations

Create predefined services:
- Nginx Web Server
- Node.js App
- Python App  
- Database Service

## Development

Backend:
```bash
cd dashboard-backend && npm run dev
```

Frontend:
```bash
cd dashboard-frontend && npm run dev
```
