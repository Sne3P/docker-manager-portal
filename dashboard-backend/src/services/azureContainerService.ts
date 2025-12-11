import { Container, ContainerStats, CreateContainerRequest } from '../types';
import { logger } from '../utils/logger';
import DatabaseService from './databaseService';
import { exec } from 'child_process';
import { promisify } from 'util';

const databaseService = DatabaseService.getInstance();
const execAsync = promisify(exec);

// Real Azure Container Apps Service - Full Azure CLI Integration
class AzureContainerService {
  private resourceGroup: string;
  private environment: string;
  private registryServer: string;
  private registryUsername: string;
  private registryPassword: string;
  private subscription: string;

  constructor() {
    // Configuration Azure basée sur les variables d'environnement
    this.resourceGroup = process.env.AZURE_RESOURCE_GROUP || 'rg-container-manager-bastienr';
    this.environment = process.env.AZURE_CONTAINER_ENVIRONMENT || 'env-bastienr';
    this.registryServer = process.env.AZURE_CONTAINER_REGISTRY || 'acrbastienr.azurecr.io';
    this.registryUsername = process.env.AZURE_CONTAINER_REGISTRY_USERNAME || 'acrbastienr';
    this.registryPassword = process.env.AZURE_CONTAINER_REGISTRY_PASSWORD || '';
    this.subscription = process.env.AZURE_SUBSCRIPTION_ID || '6df1bf9f-c8e8-4c71-aeb6-7d691adf418b';
    
    logger.info(`Azure Container Service initialized - RG: ${this.resourceGroup}, Env: ${this.environment}`);
    this.initializeDatabase();
    this.ensureAzureCLI();
  }

  private async ensureAzureCLI(): Promise<void> {
    try {
      // Vérifier que Azure CLI est installé
      await this.runAzureCommand('az --version');
      logger.info('Azure CLI is available');
      
      // Authentification via Managed Service Identity si dans Azure
      if (process.env.AZURE_USE_MSI === 'true') {
        logger.info('Authenticating with Managed Service Identity...');
        await this.runAzureCommand('az login --identity');
      }
      
      // Se connecter au subscription spécifique
      await this.runAzureCommand(`az account set --subscription ${this.subscription}`);
      logger.info(`Azure subscription set to: ${this.subscription}`);
      
      // Vérifier que le Container Apps extension est installé
      try {
        await this.runAzureCommand('az containerapp --version');
      } catch (error) {
        logger.info('Installing Azure Container Apps extension...');
        await this.runAzureCommand('az extension add --name containerapp --upgrade');
      }
      
    } catch (error: any) {
      logger.error('Azure CLI setup failed:', error.message);
      throw new Error('Azure CLI is required but not properly configured');
    }
  }

  private async runAzureCommand(command: string): Promise<string> {
    try {
      logger.debug(`Executing: ${command}`);
      const { stdout, stderr } = await execAsync(command);
      if (stderr && !stderr.includes('WARNING')) {
        logger.warn(`Azure CLI stderr: ${stderr}`);
      }
      return stdout.trim();
    } catch (error: any) {
      logger.error(`Azure CLI command failed: ${command}`, error);
      throw new Error(`Azure CLI error: ${error.message}`);
    }
  }

  private async initializeDatabase(): Promise<void> {
    try {
      // Créer la table containers si elle n'existe pas
      await databaseService.query(`
        CREATE TABLE IF NOT EXISTS user_containers (
          id SERIAL PRIMARY KEY,
          container_id VARCHAR(255) UNIQUE NOT NULL,
          name VARCHAR(255) NOT NULL,
          image VARCHAR(255) NOT NULL,
          status VARCHAR(50) NOT NULL DEFAULT 'creating',
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          client_id VARCHAR(255) NOT NULL,
          service_type VARCHAR(100) DEFAULT 'custom',
          url TEXT,
          azure_app_name VARCHAR(255),
          labels JSONB DEFAULT '{}',
          environment JSONB DEFAULT '{}',
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      `);

      // Index pour optimiser les requêtes
      await databaseService.query('CREATE INDEX IF NOT EXISTS idx_user_containers_client_id ON user_containers(client_id)');
      await databaseService.query('CREATE INDEX IF NOT EXISTS idx_user_containers_status ON user_containers(status)');
      await databaseService.query('CREATE INDEX IF NOT EXISTS idx_user_containers_azure_app_name ON user_containers(azure_app_name)');

      logger.info('Azure Container Service database tables initialized');
    } catch (error: any) {
      logger.error('Error initializing container database tables:', error);
    }
  }

