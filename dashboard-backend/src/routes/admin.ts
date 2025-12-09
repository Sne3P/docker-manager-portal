/**
 * Admin Routes for Container Management Platform
 * 
 * Provides admin-only endpoints for:
 * - Client management and overview
 * - System-wide container monitoring
 * - Platform statistics and health
 * 
 * @author Container Platform Team
 * @version 1.0.0
 */

import express, { Response } from 'express';
import { AuthRequest, authenticate, authorize } from '../middleware/auth';
import { logger } from '../utils/logger';
import ClientService from '../services/clientService';
import { dockerService } from '../services/dockerService';

const router = express.Router();
const clientService = new ClientService();


// Apply authentication to all admin routes
router.use(authenticate);
router.use(authorize(['admin']));

/**
 * GET /api/admin/clients
 * 
 * Get all clients in the system (admin only)
 * Returns client information without sensitive data
 */
router.get('/clients', async (req: AuthRequest, res: Response) => {
  try {
    // Récupérer les vrais utilisateurs clients depuis la BDD
    const db = clientService['db']; // Accéder à l'instance DatabaseService
    const realClients = await db.findMany('users', { role: 'client' });
    
    // Pour chaque client, compter ses conteneurs
    const clientsWithStats = await Promise.all(realClients.map(async (client: any) => {
      const clientId = client.email.split('@')[0]; // client1, client2, client3
      const clientContainers = await clientService.getAllEnrichedClients(clientId);
      
      const runningContainers = clientContainers.filter(c => c.status === 'active').length;
      const totalContainers = clientContainers.length;
      
      return {
        id: client.id,
        name: clientId,
        email: client.email,
        createdAt: client.created_at,
        lastLogin: client.last_login,
        isActive: client.is_active,
        containerQuota: 10,
        totalContainers: totalContainers,
        runningContainers: runningContainers,
        stoppedContainers: totalContainers - runningContainers,
        role: client.role
      };
    }));

    logger.info(`Admin ${req.user?.email} retrieved ${clientsWithStats.length} real clients`);
    
    res.json({
      success: true,
      data: clientsWithStats
    });
  } catch (error) {
    logger.error('Admin get clients error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve clients'
    });
  }
});

/**
 * GET /api/admin/containers
 * 
 * Get all containers across all clients (admin only)
 */
router.get('/containers', async (req: AuthRequest, res: Response) => {
  try {
    // Récupérer tous les containers Docker avec métriques
    const allContainers = await dockerService.listContainers(undefined, true);
    
    // Filtrer les containers système
    const systemContainerNames = [
      'container-manager-backend', 
      'container-manager-frontend', 
      'container-manager-nginx', 
      'container-manager-postgres'
    ];
    
    const adminContainers = allContainers
      .filter(container => !systemContainerNames.includes(container.name))
      .map(container => ({
        id: container.id,
        name: container.name,
        clientId: container.clientId,
        serviceType: container.serviceType,
        status: container.status,
        image: container.image,
        ports: container.ports,
        createdAt: container.created,
        url: container.url,
        description: `Container ${container.name}`,
        networks: container.networks,
        metrics: container.metrics
      }));

    logger.info(`Admin ${req.user?.email} retrieved ${adminContainers.length} containers`);
    
    res.json({
      success: true,
      data: adminContainers
    });
  } catch (error) {
    logger.error('Admin get containers error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve containers'
    });
  }
});

/**
 * GET /api/admin/stats
 * 
 * Get platform statistics (admin only)
 */
router.get('/stats', async (req: AuthRequest, res: Response) => {
  try {
    const stats = {
      totalClients: 2,
      activeClients: 2,
      totalContainers: 3,
      runningContainers: 2,
      stoppedContainers: 1,
      systemLoad: {
        cpu: 25.5,
        memory: 68.3,
        disk: 45.2
      },
      recentActivity: [
        {
          id: '1',
          action: 'container_created',
          resource: 'client1-nginx-web',
          userId: 'client-1',
          timestamp: new Date().toISOString(),
          details: { serviceType: 'web' }
        },
        {
          id: '2',
          action: 'user_login',
          resource: 'admin',
          userId: 'admin-1',
          timestamp: new Date(Date.now() - 300000).toISOString()
        }
      ]
    };

    logger.info(`Admin ${req.user?.email} retrieved platform stats`);
    
    res.json({
      success: true,
      data: stats
    });
  } catch (error) {
    logger.error('Admin get stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve platform statistics'
    });
  }
});

/**
 * POST /api/admin/containers/:id/action
 * 
 * Perform action on any container (admin only)
 */
router.post('/containers/:id/:action', async (req: AuthRequest, res: Response) => {
  try {
    const { id, action } = req.params;
    
    // Validate action
    const validActions = ['start', 'stop', 'restart', 'remove'];
    if (!validActions.includes(action)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid action'
      });
    }

    // Perform the actual Docker action avec logging en BDD
    try {
      const userId = (req.user as any)?.userId || 1;
      let success = false;

      switch (action) {
        case 'start':
          success = await clientService.startContainer(id, userId);
          break;
        case 'stop':
          success = await clientService.stopContainer(id, userId);
          break;
        case 'restart':
          // Pour restart, on fait stop puis start
          await clientService.stopContainer(id, userId);
          success = await clientService.startContainer(id, userId);
          break;
        case 'remove':
          success = await clientService.removeContainer(id, userId);
          break;
      }

      if (!success) {
        return res.status(500).json({
          success: false,
          message: `Failed to ${action} container`
        });
      }
    } catch (dockerError: any) {
      logger.error(`Docker ${action} failed for container ${id}:`, dockerError);
      return res.status(500).json({
        success: false,
        message: `Failed to ${action} container: ${dockerError.message}`
      });
    }

    logger.info(`Admin ${req.user?.email} performed ${action} on container ${id}`);
    
    res.json({
      success: true,
      message: `Container ${action} successful`,
      data: { containerId: id, action }
    });
  } catch (error) {
    logger.error('Admin container action error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to perform container action'
    });
  }
});

export default router;