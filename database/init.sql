-- Initialisation de la base de données PostgreSQL
-- Script exécuté automatiquement au démarrage du container PostgreSQL

-- Table des utilisateurs avec authentification sécurisée
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'client' CHECK (role IN ('admin', 'client')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- Table des clients (métadonnées enrichies)
CREATE TABLE IF NOT EXISTS clients (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    docker_container_id VARCHAR(255), -- ID du container Docker associé
    docker_image VARCHAR(255),
    status VARCHAR(50) DEFAULT 'inactive', -- active, inactive, error
    port_mappings JSONB, -- Configuration des ports
    environment_vars JSONB, -- Variables d'environnement
    resource_limits JSONB, -- Limites CPU/RAM
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table des logs d'activité (audit trail)
CREATE TABLE IF NOT EXISTS activity_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    client_id INTEGER REFERENCES clients(id),
    action VARCHAR(100) NOT NULL, -- start, stop, delete, create, update
    details JSONB,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address INET
);

-- Table des métriques de containers (optionnel pour monitoring)
CREATE TABLE IF NOT EXISTS container_metrics (
    id SERIAL PRIMARY KEY,
    client_id INTEGER REFERENCES clients(id),
    cpu_usage DECIMAL(5,2),
    memory_usage_mb INTEGER,
    network_rx_bytes BIGINT,
    network_tx_bytes BIGINT,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index pour performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_clients_name ON clients(name);
CREATE INDEX IF NOT EXISTS idx_clients_status ON clients(status);
CREATE INDEX IF NOT EXISTS idx_activity_logs_timestamp ON activity_logs(timestamp);
CREATE INDEX IF NOT EXISTS idx_activity_logs_user_id ON activity_logs(user_id);

-- Trigger pour mettre à jour updated_at automatiquement
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_clients_updated_at BEFORE UPDATE ON clients
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Données d'exemple pour démarrer
INSERT INTO users (email, password_hash, role) VALUES 
    ('admin@portail-cloud.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/lewfBmdJ6Ne0W6NPq', 'admin'), -- password: admin123
    ('client1@portail-cloud.com', '$2b$12$17AY7lPOLzOrycJIjZi3yeU0WFyciKm5uKMW.o9bSc1M5JRN6aybC', 'client'), -- password: client123
    ('client2@portail-cloud.com', '$2b$12$17AY7lPOLzOrycJIjZi3yeU0WFyciKm5uKMW.o9bSc1M5JRN6aybC', 'client'), -- password: client123
    ('client3@portail-cloud.com', '$2b$12$17AY7lPOLzOrycJIjZi3yeU0WFyciKm5uKMW.o9bSc1M5JRN6aybC', 'client') -- password: client123
ON CONFLICT (email) DO NOTHING;