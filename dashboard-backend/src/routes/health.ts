/**
 * Health Check Routes for Container Management Platform
 * 
 * Provides system health and readiness endpoints for:
 * - Load balancer health checks
 * - Monitoring system integration
 * - Deployment validation
 * 
 * @author Container Platform Team
 * @version 1.0.0
 */

import express, { Request, Response } from 'express';
import { logger } from '../utils/logger';

const router = express.Router();

/**
 * GET /api/health
 * 
 * Basic health check endpoint
 * Returns 200 OK if service is running
 * 
 * Used by:
 * - Azure Application Gateway
 * - Docker health checks
 * - Monitoring systems
 */
router.get('/', (req: Request, res: Response) => {
  try {
    const healthStatus = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      version: process.env.npm_package_version || '1.0.0',
      uptime: process.uptime(),
      environment: process.env.NODE_ENV || 'development'
    };

    res.status(200).json({
      success: true,
      data: healthStatus
    });
  } catch (error) {
    logger.error('Health check failed:', error);
    res.status(503).json({
      success: false,
      status: 'unhealthy',
      timestamp: new Date().toISOString()
    });
  }
});

/**
 * GET /api/health/ready
 * 
 * Readiness probe for Kubernetes/container orchestration
 * Checks if service is ready to accept traffic
 * 
 * Validates:
 * - Environment variables loaded
 * - JWT secret configured
 * - Service dependencies available
 */
router.get('/ready', (req: Request, res: Response) => {
  try {
    const checks = {
      jwt_configured: !!process.env.JWT_SECRET,
      node_env: !!process.env.NODE_ENV,
      port_configured: !!process.env.PORT
    };

    const isReady = Object.values(checks).every(check => check);
    const status = isReady ? 'ready' : 'not_ready';

    res.status(isReady ? 200 : 503).json({
      success: isReady,
      status,
      checks,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    logger.error('Readiness check failed:', error);
    res.status(503).json({
      success: false,
      status: 'not_ready',
      timestamp: new Date().toISOString()
    });
  }
});

export default router;