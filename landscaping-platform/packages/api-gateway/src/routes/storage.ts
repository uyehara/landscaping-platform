import type { FastifyInstance, FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { PutObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3';

const storageRoutes: FastifyPluginAsync = async (app: FastifyInstance) => {

  // Upload file
  app.post('/upload', {
    preHandler: [app.authenticate]
  }, async (request, reply) => {
    const data = await request.file();
    if (!data) {
      return reply.status(400).send({ error: 'No file provided' });
    }

    const fileBuffer = await data.toBuffer();
    const key = `uploads/${Date.now()}-${data.filename}`;

    const command = new PutObjectCommand({
      Bucket: app.config.minioBucket,
      Key: key,
      Body: fileBuffer,
      ContentType: data.mimetype
    });

    await app.s3.send(command);

    return {
      url: `/storage/files/${key}`,
      key,
      filename: data.filename,
      mimetype: data.mimetype,
      size: fileBuffer.length
    };
  });

  // Get file (presigned URL or proxy)
  app.get('/files/:key*', {
    preHandler: [app.authenticate]
  }, async (request, reply) => {
    const { key } = request.params as { key: string };

    const command = new GetObjectCommand({
      Bucket: app.config.minioBucket,
      Key: key
    });

    try {
      const response = await app.s3.send(command);
      const stream = response.Body;


      reply.header('Content-Type', response.ContentType || 'application/octet-stream');
      return reply.send(stream);
    } catch (error) {
      return reply.status(404).send({ error: 'File not found' });
    }
  });

  // Delete file
  app.delete('/files/:key*', {
    preHandler: [app.authenticate]
  }, async (request, reply) => {
    const { key } = request.params as { key: string };
    // TODO: Implement delete with S3 client
    return { success: true, key };
  });
};

export { storageRoutes };
