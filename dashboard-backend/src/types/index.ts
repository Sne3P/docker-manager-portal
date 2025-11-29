export interface User {
  id: string;
  email: string;
  role: 'admin' | 'client';
  clientId?: string;
  name: string;
  createdAt: Date;
  lastLogin?: Date;
}

export interface Client {
  id: string;
  name: string;
  email: string;
  createdAt: Date;
  isActive: boolean;
  containerQuota: number;
  usedContainers: number;
}

export interface Container {
  id: string;
  name: string;
  image: string;
  status: 'created' | 'running' | 'paused' | 'restarting' | 'removing' | 'exited' | 'dead';
  clientId: string;
  serviceType: 'nginx' | 'nodejs' | 'python' | 'database' | 'custom';
  url?: string;
  created: string;
  labels: Record<string, string>;
  ports: ContainerPort[];
  networks: string[];
}

export interface ContainerPort {
  containerPort: number;
  hostPort: number;
  protocol: 'tcp' | 'udp';
}

export interface ContainerStats {
  containerId: string;
  cpu: {
    usage: number;
  };
  memory: {
    usage: number;
    limit: number;
    percent: number;
  };
  network: {
    rxBytes: number;
    txBytes: number;
  };
  timestamp: string;
}

export interface ContainerLog {
  timestamp: Date;
  stream: 'stdout' | 'stderr';
  content: string;
}

export interface CreateContainerRequest {
  name: string;
  image: string;
  clientId: string;
  serviceType: 'nginx' | 'nodejs' | 'python' | 'database' | 'custom';
  ports?: ContainerPort[];
  environment?: Record<string, string>;
  labels?: Record<string, string>;
  cmd?: string[];
}

export interface ContainerVolume {
  hostPath: string;
  containerPath: string;
  readOnly?: boolean;
}

export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  message?: string;
  error?: string;
  timestamp: Date;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface AuthResponse {
  user: Omit<User, 'password'>;
  token: string;
  expiresIn: string;
}

export interface SystemStats {
  totalContainers: number;
  runningContainers: number;
  totalClients: number;
  activeClients: number;
  systemLoad: {
    cpu: number;
    memory: number;
    disk: number;
  };
  recentActivity: ActivityLog[];
}

export interface ActivityLog {
  id: string;
  action: string;
  resource: string;
  userId: string;
  clientId?: string;
  timestamp: Date;
  details?: Record<string, any>;
}