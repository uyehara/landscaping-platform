import type { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';

export interface AuthUser {
  id: string;
  email: string;
  role: string;
}

export async function verifyToken(
  app: FastifyInstance,
  request: FastifyRequest,
  reply: FastifyReply
): Promise<void> {
  try {
    await request.jwtVerify();
  } catch (err) {
    reply.status(401).send({ error: 'Unauthorized', message: 'Invalid or expired token' });
  }
}

export function requireRole(app: FastifyInstance, role: string) {
  return async (request: FastifyRequest, reply: FastifyReply) => {
    await verifyToken(app, request, reply);
    const user = request.user as AuthUser;
    if (user.role !== role && user.role !== 'admin') {
      reply.status(403).send({ error: 'Forbidden', message: 'Insufficient permissions' });
    }
  };
}