  async listContainers(clientId?: string, includeMetrics: boolean = false): Promise<Container[]> {
    try {
      logger.info(`Listing containers for client: ${clientId}`);
      
      let query = 'SELECT * FROM user_containers';
      let params: any[] = [];
      
      if (clientId) {
        query += ' WHERE client_id = $1';
        params.push(clientId);
      }
      
      query += ' ORDER BY created_at DESC';
      
      const result = await databaseService.query(query, params);
      
      const containers: Container[] = result.rows.map((row: any) => ({
        id: row.container_id,
        name: row.name,
        image: row.image,
        status: row.status as any,
        created: row.created_at.toISOString(),
        clientId: row.client_id,
        serviceType: row.service_type,
        url: row.url || '',
        labels: row.labels || {},
        ports: this.getPortsFromServiceType(row.service_type),
        networks: ['default']
      }));

      // Si aucun container n'existe pour ce client, créer des containers de démo
      if (containers.length === 0 && clientId) {
        const demoContainers = await this.createDemoContainers(clientId);
        containers.push(...demoContainers);
      }

      logger.info(`Found ${containers.length} containers for client ${clientId}`);
      return containers;
    } catch (error: any) {
      logger.error('Error listing containers:', error);
      throw new Error(`Failed to list containers: ${error.message}`);
    }
  }

  async createContainer(request: CreateContainerRequest, clientId: string): Promise<Container> {
    try {
      logger.info(`Creating real Azure Container App for client ${clientId}:`, request);

      // Générer un nom court et valide pour Azure Container Apps (max 32 caractères)
      const timestamp = Date.now().toString(36);
      const serviceType = request.serviceType || 'app';
      // Exemple: nginx-cl1-mj1ccm9m (max 20 chars pour être sûr)
      const containerId = `${serviceType}-${clientId}-${timestamp}`;
      const azureAppName = containerId.toLowerCase()
        .replace(/[^a-z0-9-]/g, '-')
        .replace(/^-+|-+$/g, '') // Supprimer tirets début/fin
        .replace(/-+/g, '-')     // Pas de tirets multiples
        .substring(0, 31);       // Max 31 chars (sécurité)
      
      // Déterminer l'image correcte à utiliser selon le service type
      const correctImage = this.getImageForServiceType(request.serviceType, request.image);

      // Insérer le nouveau container dans la base avec status "creating"
      const result = await databaseService.query(`
        INSERT INTO user_containers (
          container_id, name, image, status, client_id, service_type, azure_app_name, labels, environment
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        RETURNING *
      `, [
        containerId,
        request.name,
        correctImage,
        'creating',
        clientId,
        request.serviceType || 'custom',
        azureAppName,
        JSON.stringify(request.labels || {}),
        JSON.stringify(request.environment || {})
      ]);

      const row = result.rows[0];

      // Créer le vrai Azure Container App en arrière-plan
      this.deployRealAzureContainer(row).catch((error: any) => {
        logger.error(`Failed to deploy Azure Container App ${azureAppName}:`, error);
        // Marquer comme échoué
        databaseService.query(
          'UPDATE user_containers SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE container_id = $2',
          ['exited', containerId]
        );
      });

      const container: Container = {
        id: row.container_id,
        name: row.name,
        image: row.image,
        status: 'created', // Statut initial valide
        created: row.created_at.toISOString(),
        clientId: row.client_id,
        serviceType: row.service_type,
        url: '', // URL sera mise à jour après déploiement
        labels: row.labels || {},
        ports: request.ports || this.getPortsFromServiceType(request.serviceType),
        networks: ['azure-container-environment']
      };

      logger.info(`Container creation initiated: ${container.name}`);
      return container;
    } catch (error: any) {
      logger.error('Error creating container:', error);
      throw new Error(`Failed to create container: ${error.message}`);
    }
  }

