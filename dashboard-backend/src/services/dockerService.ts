import Docker from 'dockerode';
import { Container, ContainerStats, CreateContainerRequest } from '../types';
import { logger } from '../utils/logger';
import { azureContainerService } from './azureContainerService';
import * as fs from 'fs';

class DockerService {
  private docker: Docker | null = null;
  private isAzureEnvironment: boolean;

  constructor() {
    // Detect if we're running in Azure or local environment
    this.isAzureEnvironment = this.detectAzureEnvironment();
    
    if (!this.isAzureEnvironment) {
      this.docker = new Docker({
        socketPath: process.env.DOCKER_SOCKET || '/var/run/docker.sock'
      });
    }
    
    logger.info(`Docker service initialized for ${this.isAzureEnvironment ? 'Azure' : 'local'} environment`);
  }

  private detectAzureEnvironment(): boolean {
    // Check for explicit Azure environment variable
    if (process.env.AZURE_ENVIRONMENT === 'true') {
      return true;
    }
    
    // Check for Azure Container Apps environment variables
    if (process.env.CONTAINER_APP_NAME || process.env.AZURE_CLIENT_ID) {
      return true;
    }
    
    // Check if NODE_ENV is production and DATABASE_URL contains Azure
    if (process.env.NODE_ENV === 'production' && process.env.DATABASE_URL?.includes('postgres.database.azure.com')) {
      return true;
    }
    
    // Check if Docker socket exists (local environment)
    try {
      const socketPath = process.env.DOCKER_SOCKET || '/var/run/docker.sock';
      return !fs.existsSync(socketPath);
    } catch {
      return true; // Assume Azure if we can't check
    }
  }

  async listContainers(clientId?: string, includeMetrics: boolean = false): Promise<Container[]> {
    try {
      // Use Azure Container Service in production (simulation mode)
      if (this.isAzureEnvironment) {
        logger.info('Using Azure simulation mode for containers');
        return await azureContainerService.listContainers(clientId, includeMetrics);
      }

      // Use local Docker in development
      if (!this.docker) {
        throw new Error('Docker client not initialized');
      }

      const containers = await this.docker.listContainers({ all: true });
      
      const filteredContainers = containers.filter((container: any) => {
        // Filter by client if specified
        return !clientId || container.Labels?.clientId === clientId;
      });

      return await Promise.all(filteredContainers.map(async (container: any) => {
        const baseContainer = {
          id: container.Id,
          name: container.Names[0]?.substring(1), // Remove leading slash
          image: container.Image,
          status: container.State,
          created: new Date(container.Created * 1000).toISOString(),
          clientId: container.Labels?.clientId || container.Labels?.client || '',
          serviceType: container.Labels?.serviceType || 'custom',
          url: this.generateContainerUrl(container),
          labels: container.Labels || {},
          ports: container.Ports?.map((port: any) => ({
            containerPort: port.PrivatePort,
            hostPort: port.PublicPort,
            protocol: port.Type as 'tcp' | 'udp'
          })) || [],
          networks: Object.keys(container.NetworkSettings?.Networks || {}),
        };

        // Ajouter les métriques si demandées et si le container est en cours d'exécution
        if (includeMetrics && container.State === 'running') {
          try {
            const stats = await this.getContainerStats(container.Id);
            return {
              ...baseContainer,
              metrics: {
                cpu: stats.cpu,
                memory: {
                  ...stats.memory,
                  usageFormatted: this.formatBytes(stats.memory.usage),
                  limitFormatted: this.formatBytes(stats.memory.limit)
                },
                network: {
                  ...stats.network,
                  rxFormatted: this.formatBytes(stats.network.rxBytes),
                  txFormatted: this.formatBytes(stats.network.txBytes)
                },
                uptime: Math.floor((Date.now() - new Date(container.Created * 1000).getTime()) / 1000),
                lastUpdated: stats.timestamp
              }
            };
          } catch (error) {
            logger.warn(`Failed to get metrics for container ${container.Id}:`, error);
            return baseContainer;
          }
        }

        return baseContainer;
      }));
    } catch (error) {
      logger.error('Failed to list containers:', error);
      throw new Error('Failed to retrieve containers');
    }
  }

