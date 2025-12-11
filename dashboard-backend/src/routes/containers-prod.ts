import express, { Response } from 'express';
import { body, validationResult } from 'express-validator';
import { dockerService } from '../services/dockerService';
import { authenticate, authorize, AuthRequest } from '../middleware/auth';
import { logger } from '../utils/logger';

const router = express.Router();

// Apply authentication to all routes
router.use(authenticate);

// Get current user's containers (clients only)
router.get('/my', async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (req.user?.role !== 'client') {
      res.status(403).json({
        success: false,
        message: 'This endpoint is for clients only'
      });
      return;
    }

    const containers = await dockerService.listContainers(req.user.clientId, true);

    res.json({
      success: true,
      data: containers,
      message: `Found ${containers.length} containers for client ${req.user.clientId}`
    });
  } catch (error: any) {
    logger.error('List my containers error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to list your containers',
      error: error.message
    });
  }
});

// List containers for client or all (admin)
router.get('/', async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const clientId = req.user?.role === 'admin' ? req.query.clientId as string : req.user?.clientId;
    const containers = await dockerService.listContainers(clientId, true);

    res.json({
      success: true,
      data: containers,
      message: `Found ${containers.length} containers`
    });
  } catch (error: any) {
    logger.error('List containers error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to list containers',
      error: error.message
    });
  }
});

// Create predefined service (for clients)
router.post('/predefined', [
  body('serviceType').isIn(['nginx', 'nodejs', 'python', 'database']),
  body('clientId').optional().isLength({ min: 1 })
], async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      res.status(400).json({
        success: false,
        message: 'Validation errors',
        errors: errors.array()
      });
      return;
    }

    // Clients can only create for themselves, admin can specify clientId
    const clientId = req.user?.role === 'admin' ? 
      (req.body.clientId || req.user.clientId) : 
      req.user?.clientId;
    
    if (!clientId) {
      res.status(400).json({
        success: false,
        message: 'Client ID is required'
      });
      return;
    }

    const { serviceType } = req.body;
    const result = await dockerService.createPredefinedService(clientId, serviceType);

    res.status(201).json({
      success: true,
      data: {
        containerId: result.containerId,
        url: result.url,
        port: result.port,
        serviceType,
        clientId
      },
      message: `${serviceType} service created successfully for client ${clientId}`
    });
  } catch (error: any) {
    logger.error('Service creation error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create service',
      error: error.message
    });
  }
});

// Get container details
router.get('/:id', async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const containers = await dockerService.listContainers(req.user?.clientId);
    const container = containers.find((c: any) => c.id === id || c.id.startsWith(id));

    if (!container) {
      res.status(404).json({
        success: false,
        message: 'Container not found'
      });
      return;
    }

    // Check if client owns this container (unless admin)
    if (req.user?.role !== 'admin' && container.clientId !== req.user?.clientId) {
      res.status(403).json({
        success: false,
        message: 'Access denied to this container'
      });
      return;
    }

    const details = await dockerService.getContainerDetails(container.id);
    
    res.json({
      success: true,
      data: details
    });
  } catch (error: any) {
    logger.error('Get container error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get container details',
      error: error.message
    });
  }
});

// Start container
router.post('/:id/start', async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const containers = await dockerService.listContainers(req.user?.clientId);
    const container = containers.find((c: any) => c.id === id || c.id.startsWith(id));

    if (!container) {
      res.status(404).json({
        success: false,
        message: 'Container not found'
      });
      return;
    }

    // Check permissions
    if (req.user?.role !== 'admin' && container.clientId !== req.user?.clientId) {
      res.status(403).json({
        success: false,
        message: 'Access denied to this container'
      });
      return;
    }

    await dockerService.startContainer(container.id);
    
    res.json({
      success: true,
      message: `Container ${container.name} started successfully`
    });
  } catch (error: any) {
    logger.error('Start container error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to start container',
      error: error.message
    });
  }
});

