/**
 * Authentication Routes for Container Management Platform
 * 
 * Provides secure user authentication endpoints:
 * - POST /api/auth/login - User authentication with JWT
 * - POST /api/auth/logout - Secure session termination
 * 
 * Security features:
 * - Input validation and sanitization
 * - JWT token generation with expiration
 * - Role-based access control
 * - Audit logging for security events
 * 
 * @author Container Platform Team
 * @version 1.0.0
 */

import express, { Response } from 'express';
import { body, validationResult } from 'express-validator';
import { AuthRequest } from '../middleware/auth';
import AuthService from '../services/authService';
import { LoginRequest } from '../types/database';
import { logger } from '../utils/logger';

const router = express.Router();
const authService = new AuthService();

/**
 * POST /api/auth/login
 * 
 * Authenticates user credentials and returns JWT token
 * 
 * Request body:
 * - email: User identifier (admin, client1, client2)
 * - password: User password (min 6 characters)
 * 
 * Response:
 * - 200: Authentication successful with JWT token
 * - 400: Validation errors in request
 * - 401: Invalid credentials
 * - 500: Server error
 * 
 * Security: Rate limiting should be applied in production
 */
router.post('/login', [
  body('email').notEmpty().withMessage('Email/username is required'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters')
], async (req: AuthRequest, res: Response) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation errors',
        errors: errors.array()
      });
    }

    const { email, password }: LoginRequest = req.body;
    
    // Utiliser le service d'authentification avec PostgreSQL
    const loginResult = await authService.login({ email, password });
    
    if (!loginResult.success) {
      return res.status(401).json(loginResult);
    }

    logger.info(`User ${email} logged in successfully`);

    res.json(loginResult);
  } catch (error) {
    logger.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Login failed',
      error: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

// Get current user info
router.get('/me', async (req: AuthRequest, res: Response) => {
  try {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Not authenticated'
      });
    }

    // Récupérer les informations utilisateur depuis la BDD
    const user = await authService.getUserById((req.user as any).userId);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      data: user
    });
  } catch (error) {
    logger.error('Get user info error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get user information'
    });
  }
});

// Logout route (in production, you might want to blacklist tokens)
router.post('/logout', (req: AuthRequest, res) => {
  res.json({
    success: true,
    message: 'Logged out successfully'
  });
});

export default router;