  private generateContainerUrl(container: any): string | undefined {
    const port = container.Ports?.find((p: any) => p.PublicPort);
    if (port) {
      return `http://localhost:${port.PublicPort}`;
    }
    return undefined;
  }

  private formatBytes(bytes: number): string {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }

  async createContainer(request: CreateContainerRequest): Promise<string> {
    try {
      // Use Azure Container Service in production
      if (this.isAzureEnvironment) {
        logger.info('Creating container in Azure mode');
        const container = await azureContainerService.createContainer(request, request.clientId);
        return container.id;
      }

      // Use local Docker in development
      if (!this.docker) {
        throw new Error('Docker client not initialized');
      }

      const { name, image, ports = [], environment = {}, labels = {}, clientId } = request;
      
      // Add client ID to labels for multi-tenant isolation
      const containerLabels = {
        ...labels,
        clientId,
        'com.container-manager.created': new Date().toISOString()
      };

      const createOptions: any = {
        Image: image,
        name: `${clientId}-${name}`,
        Labels: containerLabels,
        Env: Object.entries(environment).map(([key, value]) => `${key}=${value}`),
        ExposedPorts: {} as Record<string, {}>,
        HostConfig: {
          PortBindings: {} as Record<string, Array<{ HostPort: string }>>
        }
      };

      // Add command if specified
      if (request.cmd) {
        createOptions.Cmd = request.cmd;
      }

      // Configure port mappings
      if (ports.length > 0) {
        ports.forEach(port => {
          const portKey = `${port.containerPort}/${port.protocol}`;
          createOptions.ExposedPorts[portKey] = {};
          createOptions.HostConfig.PortBindings[portKey] = [
            { HostPort: port.hostPort?.toString() || '0' }
          ];
        });
      }

      const container = await this.docker.createContainer(createOptions);
      
      logger.info(`Container created: ${container.id} for client: ${clientId}`);
      return container.id;
    } catch (error: any) {
      logger.error('Failed to create container:', error);
      throw new Error(`Failed to create container: ${error.message || 'Unknown error'}`);
    }
  }

  async startContainer(id: string): Promise<void> {
    try {
      // Use Azure Container Service in production
      if (this.isAzureEnvironment) {
        await azureContainerService.startContainer(id);
        return;
      }

      // Use local Docker in development
      if (!this.docker) {
        throw new Error('Docker client not initialized');
      }

      const container = this.docker.getContainer(id);
      await container.start();
    } catch (error: any) {
      throw new Error(`Failed to start container: ${error.message || 'Unknown error'}`);
    }
  }

  async stopContainer(id: string): Promise<void> {
    try {
      // Use Azure Container Service in production
      if (this.isAzureEnvironment) {
        await azureContainerService.stopContainer(id);
        return;
      }

      // Use local Docker in development
      if (!this.docker) {
        throw new Error('Docker client not initialized');
      }

      const container = this.docker.getContainer(id);
      await container.stop();
    } catch (error: any) {
      throw new Error(`Failed to stop container: ${error.message || 'Unknown error'}`);
    }
  }

  async restartContainer(id: string): Promise<void> {
    try {
      // In Azure, restart = stop + start
      if (this.isAzureEnvironment) {
        await azureContainerService.stopContainer(id);
        await azureContainerService.startContainer(id);
        return;
      }
      
      if (!this.docker) {
        throw new Error('Docker client not initialized');
      }
      
      const container = this.docker.getContainer(id);
      await container.restart();
      logger.info(`Container restarted: ${id}`);
    } catch (error: any) {
      logger.error(`Failed to restart container ${id}:`, error);
      throw new Error(`Failed to restart container: ${error.message || 'Unknown error'}`);
    }
  }

