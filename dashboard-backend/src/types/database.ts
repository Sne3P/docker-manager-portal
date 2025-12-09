export interface User {
  id: number;
  email: string;
  password_hash: string;
  role: 'admin' | 'client';
  created_at: Date;
  updated_at: Date;
  is_active: boolean;
}

export interface Client {
  id: number;
  name: string;
  description?: string;
  docker_container_id?: string;
  docker_image?: string;
  status: 'active' | 'inactive' | 'error';
  port_mappings?: Record<string, any>;
  environment_vars?: Record<string, any>;
  resource_limits?: Record<string, any>;
  created_by: number;
  created_at: Date;
  updated_at: Date;
}

export interface ActivityLog {
  id: number;
  user_id: number;
  client_id?: number;
  action: string;
  details?: Record<string, any>;
  timestamp: Date;
  ip_address?: string;
}

export interface ContainerMetrics {
  id: number;
  client_id: number;
  cpu_usage: number;
  memory_usage_mb: number;
  network_rx_bytes: number;
  network_tx_bytes: number;
  recorded_at: Date;
}

// Types pour l'authentification
export interface LoginRequest {
  email: string;
  password: string;
}

export interface LoginResponse {
  success: boolean;
  data?: {
    token: string;
    user: Omit<User, 'password_hash'>;
  };
  message?: string;
}

// Types pour les containers enrichis (Docker + BDD)
export interface EnrichedContainer extends Client {
  // Données en temps réel du Docker
  docker_status?: 'running' | 'stopped' | 'paused' | 'restarting';
  docker_created?: Date;
  docker_started?: Date;
  docker_ports?: Array<{
    private_port: number;
    public_port?: number;
    type: string;
  }>;
  docker_image_id?: string;
  docker_size?: number;
  docker_networks?: string[];
}