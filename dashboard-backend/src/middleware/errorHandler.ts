import { Request, Response, NextFunction } from 'express';
import { logger } from '../utils/logger';

export const errorHandler = (
  err: any,
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  logger.error('Error occurred:', {
    message: err.message,
    stack: err.stack,
    url: req.url,
    method: req.method,
    ip: req.ip
  });

  // Default error
  let error = {
    success: false,
    message: 'Internal Server Error',
    timestamp: new Date().toISOString()
  };

  // Validation errors
  if (err.name === 'ValidationError') {
    error.message = 'Validation Error';
    res.status(400).json({ ...error, details: err.details });
    return;
  }

  // JWT errors
  if (err.name === 'JsonWebTokenError') {
    error.message = 'Invalid token';
    res.status(401).json(error);
    return;
  }

  if (err.name === 'TokenExpiredError') {
    error.message = 'Token expired';
    res.status(401).json(error);
    return;
  }

  // Docker errors
  if (err.message?.includes('Docker')) {
    error.message = 'Docker service error';
    res.status(503).json({ ...error, details: err.message });
    return;
  }

  // Duplicate resource
  if (err.code === 11000) {
    error.message = 'Duplicate resource';
    res.status(409).json(error);
    return;
  }

  // Resource not found
  if (err.name === 'CastError') {
    error.message = 'Resource not found';
    res.status(404).json(error);
    return;
  }

  // Development mode - show full error
  if (process.env.NODE_ENV === 'development') {
    (error as any).details = err.message;
    (error as any).stack = err.stack;
  }

  res.status(err.statusCode || 500).json(error);
};