  async removeContainer(id: string): Promise<void> {
    try {
      if (this.isAzureEnvironment) {
        await azureContainerService.removeContainer(id);
        return;
      }
      
      if (!this.docker) {
        throw new Error('Docker client not initialized');
      }
      
      const container = this.docker.getContainer(id);
      await container.remove({ force: true });
      logger.info(`Container removed: ${id}`);
    } catch (error: any) {
      logger.error(`Failed to remove container ${id}:`, error);
      throw new Error(`Failed to remove container: ${error.message || 'Unknown error'}`);
    }
  }

  async getContainerLogs(id: string, tail: number = 100): Promise<string[]> {
    try {
      if (this.isAzureEnvironment) {
        const logs = await azureContainerService.getContainerLogs(id);
        return logs.split('\n').filter(line => line.trim());
      }
      
      if (!this.docker) {
        throw new Error('Docker client not initialized');
      }
      
      const container = this.docker.getContainer(id);
      const logs = await container.logs({
        stdout: true,
        stderr: true,
        tail,
        timestamps: true
      });
      
      return logs.toString().split('\n').filter(line => line.trim());
    } catch (error: any) {
      logger.error(`Failed to get logs for container ${id}:`, error);
      throw new Error(`Failed to get container logs: ${error.message || 'Unknown error'}`);
    }
  }

  async getContainerStats(id: string): Promise<ContainerStats> {
    try {
      // In Azure, return mock stats (real Azure monitoring would use different APIs)
      if (this.isAzureEnvironment) {
        return {
          containerId: id,
          cpu: { usage: Math.random() * 50 }, // Mock usage 0-50%
          memory: { usage: Math.random() * 1024 * 1024 * 500, limit: 1024 * 1024 * 1024, percent: Math.random() * 50 },
          network: { rxBytes: Math.floor(Math.random() * 1000000), txBytes: Math.floor(Math.random() * 1000000) },
          timestamp: new Date().toISOString()
        };
      }
      
      if (!this.docker) {
        throw new Error('Docker client not initialized');
      }
      
      const container = this.docker.getContainer(id);
      
      // Récupérer les stats sans stream
      const statsData = await container.stats({ stream: false });
      
      // Le résultat est déjà un objet JSON, pas besoin de parser
      let stats = statsData as any;
      
      // Calculer le pourcentage CPU
      let cpuUsage = 0;
      if (stats.cpu_stats && stats.precpu_stats && stats.cpu_stats.cpu_usage && stats.precpu_stats.cpu_usage) {
        const cpuDelta = stats.cpu_stats.cpu_usage.total_usage - (stats.precpu_stats.cpu_usage.total_usage || 0);
        const systemDelta = stats.cpu_stats.system_cpu_usage - (stats.precpu_stats.system_cpu_usage || 0);
        
        if (systemDelta > 0 && cpuDelta > 0) {
          const numCpus = stats.cpu_stats.cpu_usage.percpu_usage?.length || 1;
          cpuUsage = (cpuDelta / systemDelta) * numCpus * 100;
        }
      }

      // Calculer l'usage mémoire
      const memoryUsage = stats.memory_stats?.usage || 0;
      const memoryLimit = stats.memory_stats?.limit || 0;
      const memoryPercent = memoryLimit > 0 ? (memoryUsage / memoryLimit) * 100 : 0;

      // Calculer les I/O réseau
      let networkRx = 0;
      let networkTx = 0;
      
      if (stats.networks) {
        for (const [, networkData] of Object.entries(stats.networks) as [string, any][]) {
          networkRx += networkData.rx_bytes || 0;
          networkTx += networkData.tx_bytes || 0;
        }
      }

      return {
        containerId: id,
        cpu: {
          usage: Math.round(Math.max(0, cpuUsage) * 100) / 100
        },
        memory: {
          usage: memoryUsage,
          limit: memoryLimit,
          percent: Math.round(memoryPercent * 100) / 100
        },
        network: {
          rxBytes: networkRx,
          txBytes: networkTx
        },
        timestamp: new Date().toISOString()
      };
    } catch (error: any) {
      logger.error(`Failed to get stats for container ${id}:`, error);
      // Retourner des stats par défaut en cas d'erreur
      return {
        containerId: id,
        cpu: { usage: 0 },
        memory: { usage: 0, limit: 0, percent: 0 },
        network: { rxBytes: 0, txBytes: 0 },
        timestamp: new Date().toISOString()
      };
    }
  }

