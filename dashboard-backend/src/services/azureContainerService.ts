import { Container, ContainerStats, CreateContainerRequest } from '../types';
import { logger } from '../utils/logger';

// Simplified Azure Container Service for MVP - Simulation Mode
class AzureContainerService {
  private containers: Map<string, Container> = new Map();

  constructor() {
    logger.info('Azure Container Service initialized (simulation mode)');
  }

  async listContainers(clientId?: string, includeMetrics: boolean = false): Promise<Container[]> {
    try {
      logger.info(`Listing containers for client: ${clientId} (simulation mode)`);
      
      const containers: Container[] = [];
      
      // Return stored containers
      for (const [id, containerData] of this.containers.entries()) {
        if (clientId && containerData.clientId !== clientId) {
          continue;
        }
        containers.push(containerData);
      }

      // If no containers exist, create some demo containers for the client
      if (containers.length === 0 && clientId) {
        const demoContainers = this.createDemoContainers(clientId);
        for (const container of demoContainers) {
          this.containers.set(container.id, container);
          containers.push(container);
        }
      }

      logger.info(`Found ${containers.length} containers (simulation)`);
      return containers;
    } catch (error: any) {
      logger.error('Error listing containers:', error);
      throw new Error(`Failed to list containers: ${error.message}`);
    }
  }

  async createContainer(request: CreateContainerRequest, clientId: string): Promise<Container> {
    try {
      logger.info(`Creating container for client ${clientId}:`, request);

      const containerId = `${clientId}-${Date.now()}`;
      const container: Container = {
        id: containerId,
        name: request.name,
        image: request.image,
        status: 'running',
        created: new Date().toISOString(),
        clientId: clientId,
        serviceType: request.serviceType || 'custom',
        url: `https://${request.name}.azurecontainerapps.io`,
        labels: { createdBy: 'portail-cloud' },
        ports: request.ports || [{ containerPort: 80, hostPort: 80, protocol: 'tcp' }],
        networks: ['default']
      };

      this.containers.set(containerId, container);
      logger.info(`Container created: ${containerId}`);

      return container;
    } catch (error: any) {
      logger.error('Error creating container:', error);
      throw new Error(`Failed to create container: ${error.message}`);
    }
  }

  async startContainer(containerId: string): Promise<void> {
    try {
      logger.info(`Starting container: ${containerId}`);
      const container = this.containers.get(containerId);
      if (container) {
        container.status = 'running';
        this.containers.set(containerId, container);
      }
      logger.info(`Container started: ${containerId}`);
    } catch (error: any) {
      logger.error('Error starting container:', error);
      throw new Error(`Failed to start container: ${error.message}`);
    }
  }

  async stopContainer(containerId: string): Promise<void> {
    try {
      logger.info(`Stopping container: ${containerId}`);
      const container = this.containers.get(containerId);
      if (container) {
        container.status = 'exited';
        this.containers.set(containerId, container);
      }
      logger.info(`Container stopped: ${containerId}`);
    } catch (error: any) {
      logger.error('Error stopping container:', error);
      throw new Error(`Failed to stop container: ${error.message}`);
    }
  }

  async removeContainer(containerId: string): Promise<void> {
    try {
      logger.info(`Deleting container: ${containerId}`);
      this.containers.delete(containerId);
      logger.info(`Container deleted: ${containerId}`);
    } catch (error: any) {
      logger.error('Error deleting container:', error);
      throw new Error(`Failed to delete container: ${error.message}`);
    }
  }

  async getContainerLogs(containerId: string): Promise<string> {
    try {
      return `[SIMULATION] Logs for container ${containerId}:
2024-12-10 22:00:00 Container started
2024-12-10 22:00:01 Application ready
2024-12-10 22:00:02 Listening on port 80`;
    } catch (error: any) {
      logger.error('Error getting container logs:', error);
      throw new Error(`Failed to get logs: ${error.message}`);
    }
  }

  private createDemoContainers(clientId: string): Container[] {
    return [
      {
        id: `demo-nginx-${clientId}`,
        name: `nginx-${clientId}`,
        image: 'nginx:latest',
        status: 'running',
        created: new Date().toISOString(),
        clientId: clientId,
        serviceType: 'nginx',
        url: `https://demo-nginx-${clientId}.azurecontainerapps.io`,
        labels: { demo: 'true', type: 'webserver' },
        ports: [{ containerPort: 80, hostPort: 80, protocol: 'tcp' }],
        networks: ['default']
      },
      {
        id: `demo-app-${clientId}`,
        name: `nodejs-app-${clientId}`,
        image: 'node:18-alpine',
        status: 'exited',
        created: new Date(Date.now() - 3600000).toISOString(),
        clientId: clientId,
        serviceType: 'nodejs',
        url: '',
        labels: { demo: 'true', type: 'application' },
        ports: [{ containerPort: 3000, hostPort: 3000, protocol: 'tcp' }],
        networks: ['default']
      }
    ];
  }
}

export const azureContainerService = new AzureContainerService();
