const cron = require('node-cron');
require('dotenv').config();

const SERVICE_NAME = process.env.SERVICE_NAME || 'Demo Worker Service';
const CLIENT_ID = process.env.CLIENT_ID || 'unknown';
const TASK_INTERVAL = process.env.TASK_INTERVAL || '*/30 * * * * *'; // Every 30 seconds by default
const LOG_LEVEL = process.env.LOG_LEVEL || 'info';

// Service state
let serviceState = {
    name: SERVICE_NAME,
    clientId: CLIENT_ID,
    startTime: new Date(),
    taskCount: 0,
    lastTaskTime: null,
    isRunning: true,
    processedJobs: [],
    errors: []
};

// Logging utility
function log(level, message, data = null) {
    const timestamp = new Date().toISOString();
    const logEntry = {
        timestamp,
        level,
        service: SERVICE_NAME,
        client: CLIENT_ID,
        message,
        data
    };
    
    console.log(`[${timestamp}] [${level.toUpperCase()}] [${CLIENT_ID}] ${message}${data ? ' | Data: ' + JSON.stringify(data) : ''}`);
    
    // Keep last 100 log entries for monitoring
    if (serviceState.processedJobs.length > 100) {
        serviceState.processedJobs.shift();
    }
    serviceState.processedJobs.push(logEntry);
}

// Sample tasks that the worker can perform
const taskTypes = [
    {
        name: 'data_processing',
        description: 'Process customer data batch',
        duration: () => Math.random() * 2000 + 1000, // 1-3 seconds
        execute: async (taskId) => {
            const customers = Math.floor(Math.random() * 100) + 50;
            await simulateWork(1000 + Math.random() * 1000);
            return { processed_customers: customers, status: 'completed' };
        }
    },
    {
        name: 'email_sending',
        description: 'Send notification emails',
        duration: () => Math.random() * 1500 + 500, // 0.5-2 seconds
        execute: async (taskId) => {
            const emails = Math.floor(Math.random() * 50) + 10;
            await simulateWork(500 + Math.random() * 1000);
            return { emails_sent: emails, status: 'completed' };
        }
    },
    {
        name: 'report_generation',
        description: 'Generate daily reports',
        duration: () => Math.random() * 3000 + 2000, // 2-5 seconds
        execute: async (taskId) => {
            const reports = Math.floor(Math.random() * 10) + 1;
            await simulateWork(2000 + Math.random() * 2000);
            return { reports_generated: reports, status: 'completed' };
        }
    },
    {
        name: 'database_cleanup',
        description: 'Clean up temporary database entries',
        duration: () => Math.random() * 1000 + 500, // 0.5-1.5 seconds
        execute: async (taskId) => {
            const deleted_records = Math.floor(Math.random() * 200) + 100;
            await simulateWork(500 + Math.random() * 1000);
            return { deleted_records, status: 'completed' };
        }
    }
];

// Simulate work with random delay
function simulateWork(duration) {
    return new Promise(resolve => setTimeout(resolve, duration));
}

// Generate unique task ID
function generateTaskId() {
    return `task_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
}

// Execute a random task
async function executeTask() {
    const taskType = taskTypes[Math.floor(Math.random() * taskTypes.length)];
    const taskId = generateTaskId();
    
    log('info', `Starting task: ${taskType.name}`, { taskId, description: taskType.description });
    
    try {
        const startTime = Date.now();
        const result = await taskType.execute(taskId);
        const duration = Date.now() - startTime;
        
        serviceState.taskCount++;
        serviceState.lastTaskTime = new Date();
        
        log('info', `Task completed: ${taskType.name}`, {
            taskId,
            duration: `${duration}ms`,
            result
        });
        
        return { success: true, taskId, taskType: taskType.name, result, duration };
    } catch (error) {
        serviceState.errors.push({
            timestamp: new Date(),
            taskId,
            taskType: taskType.name,
            error: error.message
        });
        
        log('error', `Task failed: ${taskType.name}`, {
            taskId,
            error: error.message
        });
        
        return { success: false, taskId, error: error.message };
    }
}

// Health check function
function getHealthStatus() {
    const uptime = Date.now() - serviceState.startTime.getTime();
    const uptimeSeconds = Math.floor(uptime / 1000);
    
    return {
        status: 'healthy',
        service: SERVICE_NAME,
        client: CLIENT_ID,
        uptime: uptimeSeconds,
        uptimeHuman: formatUptime(uptimeSeconds),
        taskCount: serviceState.taskCount,
        lastTaskTime: serviceState.lastTaskTime,
        memoryUsage: process.memoryUsage(),
        cpuUsage: process.cpuUsage(),
        errors: serviceState.errors.length,
        timestamp: new Date().toISOString()
    };
}

// Format uptime in human readable format
function formatUptime(seconds) {
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;
    
    if (days > 0) return `${days}d ${hours}h ${minutes}m`;
    if (hours > 0) return `${hours}h ${minutes}m`;
    if (minutes > 0) return `${minutes}m ${secs}s`;
    return `${secs}s`;
}

// Periodic task execution
function startTaskScheduler() {
    log('info', 'Starting task scheduler', { interval: TASK_INTERVAL });
    
    cron.schedule(TASK_INTERVAL, async () => {
        if (serviceState.isRunning) {
            await executeTask();
        }
    });
}

// Status monitoring
function startStatusMonitoring() {
    // Log status every 5 minutes
    cron.schedule('0 */5 * * * *', () => {
        const status = getHealthStatus();
        log('info', 'Service status update', {
            uptime: status.uptimeHuman,
            taskCount: status.taskCount,
            memoryUsage: Math.round(status.memoryUsage.heapUsed / 1024 / 1024) + 'MB'
        });
    });
}

// Graceful shutdown
function gracefulShutdown(signal) {
    log('info', `Received ${signal}, shutting down gracefully`);
    serviceState.isRunning = false;
    
    setTimeout(() => {
        log('info', 'Service stopped', { 
            totalTasks: serviceState.taskCount,
            uptime: formatUptime(Math.floor((Date.now() - serviceState.startTime.getTime()) / 1000))
        });
        process.exit(0);
    }, 2000);
}

// Initialize service
function initialize() {
    log('info', 'Initializing worker service', {
        service: SERVICE_NAME,
        client: CLIENT_ID,
        taskInterval: TASK_INTERVAL,
        logLevel: LOG_LEVEL
    });
    
    // Start schedulers
    startTaskScheduler();
    startStatusMonitoring();
    
    // Setup signal handlers
    process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
    process.on('SIGINT', () => gracefulShutdown('SIGINT'));
    
    // Setup error handlers
    process.on('uncaughtException', (error) => {
        log('error', 'Uncaught exception', { error: error.message, stack: error.stack });
        serviceState.errors.push({
            timestamp: new Date(),
            type: 'uncaughtException',
            error: error.message
        });
    });
    
    process.on('unhandledRejection', (reason, promise) => {
        log('error', 'Unhandled promise rejection', { reason, promise });
        serviceState.errors.push({
            timestamp: new Date(),
            type: 'unhandledRejection',
            reason: reason
        });
    });
    
    log('info', 'Worker service started successfully');
    
    // Execute first task immediately
    setTimeout(executeTask, 5000);
}

// Start the service
initialize();