import express, { Response } from 'express';
import * as jwt from 'jsonwebtoken';
import { body, validationResult } from 'express-validator';
import { AuthRequest, validateCredentials } from '../middleware/auth';
import { AuthResponse, LoginRequest } from '../types';
import { logger } from '../utils/logger';

const router = express.Router();

// Login route
router.post('/login', [
  body('email').notEmpty(),
  body('password').isLength({ min: 6 })
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
    
    // Validate credentials
    const user = validateCredentials(email, password);
    
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    if (!process.env.JWT_SECRET) {
      logger.error('JWT_SECRET not configured');
      return res.status(500).json({
        success: false,
        message: 'Authentication service not configured'
      });
    }

    // Generate JWT token
    const jwtSecret = process.env.JWT_SECRET;
    if (!jwtSecret) {
      return res.status(500).json({
        error: 'JWT_SECRET not configured'
      });
    }
    
    const tokenOptions = { expiresIn: (process.env.JWT_EXPIRES_IN || '24h') as any };
    const payload = { userId: user.id, role: user.role, clientId: user.clientId || undefined, email: email, name: user.name };
    const token = jwt.sign(payload, jwtSecret, tokenOptions);

    const response: AuthResponse = {
      user: {
        id: user.id,
        email: email,
        role: user.role,
        clientId: user.clientId || undefined,
        name: user.name,
        createdAt: new Date(),
        lastLogin: new Date()
      },
      token,
      expiresIn: process.env.JWT_EXPIRES_IN || '24h'
    };

    logger.info(`User ${email} logged in successfully`);

    res.json({
      success: true,
      data: response,
      message: 'Login successful'
    });
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

    res.json({
      success: true,
      data: {
        id: req.user.id,
        email: req.user.email,
        role: req.user.role,
        clientId: req.user.clientId,
        name: req.user.name,
        createdAt: req.user.createdAt,
        lastLogin: req.user.lastLogin
      }
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