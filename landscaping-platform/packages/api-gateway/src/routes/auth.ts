import type { FastifyInstance, FastifyPluginAsync } from 'fastify';
import { z } from 'zod';

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8)
});

const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  name: z.string().min(2)
});


const authRoutes: FastifyPluginAsync = async (app: FastifyInstance) => {
  // Login
  app.post('/login', async (request, reply) => {
    const body = loginSchema.safeParse(request.body);
    if (!body.success) {
      return reply.status(400).send({ error: 'Invalid request' });
    }

    const { email, password } = body.data;

    // TODO: Implement actual auth logic with database
    // For MVP, return a mock token
    const token = app.jwt.sign({ email, role: 'user' });

    return { token, user: { email, name: 'User' } };
  });

  // Register
  app.post('/register', async (request, reply) => {
    const body = registerSchema.safeParse(request.body);
    if (!body.success) {
      return reply.status(400).send({ error: 'Invalid request' });
    }

    const { email, password, name } = body.data;

    // TODO: Implement actual registration with database
    const token = app.jwt.sign({ email, role: 'user' });

    return { token, user: { email, name } };
  });

  // Get current user
  app.get('/me', {
    preHandler: [app.authenticate]
  }, async (request, reply) => {
    const { email } = request.user as any;
    // TODO: Fetch user from database
    return { email, name: 'User' };
  });
};

export { authRoutes };
