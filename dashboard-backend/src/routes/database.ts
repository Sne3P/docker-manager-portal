import express from 'express';
import DatabaseService from '../services/databaseService';
import { logger } from '../utils/logger';

const router = express.Router();

// Route pour initialiser manuellement la base de données (tables de base)
router.post('/init-database', async (req, res) => {
  try {
    logger.info('🔧 Manual database initialization requested');
    
    const dbService = new DatabaseService();
    await dbService.initializeTables();
    
    logger.info('✅ Database initialization completed successfully');
    
    res.json({
      success: true,
      message: 'Database initialized successfully',
      timestamp: new Date().toISOString()
    });
  } catch (error: any) {
    logger.error('❌ Database initialization failed:', error);
    
    res.status(500).json({
      success: false,
      message: 'Database initialization failed',
      error: error.message,
      details: {
        code: error.code,
        severity: error.severity,
        detail: error.detail
      },
      timestamp: new Date().toISOString()
    });
  }
});


// Route pour vérifier l'état de la base de données
router.get('/database-status', async (req, res) => {
  try {
    const dbService = new DatabaseService();
    
    // Test de connexion
    const connectionTest = await dbService.query('SELECT 1 as test');
    
    // Vérification de l'existence de la table users
    const tables = await dbService.query(`
      SELECT table_name FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_name = 'users'
    `);
    
    let userCount = 0;
    let adminExists = false;
    
    if (tables.rows.length > 0) {
      const countResult = await dbService.query('SELECT COUNT(*) as count FROM users');
      userCount = parseInt(countResult.rows[0].count);
      
      const adminResult = await dbService.query('SELECT id FROM users WHERE email = $1', ['admin@example.com']);
      adminExists = adminResult.rows.length > 0;
    }
    
    res.json({
      success: true,
      database: {
        connected: true,
        tables: {
          users: tables.rows.length > 0
        },
        data: {
          userCount,
          adminExists
        }
      },
      timestamp: new Date().toISOString()
    });
  } catch (error: any) {
    logger.error('Database status check failed:', error);
    
    res.status(500).json({
      success: false,
      message: 'Database status check failed',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

export default router;