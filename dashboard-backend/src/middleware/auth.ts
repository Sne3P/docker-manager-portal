import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { User } from '../types';
import { logger } from '../utils/logger';

// Mock users database (in production, use a real database)
const MOCK_USERS: User[] = [
  {
    id: 'admin-1',
    email: 'admin@containerplatform.com',
    role: 'admin',
    name: 'System Administrator',
    createdAt: new Date('2024-01-01'),
    lastLogin: new Date()
  },
  {
    id: 'client-1',
    email: 'client1@example.com',
    role: 'client',
    clientId: 'client-1',
    name: 'Client One',
    createdAt: new Date('2024-01-15'),
    lastLogin: new Date()
  },
  {
    id: 'client-2',
    email: 'client2@example.com',
    role: 'client',
    clientId: 'client-2',
    name: 'Client Two',
    createdAt: new Date('2024-02-01'),
    lastLogin: new Date()
  }
];

export interface AuthRequest extends Request {
  user?: User;
}

export const authenticate = (req: AuthRequest, res: Response, next: NextFunction): void => {
  try {
    const authHeader = req.headers.authorization;
    logger.info(`Auth middleware called. Header: ${authHeader ? 'Present' : 'Missing'}`);
    
    if (!authHeader?.startsWith('Bearer ')) {
      logger.warn(`Invalid auth header format: ${authHeader}`);
      res.status(401).json({
        success: false,
        error: 'Access token is missing or invalid'
      });
      return;
    }

    const token = authHeader.substring(7);
    logger.info(`Token extracted, length: ${token.length}`);
    
    if (!process.env.JWT_SECRET) {
      logger.error('JWT_SECRET is not configured');
      res.status(500).json({
        success: false,
        error: 'Authentication service not properly configured'
      });
      return;
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET) as any;
    logger.info(`Token decoded successfully. UserId: ${decoded.userId}`);
    
    // Find user (in production, query from database)
    const user = MOCK_USERS.find(u => u.id === decoded.userId);
    
    if (!user) {
      res.status(401).json({
        success: false,
        error: 'Invalid token - user not found'
      });
      return;
    }

    // Set user info from token
    req.user = {
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
      clientId: user.clientId,
      createdAt: user.createdAt,
      lastLogin: new Date()
    };
    
    next();
  } catch (error) {
    logger.error('Authentication error:', error);
    
    if (error instanceof jwt.TokenExpiredError) {
      logger.warn('Token expired');
      res.status(401).json({
        success: false,
        error: 'Token has expired'
      });
      return;
    }
    
    if (error instanceof jwt.JsonWebTokenError) {
      logger.warn(`JWT Error: ${error.message}`);
      res.status(401).json({
        success: false,
        error: 'Invalid token'
      });
      return;
    }

    logger.error(`Unexpected auth error: ${error}`);
    res.status(500).json({
      success: false,
      error: 'Authentication service error'
    });
  }
};

export const authorize = (roles: Array<User['role']>) => {
  return (req: AuthRequest, res: Response, next: NextFunction): void => {
    if (!req.user) {
      res.status(401).json({
        success: false,
        error: 'Authentication required'
      });
      return;
    }

    if (!roles.includes(req.user.role)) {
      res.status(403).json({
        success: false,
        error: 'Insufficient permissions'
      });
      return;
    }

    next();
  };
};

export const getMockUsers = () => MOCK_USERS;
export const findUserByEmail = (email: string) => MOCK_USERS.find(u => u.email === email);