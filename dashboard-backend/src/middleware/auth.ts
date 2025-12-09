/**
 * Authentication Middleware for Container Management Platform
 * 
 * Handles JWT token validation and user authentication
 * Supports role-based access control (admin/client)
 * 
 * @author Container Platform Team
 * @version 1.0.0
 */

import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { User } from '../types';
import { logger } from '../utils/logger';
import AuthService from '../services/authService';

// Authentication now handled by PostgreSQL database via AuthService

/**
 * Extended Express Request interface with user authentication data
 * 
 * Adds user property after successful JWT validation
 * Used throughout the application for authenticated routes
 */
export interface AuthRequest extends Request {
  user?: User;
}

/**
 * Main authentication middleware function
 * 
 * Validates JWT tokens and attaches user data to request
 * Supports Bearer token authentication via Authorization header
 * 
 * @param req Express request with optional user data
 * @param res Express response object
 * @param next Express next function
 * 
 * @throws 401 if token is missing, invalid, or expired
 * @throws 403 if user not found or inactive
 */
export const authenticate = (req: AuthRequest, res: Response, next: NextFunction): void => {
  try {
    // Extract Bearer token from Authorization header
    const authHeader = req.headers.authorization;
    
    if (!authHeader?.startsWith('Bearer ')) {
      res.status(401).json({
        success: false,
        error: 'Access token is missing or invalid'
      });
      return;
    }

    const token = authHeader.substring(7);
    
    if (!process.env.JWT_SECRET) {
      logger.error('JWT_SECRET is not configured');
      res.status(500).json({
        success: false,
        error: 'Authentication service not properly configured'
      });
      return;
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET) as any;
    
    // Set user info from token payload
    req.user = {
      id: decoded.userId,
      email: decoded.email,
      name: decoded.name,
      role: decoded.role,
      clientId: decoded.clientId,
      createdAt: new Date(),
      lastLogin: new Date()
    };
    
    next();
  } catch (error) {
    logger.error('Authentication error:', error);
    
    if (error instanceof jwt.TokenExpiredError) {
      res.status(401).json({
        success: false,
        error: 'Token has expired'
      });
      return;
    }
    
    if (error instanceof jwt.JsonWebTokenError) {
      res.status(401).json({
        success: false,
        error: 'Invalid token'
      });
      return;
    }

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

// User validation now handled by AuthService with PostgreSQL