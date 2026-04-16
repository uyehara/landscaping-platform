import Fastify from 'fastify';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import jwt from '@fastify/jwt';
import { Pool } from 'pg';
import { S3Client } from '@aws-sdk/client-s3';

// Plugins
import { healthRoutes } from './routes/health.js';
import { authRoutes } from './routes/auth.js';
import { projectRoutes } from './routes/projects.js';
import { storageRoutes } from './routes/storage.js';


const PORT = parseInt(process.env.PORT || '3001');

// Initialize Fastify
const app = Fastify({
  logger: {
    level: process.env.LOG_LEVEL || 'info'
  }
});

// Database pool
const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

// S3 client
const s3Client = new S3Client({
  endpoint: `http://${process.env.MINIO_ENDPOINT || 'localhost:9000'}`,
  region: 'us-east-1',
  credentials: {
    accessKeyId: process.env.MINIO_ACCESS_KEY || 'minioadmin',
    secretAccessKey: process.env.MINIO_SECRET_KEY || 'minioadmin'
  },
  forcePathStyle: true
});

// Decorate with dependencies
app.decorate('db', pool);
app.decorate('s3', s3Client);
app.decorate('config', {
  minioBucket: process.env.MINIO_BUCKET || 'landscaping-assets',
  aiServiceUrl: process.env.AI_SERVICE_URL || 'http://localhost:8000'
});

// Register plugins
await app.register(cors, {
  origin: process.env.CORS_ORIGIN || 'http://localhost:5173',
  credentials: true
});

await app.register(helmet, {
  contentSecurityPolicy: false
});

await app.register(jwt, {
  secret: process.env.JWT_SECRET || 'your-secret-key'
});


// Auth decorator
app.decorate('authenticate', async function (request: any, reply: any) {
  try {
    await request.jwtVerify();
  } catch (err) {
    reply.status(401).send({ error: 'Unauthorized' });
  }
});

// Register routes
await app.register(healthRoutes, { prefix: '/health' });
await app.register(authRoutes, { prefix: '/api/auth' });
await app.register(projectRoutes, { prefix: '/api/projects' });
await app.register(storageRoutes, { prefix: '/api/storage' });


// Root route
app.get('/', async () => ({
  name: 'Landscaping Platform API',
  version: '0.1.0',
  docs: '/docs'
}));

// Start server
const start = async () => {
  try {
    await app.listen({ port: PORT, host: '0.0.0.0' });
    console.log(`API Gateway running on port ${PORT}`);
  } catch (err) {
    app.log.error(err);
    process.exit(1);
  }
};

start();

// Graceful shutdown
process.on('SIGINT', async () => {
  await app.close();
  await pool.end();
  process.exit(0);
});