  private async deployRealAzureContainer(containerData: any): Promise<void> {
    const azureAppName = containerData.azure_app_name;
    const containerId = containerData.container_id;
    
    try {
      logger.info(`Deploying real Azure Container App: ${azureAppName}`);
      
      // Étape 1: Créer le manifeste YAML pour le Container App
      const manifest = this.generateContainerAppManifest(containerData);
      
      // Étape 2: Déployer via Azure CLI
      const deployCommand = `az containerapp create \\
        --name ${azureAppName} \\
        --resource-group ${this.resourceGroup} \\
        --environment ${this.environment} \\
        --image ${containerData.image} \\
        --target-port ${this.getTargetPort(containerData.service_type)} \\
        --ingress external \\
        --registry-server ${this.registryServer} \\
        --registry-username ${this.registryUsername} \\
        --registry-password ${this.registryPassword} \\
        --cpu 0.25 --memory 0.5Gi \\
        --min-replicas 0 --max-replicas 1 \\
        --env-vars ${this.buildEnvVars(containerData.environment)} \\
        --output table`;

      await this.runAzureCommand(deployCommand);
      
      // Étape 3: Récupérer l'URL du Container App déployé
      const urlCommand = `az containerapp show --name ${azureAppName} --resource-group ${this.resourceGroup} --query "properties.configuration.ingress.fqdn" -o tsv`;
      const fqdn = await this.runAzureCommand(urlCommand);
      const url = `https://${fqdn}`;
      
      // Étape 4: Mettre à jour la base de données avec l'URL réelle et le statut
      await databaseService.query(
        'UPDATE user_containers SET status = $1, url = $2, updated_at = CURRENT_TIMESTAMP WHERE container_id = $3',
        ['running', url, containerId]
      );
      
      logger.info(`Azure Container App deployed successfully: ${azureAppName} -> ${url}`);
      
    } catch (error: any) {
      logger.error(`Failed to deploy Azure Container App ${azureAppName}:`, error);
      await databaseService.query(
        'UPDATE user_containers SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE container_id = $2',
        ['exited', containerId]
      );
      throw error;
    }
  }

  async startContainer(containerId: string): Promise<void> {
    try {
      logger.info(`Starting container (${this.isLocalMode() ? 'LOCAL' : 'AZURE'} mode): ${containerId}`);
      
      // Marquer comme "starting" pour le feedback UX
      await databaseService.query(
        'UPDATE user_containers SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE container_id = $2',
        ['starting', containerId]
      );

      if (this.isLocalMode()) {
        // Mode local : simulation immediate
        await databaseService.query(
          'UPDATE user_containers SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE container_id = $2',
          ['running', containerId]
        );
        logger.info(`Container ${containerId} started successfully (local mode)`);
        return;
      }
      
      const result = await databaseService.query('SELECT azure_app_name, service_type FROM user_containers WHERE container_id = $1', [containerId]);
      if (result.rows.length === 0) {
        throw new Error('Container not found');
      }
      
      const azureAppName = result.rows[0].azure_app_name;
      const serviceType = result.rows[0].service_type;
      const targetPort = this.getTargetPort(serviceType);
      
      // SIMPLE : Réactiver l'ingress
      await this.runAzureCommand(`az containerapp ingress enable --name ${azureAppName} --resource-group ${this.resourceGroup} --type external --target-port ${targetPort}`);
      
      await databaseService.query(
        'UPDATE user_containers SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE container_id = $2',
        ['running', containerId]
      );
      
      logger.info(`Azure Container App INGRESS ENABLED: ${containerId}`);
    } catch (error: any) {
      logger.error('Error enabling ingress:', error);
      // Marquer comme erreur en cas d'échec
      await databaseService.query(
        'UPDATE user_containers SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE container_id = $2',
        ['error', containerId]
      );
      throw new Error(`Failed to start container: ${error.message}`);
    }
  }

  async stopContainer(containerId: string): Promise<void> {
    try {
      logger.info(`Stopping Azure Container App (INGRESS DISABLE): ${containerId}`);
      
      // Marquer comme "stopping" pour le feedback UX
      await databaseService.query(
        'UPDATE user_containers SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE container_id = $2',
        ['stopping', containerId]
      );
      
      const result = await databaseService.query('SELECT azure_app_name FROM user_containers WHERE container_id = $1', [containerId]);
      if (result.rows.length === 0) {
        throw new Error('Container not found');
      }
      
      const azureAppName = result.rows[0].azure_app_name;
      
      // SIMPLE : Désactiver juste l'ingress (rend l'URL inaccessible)
      await this.runAzureCommand(`az containerapp ingress disable --name ${azureAppName} --resource-group ${this.resourceGroup}`);
      
      await databaseService.query(
        'UPDATE user_containers SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE container_id = $2',
        ['exited', containerId]
      );
      
      logger.info(`Azure Container App INGRESS DISABLED: ${containerId}`);
    } catch (error: any) {
      logger.error('Error disabling ingress:', error);
      // Marquer comme erreur en cas d'échec
      await databaseService.query(
        'UPDATE user_containers SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE container_id = $2',
        ['error', containerId]
      );
      throw new Error(`Failed to stop container: ${error.message}`);
    }
  }

