// Shared types between frontend and backend
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
  state: string;
  clientId: string;
  serviceType: 'api' | 'web' | 'worker' | 'database' | 'custom';
  ports: ContainerPort[];
  createdAt: Date;
  startedAt?: Date;
  stats?: ContainerStats;
  labels: Record<string, string>;
}

export interface ContainerPort {
  containerPort: number;
  hostPort: number;
  protocol: 'tcp' | 'udp';
}

export interface ContainerStats {
  cpuPercent: number;
  memoryUsage: number;
  memoryLimit: number;
  memoryPercent: number;
  networkRx: number;
  networkTx: number;
  blockRead: number;
  blockWrite: number;
}

export interface CreateContainerRequest {
  name: string;
  image: string;
  serviceType: Container['serviceType'];
  ports?: ContainerPort[];
  environment?: Record<string, string>;
  volumes?: ContainerVolume[];
  labels?: Record<string, string>;
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

// Frontend-specific types
export interface DashboardCardProps {
  title: string;
  value: string | number;
  icon: React.ComponentType<any>;
  trend?: {
    value: number;
    isPositive: boolean;
  };
  color?: 'blue' | 'green' | 'yellow' | 'red' | 'purple';
}

export interface TableColumn<T> {
  key: keyof T | string;
  label: string;
  render?: (value: any, item: T) => React.ReactNode;
  sortable?: boolean;
  className?: string;
}

export interface ContainerAction {
  id: string;
  label: string;
  icon: React.ComponentType<any>;
  action: (container: Container) => void | Promise<void>;
  variant: 'primary' | 'secondary' | 'success' | 'warning' | 'danger';
  disabled?: (container: Container) => boolean;
}

export interface NotificationOptions {
  type: 'success' | 'error' | 'warning' | 'info';
  title: string;
  message?: string;
  duration?: number;
}

export interface ServiceTemplate {
  id: string;
  name: string;
  description: string;
  image: string;
  serviceType: Container['serviceType'];
  defaultPorts: ContainerPort[];
  defaultEnvironment: Record<string, string>;
  category: 'web' | 'api' | 'database' | 'monitoring' | 'utility';
  icon: string;
}

export interface ResourceUsage {
  containerId: string;
  containerName: string;
  cpuPercent: number;
  memoryUsage: number;
  memoryLimit: number;
  memoryPercent: number;
  networkRx: number;
  networkTx: number;
}

export interface LogEntry {
  timestamp: string;
  level: 'info' | 'warn' | 'error' | 'debug';
  message: string;
  source: 'stdout' | 'stderr';
}