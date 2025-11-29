import express, { Response } from 'express';
import { body, validationResult } from 'express-validator';
import { authenticate, authorize, AuthRequest } from '../middleware/auth';
import { logger } from '../utils/logger';

const router = express.Router();

// Apply authentication and admin authorization to all routes
router.use(authenticate);
router.use(authorize(['admin']));

// Predefined clients data (in production, this would come from database)
const clients = [
  {
    id: 'client1',
    name: 'Client 1',
    email: 'client1@example.com',
    createdAt: new Date('2024-01-01').toISOString()
  },
  {
    id: 'client2', 
    name: 'Client 2',
    email: 'client2@example.com',
    createdAt: new Date('2024-01-15').toISOString()
  }
];

// Get all clients (admin only)
router.get('/clients', async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    logger.info('Admin fetching all clients', { adminId: req.user?.id });
    
    res.json({
      success: true,
      data: clients,
      message: `Found ${clients.length} clients`
    });
  } catch (error: any) {
    logger.error('Get clients error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get clients',
      error: error.message
    });
  }
});

// Get client by ID (admin only)
router.get('/clients/:id', async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const client = clients.find(c => c.id === id);

    if (!client) {
      res.status(404).json({
        success: false,
        message: 'Client not found'
      });
      return;
    }

    logger.info('Admin fetching client details', { adminId: req.user?.id, clientId: id });

    res.json({
      success: true,
      data: client,
      message: 'Client found'
    });
  } catch (error: any) {
    logger.error('Get client error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get client',
      error: error.message
    });
  }
});

// Create new client (admin only)
router.post('/clients', [
  body('name').isLength({ min: 1 }).withMessage('Name is required'),
  body('email').isEmail().withMessage('Valid email is required')
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

    const { name, email } = req.body;
    
    // Check if email already exists
    const existingClient = clients.find(c => c.email === email);
    if (existingClient) {
      res.status(409).json({
        success: false,
        message: 'Client with this email already exists'
      });
      return;
    }

    const newClient = {
      id: `client${Date.now()}`,
      name,
      email,
      createdAt: new Date().toISOString()
    };

    clients.push(newClient);

    logger.info('Admin created new client', { 
      adminId: req.user?.id, 
      clientId: newClient.id,
      clientEmail: email
    });

    res.status(201).json({
      success: true,
      data: newClient,
      message: 'Client created successfully'
    });
  } catch (error: any) {
    logger.error('Create client error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create client',
      error: error.message
    });
  }
});

// Update client (admin only)
router.put('/clients/:id', [
  body('name').optional().isLength({ min: 1 }).withMessage('Name must not be empty'),
  body('email').optional().isEmail().withMessage('Valid email is required')
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

    const { id } = req.params;
    const { name, email } = req.body;
    
    const clientIndex = clients.findIndex(c => c.id === id);
    if (clientIndex === -1) {
      res.status(404).json({
        success: false,
        message: 'Client not found'
      });
      return;
    }

    // Check if email already exists for another client
    if (email) {
      const existingClient = clients.find(c => c.email === email && c.id !== id);
      if (existingClient) {
        res.status(409).json({
          success: false,
          message: 'Email already exists for another client'
        });
        return;
      }
    }

    // Update client
    if (name) clients[clientIndex].name = name;
    if (email) clients[clientIndex].email = email;

    logger.info('Admin updated client', { 
      adminId: req.user?.id, 
      clientId: id,
      updates: { name, email }
    });

    res.json({
      success: true,
      data: clients[clientIndex],
      message: 'Client updated successfully'
    });
  } catch (error: any) {
    logger.error('Update client error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update client',
      error: error.message
    });
  }
});

// Delete client (admin only)
router.delete('/clients/:id', async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    
    const clientIndex = clients.findIndex(c => c.id === id);
    if (clientIndex === -1) {
      res.status(404).json({
        success: false,
        message: 'Client not found'
      });
      return;
    }

    const deletedClient = clients.splice(clientIndex, 1)[0];

    logger.info('Admin deleted client', { 
      adminId: req.user?.id, 
      clientId: id,
      clientEmail: deletedClient.email
    });

    res.json({
      success: true,
      data: deletedClient,
      message: 'Client deleted successfully'
    });
  } catch (error: any) {
    logger.error('Delete client error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete client',
      error: error.message
    });
  }
});

// Get system statistics (admin only)
router.get('/stats', async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    // In production, these would be real metrics from database/monitoring
    const stats = {
      totalClients: clients.length,
      totalContainers: 0, // Would be calculated from actual containers
      activeContainers: 0, // Would be calculated from Docker
      systemResources: {
        cpuUsage: Math.random() * 100,
        memoryUsage: Math.random() * 100,
        diskUsage: Math.random() * 100
      }
    };

    logger.info('Admin fetched system stats', { adminId: req.user?.id });

    res.json({
      success: true,
      data: stats,
      message: 'System statistics retrieved'
    });
  } catch (error: any) {
    logger.error('Get stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get system statistics',
      error: error.message
    });
  }
});

export default router;