  async streamContainerLogs(id: string, callback: (data: string) => void): Promise<void> {
    try {
      // In Azure, simulate log streaming with periodic updates
      if (this.isAzureEnvironment) {
        const logs = await azureContainerService.getContainerLogs(id);
        callback(logs);
        return;
      }
      
      if (!this.docker) {
        throw new Error('Docker client not initialized');
      }
      
      const container = this.docker.getContainer(id);
      const stream = await container.logs({
        stdout: true,
        stderr: true,
        follow: true,
        timestamps: true
      });

      stream.on('data', (chunk: any) => {
        callback(chunk.toString());
      });

      stream.on('error', (error: any) => {
        logger.error(`Log stream error for container ${id}:`, error);
      });
    } catch (error: any) {
      logger.error(`Failed to stream logs for container ${id}:`, error);
      throw new Error(`Failed to stream container logs: ${error.message || 'Unknown error'}`);
    }
  }

  // Méthode pour générer des URLs uniques par client
  generateClientUrl(clientId: string, serviceName: string, port: number): string {
    const baseUrl = process.env.BASE_URL || 'localhost';
    return `http://${clientId}-${serviceName}.${baseUrl}:${port}`;
  }

  // Créer un service prédéfini pour un client avec gestion Docker réelle
  async createPredefinedService(clientId: string, serviceType: 'nginx' | 'nodejs' | 'python' | 'database'): Promise<{ containerId: string; url: string; port: number }> {
    const timestamp = Date.now();
    const serviceConfigs = {
      nginx: {
        image: 'nginx:alpine', 
        name: `nginx-${clientId}-${timestamp}`,
        cmd: ['nginx', '-g', 'daemon off;'],
        ports: [{ containerPort: 80, hostPort: 0, protocol: 'tcp' as const }],
        environment: { 
          CLIENT_ID: clientId,
          SERVICE_TYPE: 'nginx',
          NGINX_HOST: `${clientId}-web.localhost`
        }
      },
      nodejs: {
        image: 'nginx:alpine',
        name: `nodejs-${clientId}-${timestamp}`,
        cmd: ['sh', '-c', 'echo "<h1>Node.js Service for client ${CLIENT_ID}</h1><p>Service: nodejs</p><p>Status: Running</p>" > /usr/share/nginx/html/index.html && nginx -g "daemon off;"'],
        ports: [{ containerPort: 80, hostPort: 0, protocol: 'tcp' as const }],
        environment: { 
          CLIENT_ID: clientId,
          SERVICE_TYPE: 'nodejs',
          NGINX_HOST: `${clientId}-nodejs.localhost`
        }
      },
      python: {
        image: 'nginx:alpine',
        name: `python-${clientId}-${timestamp}`,
        cmd: ['sh', '-c', 'echo "<h1>Python Service for client ${CLIENT_ID}</h1><p>Service: python</p><p>Status: Running</p>" > /usr/share/nginx/html/index.html && nginx -g "daemon off;"'],
        ports: [{ containerPort: 80, hostPort: 0, protocol: 'tcp' as const }],
        environment: { 
          CLIENT_ID: clientId,
          SERVICE_TYPE: 'python',
          NGINX_HOST: `${clientId}-python.localhost`
        }
      },
      database: {
        image: 'nginx:alpine',
        name: `database-${clientId}-${timestamp}`, 
        cmd: ['sh', '-c', 'echo "<h1>Database Service for client ${CLIENT_ID}</h1><p>Service: database</p><p>Status: Running</p><p>Type: PostgreSQL Compatible</p>" > /usr/share/nginx/html/index.html && nginx -g "daemon off;"'],
        ports: [{ containerPort: 80, hostPort: 0, protocol: 'tcp' as const }],
        environment: { 
          CLIENT_ID: clientId,
          SERVICE_TYPE: 'database',
          NGINX_HOST: `${clientId}-database.localhost`
        }
      }
    };

    const config = serviceConfigs[serviceType];
    
    if (!config) {
      throw new Error(`Service type '${serviceType}' not supported. Available types: ${Object.keys(serviceConfigs).join(', ')}`);
    }
    
    logger.info(`Creating ${serviceType} service config: ${JSON.stringify(config, null, 2)}`);
    
    // Créer le container
    const containerId = await this.createContainer({
      name: config.name,
      image: config.image,
      cmd: config.cmd,
      ports: config.ports,
      environment: config.environment,
      clientId,
      serviceType,
      labels: { 
        serviceType,
        client: clientId,
        'container-manager.managed': 'true'
      }
    });

    // Démarrer le container (seulement en mode local Docker)
    // En Azure, le container est déjà démarré par createContainer
    if (!this.isAzureEnvironment) {
      await this.startContainer(containerId);
    }
    
    // Générer l'URL et port selon l'environnement
    let mappedPort: number;
    let url: string;
    
    if (this.isAzureEnvironment) {
      // En Azure, pas de port mappé, utilisation de l'URL Azure Container Apps
      mappedPort = 443; // HTTPS par défaut pour Azure
      url = `https://app-${config.name.replace(/[^a-z0-9-]/g, '-').toLowerCase()}.${process.env.AZURE_RESOURCE_GROUP_REGION || 'francecentral'}.azurecontainerapps.io`;
    } else {
      // En local Docker, récupérer le port mappé réellement
      mappedPort = 8000 + Math.floor(Math.random() * 1000);
      if (this.docker) {
        const containers = await this.docker.listContainers();
        const containerInfo = containers.find((c: any) => c.Id.startsWith(containerId));
        mappedPort = containerInfo?.Ports?.find((p: any) => p.PrivatePort === 80)?.PublicPort || mappedPort;
      }
      url = `http://${clientId}-${serviceType}.localhost:${mappedPort}`;
    }

    logger.info(`Service ${serviceType} créé pour client ${clientId}: ${url}`);

    return { containerId, url, port: mappedPort };
  }

