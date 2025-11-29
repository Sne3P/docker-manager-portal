import express, { Response } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import { logger } from '../utils/logger';

const router = express.Router();

// Apply authentication to all routes
router.use(authenticate);

// Get system statistics
router.get('/system', async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    // Mock system stats - in production, this would come from actual monitoring
    const stats = {
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      cpu: process.cpuUsage(),
      timestamp: new Date().toISOString()
    };

    logger.info('System stats requested', { userId: req.user?.id });

    res.json({
      success: true,
      data: stats,
      message: 'System statistics retrieved'
    });
  } catch (error: any) {
    logger.error('Get system stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get system statistics',
      error: error.message
    });
  }
});

// Get resource usage
router.get('/resources', async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    // Mock resource usage - in production, this would come from Docker/system monitoring
    const resources = {
      containers: {
        total: 10,
        running: 7,
        stopped: 3
      },
      resources: {
        cpuUsage: Math.random() * 100,
        memoryUsage: Math.random() * 100,
        diskUsage: Math.random() * 100
      },
      timestamp: new Date().toISOString()
    };

    logger.info('Resource usage requested', { userId: req.user?.id });

    res.json({
      success: true,
      data: resources,
      message: 'Resource usage retrieved'
    });
  } catch (error: any) {
    logger.error('Get resource usage error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get resource usage',
      error: error.message
    });
  }
});

export default router;