import type { FastifyInstance, FastifyPluginAsync } from 'fastify';
import { z } from 'zod';

const createProjectSchema = z.object({
  name: z.string().min(1).max(255),
  description: z.string().optional(),
  clientId: z.string().uuid().optional()
});

const projectRoutes: FastifyPluginAsync = async (app: FastifyInstance) => {
  // List projects
  app.get('/', {
    preHandler: [app.authenticate]
  }, async (request) => {
    // TODO: Fetch from database with user filter
    return {
      projects: [
        {
          id: 'demo-project-1',
          name: 'Demo Project',
          description: 'A sample landscaping project',
          ownerId: 'user-1',
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        }
      ]
    };
  });


  // Get project by ID
  app.get('/:id', {
    preHandler: [app.authenticate]
  }, async (request, reply) => {
    const { id } = request.params as { id: string };
    // TODO: Fetch from database
    if (!id) {
      return reply.status(404).send({ error: 'Project not found' });
    }
    return {
      id,
      name: 'Demo Project',
      description: 'A sample landscaping project',
      ownerId: 'user-1',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
  });

  // Create project
  app.post('/', {
    preHandler: [app.authenticate]
  }, async (request, reply) => {
    const body = createProjectSchema.safeParse(request.body);
    if (!body.success) {
      return reply.status(400).send({ error: 'Invalid request', details: body.error });
    }

    const { name, description, clientId } = body.data;
    // TODO: Insert into database
    return {
      id: crypto.randomUUID(),
      name,
      description,
      clientId,
      ownerId: 'user-1',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
  });

  // Update project
  app.put('/:id', {
    preHandler: [app.authenticate]
  }, async (request, reply) => {
    const { id } = request.params as { id: string };
    const body = createProjectSchema.partial().safeParse(request.body);
    if (!body.success) {
      return reply.status(400).send({ error: 'Invalid request' });
    }
    // TODO: Update in database
    return { id, ...body.data, updatedAt: new Date().toISOString() };
  });

  // Delete project
  app.delete('/:id', {
    preHandler: [app.authenticate]
  }, async (request, reply) => {
    const { id } = request.params as { id: string };
    // TODO: Delete from database
    return { success: true, id };
  });
};

export { projectRoutes };