  // Obtenir les containers avec informations complètes
  async getContainerDetails(id: string): Promise<any> {
    try {
      // In Azure, return basic container info from our service
      if (this.isAzureEnvironment) {
        // Get container from Azure service (simplified)
        return {
          id: id,
          name: `container-${id}`,
          image: 'unknown',
          status: 'running',
          created: new Date().toISOString(),
          ports: {},
          environment: [],
          labels: { azure: 'true' }
        };
      }
      
      if (!this.docker) {
        throw new Error('Docker client not initialized');
      }
      
      const container = this.docker.getContainer(id);
      const info = await container.inspect();
      
      return {
        id: info.Id,
        name: info.Name.substring(1), // Remove leading slash
        image: info.Config.Image,
        status: info.State.Status,
        created: info.Created,
        ports: info.NetworkSettings.Ports,
        environment: info.Config.Env,
        labels: info.Config.Labels || {}
      };
    } catch (error: any) {
      logger.error(`Failed to get container details ${id}:`, error);
      throw new Error(`Failed to get container details: ${error.message || 'Unknown error'}`);
    }
  }

  async cleanupTestContainers(): Promise<void> {
    try {
      if (this.isAzureEnvironment) {
        // Dans l'environnement Azure, déléguer au service Azure
        return await azureContainerService.cleanupTestContainers();
      } else {
        // Dans l'environnement local, nettoyer les containers Docker locaux
        // Pour l'instant, juste retourner sans erreur
        logger.info('Local cleanup not implemented yet');
        return;
      }
    } catch (error: any) {
      logger.error('Failed to cleanup test containers:', error);
      throw new Error(`Failed to cleanup test containers: ${error.message || 'Unknown error'}`);
    }
  }
}

export const dockerService = new DockerService();