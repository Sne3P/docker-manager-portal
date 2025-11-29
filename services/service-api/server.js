const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3001;
const SERVICE_NAME = process.env.SERVICE_NAME || 'Demo API Service';
const CLIENT_ID = process.env.CLIENT_ID || 'unknown';

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());

// Sample data
const sampleData = {
  users: [
    { id: 1, name: 'John Doe', email: 'john@example.com', active: true },
    { id: 2, name: 'Jane Smith', email: 'jane@example.com', active: true },
    { id: 3, name: 'Bob Johnson', email: 'bob@example.com', active: false }
  ],
  products: [
    { id: 1, name: 'Laptop', price: 999.99, category: 'Electronics' },
    { id: 2, name: 'Coffee Mug', price: 12.99, category: 'Kitchen' },
    { id: 3, name: 'Desk Chair', price: 199.99, category: 'Furniture' }
  ]
};

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    service: SERVICE_NAME,
    client: CLIENT_ID,
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    version: '1.0.0'
  });
});

// Service info endpoint
app.get('/', (req, res) => {
  res.json({
    service: SERVICE_NAME,
    description: 'Demo API service for container management platform',
    client: CLIENT_ID,
    version: '1.0.0',
    endpoints: [
      'GET / - Service information',
      'GET /health - Health check',
      'GET /users - List users',
      'GET /users/:id - Get specific user',
      'GET /products - List products',
      'GET /products/:id - Get specific product',
      'POST /echo - Echo request data'
    ],
    timestamp: new Date().toISOString()
  });
});

// Users endpoints
app.get('/users', (req, res) => {
  console.log(`[${new Date().toISOString()}] GET /users - Client: ${CLIENT_ID}`);
  res.json({
    success: true,
    data: sampleData.users,
    count: sampleData.users.length,
    client: CLIENT_ID
  });
});

app.get('/users/:id', (req, res) => {
  const userId = parseInt(req.params.id);
  const user = sampleData.users.find(u => u.id === userId);
  
  console.log(`[${new Date().toISOString()}] GET /users/${userId} - Client: ${CLIENT_ID}`);
  
  if (user) {
    res.json({
      success: true,
      data: user,
      client: CLIENT_ID
    });
  } else {
    res.status(404).json({
      success: false,
      message: 'User not found',
      client: CLIENT_ID
    });
  }
});

// Products endpoints
app.get('/products', (req, res) => {
  console.log(`[${new Date().toISOString()}] GET /products - Client: ${CLIENT_ID}`);
  res.json({
    success: true,
    data: sampleData.products,
    count: sampleData.products.length,
    client: CLIENT_ID
  });
});

app.get('/products/:id', (req, res) => {
  const productId = parseInt(req.params.id);
  const product = sampleData.products.find(p => p.id === productId);
  
  console.log(`[${new Date().toISOString()}] GET /products/${productId} - Client: ${CLIENT_ID}`);
  
  if (product) {
    res.json({
      success: true,
      data: product,
      client: CLIENT_ID
    });
  } else {
    res.status(404).json({
      success: false,
      message: 'Product not found',
      client: CLIENT_ID
    });
  }
});

// Echo endpoint for testing
app.post('/echo', (req, res) => {
  console.log(`[${new Date().toISOString()}] POST /echo - Client: ${CLIENT_ID}`, req.body);
  res.json({
    success: true,
    message: 'Echo response',
    data: req.body,
    timestamp: new Date().toISOString(),
    client: CLIENT_ID
  });
});

// Stats endpoint
app.get('/stats', (req, res) => {
  res.json({
    service: SERVICE_NAME,
    client: CLIENT_ID,
    stats: {
      totalUsers: sampleData.users.length,
      activeUsers: sampleData.users.filter(u => u.active).length,
      totalProducts: sampleData.products.length,
      uptime: process.uptime(),
      memoryUsage: process.memoryUsage(),
      cpuUsage: process.cpuUsage()
    },
    timestamp: new Date().toISOString()
  });
});

// Error handling
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Endpoint not found',
    path: req.path,
    method: req.method,
    client: CLIENT_ID
  });
});

app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({
    success: false,
    message: 'Internal server error',
    client: CLIENT_ID
  });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 ${SERVICE_NAME} running on port ${PORT}`);
  console.log(`📋 Client ID: ${CLIENT_ID}`);
  console.log(`🕒 Started at: ${new Date().toISOString()}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('🛑 SIGTERM received, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('🛑 SIGINT received, shutting down gracefully');
  process.exit(0);
});