// Stop container
router.post('/:id/stop', async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const containers = await dockerService.listContainers(req.user?.clientId);
    const container = containers.find((c: any) => c.id === id || c.id.startsWith(id));

    if (!container) {
      res.status(404).json({
        success: false,
        message: 'Container not found'
      });
      return;
    }

    // Check permissions
    if (req.user?.role !== 'admin' && container.clientId !== req.user?.clientId) {
      res.status(403).json({
        success: false,
        message: 'Access denied to this container'
      });
      return;
    }

    await dockerService.stopContainer(container.id);
    
    res.json({
      success: true,
      message: `Container ${container.name} stopped successfully`
    });
  } catch (error: any) {
    logger.error('Stop container error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to stop container',
      error: error.message
    });
  }
});

// Restart container
router.post('/:id/restart', async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const containers = await dockerService.listContainers(req.user?.clientId);
    const container = containers.find((c: any) => c.id === id || c.id.startsWith(id));

    if (!container) {
      res.status(404).json({
        success: false,
        message: 'Container not found'
      });
      return;
    }

    // Check permissions
    if (req.user?.role !== 'admin' && container.clientId !== req.user?.clientId) {
      res.status(403).json({
        success: false,
        message: 'Access denied to this container'
      });
      return;
    }

    await dockerService.restartContainer(container.id);
    
    res.json({
      success: true,
      message: `Container ${container.name} restarted successfully`
    });
  } catch (error: any) {
    logger.error('Restart container error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to restart container',
      error: error.message
    });
  }
});

// Delete container (admin only or own containers)
router.delete('/:id', async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const containers = await dockerService.listContainers(req.user?.clientId);
    const container = containers.find((c: any) => c.id === id || c.id.startsWith(id));

    if (!container) {
      res.status(404).json({
        success: false,
        message: 'Container not found'
      });
      return;
    }

    // Check permissions
    if (req.user?.role !== 'admin' && container.clientId !== req.user?.clientId) {
      res.status(403).json({
        success: false,
        message: 'Access denied to this container'
      });
      return;
    }

    await dockerService.removeContainer(container.id);
    
    res.json({
      success: true,
      message: `Container ${container.name} removed successfully`
    });
  } catch (error: any) {
    logger.error('Remove container error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to remove container',
      error: error.message
    });
  }
});

// Get container logs
router.get('/:id/logs', async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const tail = parseInt(req.query.tail as string) || 100;
    
    const containers = await dockerService.listContainers(req.user?.clientId);
    const container = containers.find((c: any) => c.id === id || c.id.startsWith(id));

    if (!container) {
      res.status(404).json({
        success: false,
        message: 'Container not found'
      });
      return;
    }

    // Check permissions
    if (req.user?.role !== 'admin' && container.clientId !== req.user?.clientId) {
      res.status(403).json({
        success: false,
        message: 'Access denied to this container'
      });
      return;
    }

    const logs = await dockerService.getContainerLogs(container.id, tail);
    
    res.json({
      success: true,
      data: logs
    });
  } catch (error: any) {
    logger.error('Get logs error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get container logs',
      error: error.message
    });
  }
});

// Get container stats
router.get('/:id/stats', async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    
    const containers = await dockerService.listContainers(req.user?.clientId);
    const container = containers.find((c: any) => c.id === id || c.id.startsWith(id));

    if (!container) {
      res.status(404).json({
        success: false,
        message: 'Container not found'
      });
      return;
    }

    // Check permissions
    if (req.user?.role !== 'admin' && container.clientId !== req.user?.clientId) {
      res.status(403).json({
        success: false,
        message: 'Access denied to this container'
      });
      return;
    }

    const stats = await dockerService.getContainerStats(container.id);
    
    res.json({
      success: true,
      data: stats
    });
  } catch (error: any) {
    logger.error('Get stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get container stats',
      error: error.message
    });
  }
});

// Cleanup test/simulation containers (admin only)
router.delete('/cleanup-test', authorize(['admin']), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    await dockerService.cleanupTestContainers();

    res.json({
      success: true,
      message: 'Test containers cleaned up successfully'
    });
  } catch (error: any) {
    logger.error('Cleanup test containers error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to cleanup test containers',
      error: error.message
    });
  }
});

export default router;