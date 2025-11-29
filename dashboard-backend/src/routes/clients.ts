import express, { Response } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import { logger } from '../utils/logger';

const router = express.Router();

// Apply authentication to all routes
router.use(authenticate);

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

// Get client info (client can only see their own info)
router.get('/me/info', async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (req.user?.role !== 'client') {
      res.status(403).json({
        success: false,
        message: 'This endpoint is for clients only'
      });
      return;
    }

    const client = clients.find(c => c.id === req.user?.clientId);
    
    if (!client) {
      res.status(404).json({
        success: false,
        message: 'Client not found'
      });
      return;
    }

    logger.info('Client fetched own info', { clientId: req.user.clientId });

    res.json({
      success: true,
      data: client,
      message: 'Client info retrieved'
    });
  } catch (error: any) {
    logger.error('Get client info error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get client info',
      error: error.message
    });
  }
});

export default router;