  async cleanupTestContainers(): Promise<void> {
    try {
      logger.info('Cleaning up test/simulation containers...');
      
      // Supprimer tous les containers qui ne sont pas des vrais Azure Container Apps
      // (ceux qui n'ont pas d'azure_app_name ou qui commencent par test/sim)
      const testContainers = await databaseService.query(`
        SELECT container_id, azure_app_name FROM user_containers 
        WHERE azure_app_name IS NULL 
        OR azure_app_name LIKE 'test-%' 
        OR azure_app_name LIKE 'sim-%'
        OR container_id LIKE 'test-%'
        OR container_id LIKE 'sim-%'
      `);
      
      logger.info(`Found ${testContainers.rows.length} test containers to clean up`);
      
      // Supprimer de la base de données
      await databaseService.query(`
        DELETE FROM user_containers 
        WHERE azure_app_name IS NULL 
        OR azure_app_name LIKE 'test-%' 
        OR azure_app_name LIKE 'sim-%'
        OR container_id LIKE 'test-%'
        OR container_id LIKE 'sim-%'
      `);
      
      logger.info('Test containers cleaned up successfully');
    } catch (error: any) {
      logger.error('Error cleaning up test containers:', error);
      throw new Error(`Failed to cleanup test containers: ${error.message}`);
    }
  }

  async removeContainer(containerId: string): Promise<void> {
    try {
      logger.info(`Deleting Azure Container App: ${containerId}`);
      
      const result = await databaseService.query('SELECT azure_app_name FROM user_containers WHERE container_id = $1', [containerId]);
      if (result.rows.length === 0) {
        throw new Error('Container not found');
      }
      
      const azureAppName = result.rows[0].azure_app_name;
      
      // Supprimer le Container App Azure
      await this.runAzureCommand(`az containerapp delete --name ${azureAppName} --resource-group ${this.resourceGroup} --yes`);
      
      // Supprimer de la base de données
      await databaseService.query('DELETE FROM user_containers WHERE container_id = $1', [containerId]);
      
      logger.info(`Azure Container App deleted: ${containerId}`);
    } catch (error: any) {
      logger.error('Error deleting container:', error);
      throw new Error(`Failed to delete container: ${error.message}`);
    }
  }

  async getContainerLogs(containerId: string): Promise<string> {
    try {
      logger.info(`Getting real Azure Container App logs: ${containerId}`);
      
      const result = await databaseService.query('SELECT azure_app_name FROM user_containers WHERE container_id = $1', [containerId]);
      
      if (result.rows.length === 0) {
        return 'Container not found';
      }

      const azureAppName = result.rows[0].azure_app_name;
      
      try {
        // Récupérer les vrais logs Azure Container App
        const logsCommand = `az containerapp logs show --name ${azureAppName} --resource-group ${this.resourceGroup} --tail 100`;
        const logs = await this.runAzureCommand(logsCommand);
        return logs || 'No logs available yet';
      } catch (error) {
        // Fallback si les logs ne sont pas encore disponibles
        return `[AZURE CONTAINER APP] ${azureAppName}
${new Date().toISOString()} Container deployment in progress
${new Date().toISOString()} Logs will be available once the container is fully deployed
${new Date().toISOString()} Status: Check Azure Portal for real-time status`;
      }
    } catch (error: any) {
      logger.error('Error getting container logs:', error);
      return `Error retrieving logs: ${error.message}`;
    }
  }

  private generateContainerAppManifest(containerData: any): string {
    // Génère un manifeste YAML pour Azure Container App (non utilisé dans cette implémentation mais utile pour le debug)
    return JSON.stringify({
      name: containerData.azure_app_name,
      resourceGroup: this.resourceGroup,
      environment: this.environment,
      image: containerData.image,
      serviceType: containerData.service_type,
      targetPort: this.getTargetPort(containerData.service_type)
    }, null, 2);
  }

  private getTargetPort(serviceType?: string): number {
    switch (serviceType) {
      case 'nginx':
      case 'apache':
        return 80;
      case 'nodejs':
        return 3000;
      case 'python':
        return 8000;
      case 'redis':
        return 6379;
      case 'postgres':
      case 'database':
        return 5432;
      default:
        return 80;
    }
  }

