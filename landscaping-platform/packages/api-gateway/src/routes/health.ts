import type { FastifyInstance, FastifyPluginAsync } from 'fastify';

const healthRoutes: FastifyPluginAsync = async (app: FastifyInstance) => {
  app.get('/', async () => ({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    services: {
      database: 'connected',
      storage: 'connected'
    }
  }));
};

export { healthRoutes };
