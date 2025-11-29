import express, { Response } from 'express';
import bcrypt from 'bcryptjs';
import * as jwt from 'jsonwebtoken';
import { body, validationResult } from 'express-validator';
import { AuthRequest, findUserByEmail } from '../middleware/auth';
import { AuthResponse, LoginRequest } from '../types';
import { logger } from '../utils/logger';

const router = express.Router();

// Login route
router.post('/login', [
  body('email').isEmail().normalizeEmail(),
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
    
    // Find user (in production, use database with hashed passwords)
    const user = findUserByEmail(email);
    
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // In production, compare with bcrypt.compare(password, user.hashedPassword)
    // For demo, we use simple password check (NOT for production!)
    const validPassword = email === 'admin@containerplatform.com' && password === 'admin123' ||
                         email === 'client1@example.com' && password === 'client123' ||
                         email === 'client2@example.com' && password === 'client123';

    if (!validPassword) {
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
    const payload = { userId: user.id, role: user.role, clientId: user.clientId, email: user.email, name: user.name };
    const token = jwt.sign(payload, jwtSecret, tokenOptions);
    
    logger.info(`Token generated for user ${user.email}. Payload: ${JSON.stringify(payload)}`);

    // Update last login (in production, update database)
    user.lastLogin = new Date();

    const response: AuthResponse = {
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        clientId: user.clientId,
        name: user.name,
        createdAt: user.createdAt,
        lastLogin: user.lastLogin
      },
      token,
      expiresIn: process.env.JWT_EXPIRES_IN || '24h'
    };

    logger.info(`User ${user.email} logged in successfully`);

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