  private getImageForServiceType(serviceType?: string, customImage?: string): string {
    // Si une image personnalisée est fournie et que le type est custom, l'utiliser
    if (serviceType === 'custom' && customImage) {
      return customImage;
    }
    
    // Utiliser des images du registry avec nom dynamique basé sur l'environnement
    const registryServer = this.registryServer; // acrbastienr.azurecr.io par exemple
    
    switch (serviceType) {
      case 'nginx':
        return `${registryServer}/nginx-demo:latest`;
      case 'apache':
        return 'httpd:alpine';
      case 'nodejs':
        return `${registryServer}/nodejs-demo:latest`;
      case 'python':
        return `${registryServer}/python-demo:latest`;
      case 'redis':
        return 'redis:alpine';
      case 'postgres':
        return 'postgres:15-alpine';
      case 'database':
        return `${registryServer}/database-demo:latest`;
      default:
        return customImage || `${registryServer}/nginx-demo:latest`; // Fallback sur nginx-demo
    }
  }

  private buildEnvVars(environment: any): string {
    if (!environment || typeof environment !== 'object') {
      return '';
    }
    
    const envVars = Object.entries(environment)
      .map(([key, value]) => `${key}=${value}`)
      .join(' ');
    
    return envVars;
  }

  private getPortsFromServiceType(serviceType?: string): Array<{containerPort: number, hostPort: number, protocol: 'tcp' | 'udp'}> {
    switch (serviceType) {
      case 'nginx':
      case 'apache':
        return [{ containerPort: 80, hostPort: 80, protocol: 'tcp' }];
      case 'nodejs':
        return [{ containerPort: 3000, hostPort: 80, protocol: 'tcp' }];
      case 'redis':
        return [{ containerPort: 6379, hostPort: 6379, protocol: 'tcp' }];
      case 'postgres':
        return [{ containerPort: 5432, hostPort: 5432, protocol: 'tcp' }];
      default:
        return [{ containerPort: 80, hostPort: 80, protocol: 'tcp' }];
    }
  }

  async getContainerStats(containerId: string): Promise<ContainerStats | null> {
    try {
      const result = await databaseService.query('SELECT azure_app_name FROM user_containers WHERE container_id = $1', [containerId]);
      
      if (result.rows.length === 0) {
        return null;
      }

      const azureAppName = result.rows[0].azure_app_name;
      
      try {
        // Récupérer les métriques Azure réelles
        const metricsCommand = `az containerapp show --name ${azureAppName} --resource-group ${this.resourceGroup} --query "properties.template.containers[0]" -o json`;
        const containerInfo = await this.runAzureCommand(metricsCommand);
        const info = JSON.parse(containerInfo);
        
        return {
          containerId: containerId,
          cpu: { usage: 0 }, // Azure Container Apps ne fournit pas de métriques temps réel via CLI
          memory: { usage: 0, limit: 536870912, percent: 0 }, // 512MB limit par défaut
          network: { rxBytes: 0, txBytes: 0 },
          timestamp: new Date().toISOString()
        };
      } catch (error) {
        // Retourner des stats par défaut si la récupération échoue
        return {
          containerId: containerId,
          cpu: { usage: 0 },
          memory: { usage: 0, limit: 536870912, percent: 0 },
          network: { rxBytes: 0, txBytes: 0 },
          timestamp: new Date().toISOString()
        };
      }
    } catch (error: any) {
      logger.error('Error getting container stats:', error);
      return null;
    }
  }

  private async createDemoContainers(clientId: string): Promise<Container[]> {
    const demoConfigs = [
      {
        name: `nginx-${clientId}`,
        image: 'nginx:latest',
        serviceType: 'nginx' as const
      },
      {
        name: `nodejs-app-${clientId}`,
        image: 'node:18-alpine',
        serviceType: 'nodejs' as const
      }
    ];

    const containers: Container[] = [];
    
    for (const config of demoConfigs) {
      try {
        const container = await this.createContainer({
          name: config.name,
          image: config.image,
          clientId: clientId,
          serviceType: config.serviceType,
          environment: {},
          labels: { demo: 'true', type: config.serviceType }
        }, clientId);
        containers.push(container);
      } catch (error) {
        logger.warn(`Failed to create demo container ${config.name}:`, error);
      }
    }

    return containers;
  }
}

export const azureContainerService = new AzureContainerService();