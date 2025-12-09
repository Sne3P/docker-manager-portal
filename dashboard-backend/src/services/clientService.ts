import DatabaseService from './databaseService';
import { dockerService } from './dockerService';
import { Client } from '../types/database';

class ClientService {
  private db: DatabaseService;

  constructor() {
    this.db = DatabaseService.getInstance();
  }

  /**
   * Retourne les vrais containers Docker avec métadonnées BDD
   */
  async getAllEnrichedClients(clientId?: string): Promise<any[]> {
    try {
      // Récupérer les vrais containers Docker (filtrer par clientId si spécifié)
      const dockerContainers = await dockerService.listContainers(clientId);
      
      // Récupérer les métadonnées depuis la BDD si disponible
      let dbClients: any[] = [];
      try {
        dbClients = await this.db.findMany('clients');
      } catch (dbError) {
        console.warn('Database not available, using only Docker data:', dbError);
      }

      // Fusionner Docker containers avec métadonnées BDD
      return dockerContainers.map(container => {
        const dbClient = dbClients.find(client => 
          client.name === container.name || 
          client.docker_container_id === container.id
        );
        
        return {
          id: container.id,
          name: container.name,
          status: container.status === 'running' ? 'active' : 'inactive',
          docker_status: container.status,
          docker_image: container.image,
          created_at: container.created ? new Date(container.created) : new Date(),
          description: dbClient?.description || `Container ${container.name}`,
          docker_container_id: container.id,
          port_mappings: this.formatPortMappings(container.ports),
          environment_vars: dbClient?.environment_vars || {},
          resource_limits: dbClient?.resource_limits || {},
          created_by: dbClient?.created_by || 1,
          updated_at: dbClient?.updated_at || new Date(),
          docker_ports: container.ports,
          docker_networks: container.networks,
          clientId: container.clientId,
          serviceType: container.serviceType,
          url: container.url,
          labels: container.labels
        };
      });

    } catch (error) {
      console.error('Error getting enriched clients:', error);
      // En cas d'erreur Docker, retourner une liste vide
      return [];
    }
  }

  /**
   * Formater les ports pour compatibilité avec l'interface existante
   */
  private formatPortMappings(ports: any[]): any {
    const mappings: any = {};
    ports.forEach(port => {
      if (port.hostPort) {
        mappings[`${port.containerPort}/${port.protocol}`] = port.hostPort;
      }
    });
    return mappings;
  }

  /**
   * Actions réelles sur les containers Docker avec logging BDD
   */
  async startContainer(containerId: string, userId: number): Promise<boolean> {
    try {
      console.log(`Starting container ${containerId} by user ${userId}`);
      
      // Vraie action Docker
      await dockerService.startContainer(containerId);
      
      // Log l'activité en BDD si disponible
      try {
        await this.db.logActivity(userId, null, 'start', { container_id: containerId });
      } catch (dbError) {
        console.warn('Could not log to database:', dbError);
      }

      return true;
    } catch (error) {
      console.error('Start container error:', error);
      return false;
    }
  }

  async stopContainer(containerId: string, userId: number): Promise<boolean> {
    try {
      console.log(`Stopping container ${containerId} by user ${userId}`);
      
      // Vraie action Docker  
      await dockerService.stopContainer(containerId);
      
      // Log l'activité en BDD si disponible  
      try {
        await this.db.logActivity(userId, null, 'stop', { container_id: containerId });
      } catch (dbError) {
        console.warn('Could not log to database:', dbError);
      }

      return true;
    } catch (error) {
      console.error('Stop container error:', error);
      return false;
    }
  }

  async removeContainer(containerId: string, userId: number): Promise<boolean> {
    try {
      console.log(`Removing container ${containerId} by user ${userId}`);
      
      // Vraie action Docker
      await dockerService.removeContainer(containerId);
      
      // Log l'activité en BDD si disponible
      try {
        await this.db.logActivity(userId, null, 'delete', { container_id: containerId });
      } catch (dbError) {
        console.warn('Could not log to database:', dbError);
      }

      return true;
    } catch (error) {
      console.error('Remove container error:', error);
      return false;
    }
  }

  /**
   * Gestion des clients en BDD
   */
  async createClient(clientData: Partial<Client>, userId: number): Promise<Client | null> {
    try {
      const newClient = await this.db.insert('clients', {
        ...clientData,
        created_by: userId,
        status: 'inactive'
      });

      await this.db.logActivity(userId, newClient.id, 'create', clientData);
      return newClient;
    } catch (error) {
      console.error('Create client error:', error);
      return null;
    }
  }

  async updateClient(clientId: number, updates: Partial<Client>, userId: number): Promise<Client | null> {
    try {
      const updatedClient = await this.db.update('clients', clientId, updates);
      
      if (updatedClient) {
        await this.db.logActivity(userId, clientId, 'update', updates);
      }

      return updatedClient;
    } catch (error) {
      console.error('Update client error:', error);
      return null;
    }
  }

  async getClientActivityLogs(clientId: number, limit: number = 50): Promise<any[]> {
    try {
      return await this.db.findMany('activity_logs', { client_id: clientId }, limit);
    } catch (error) {
      console.error('Get activity logs error:', error);
      return [];
    }
  }
}

export default ClientService;