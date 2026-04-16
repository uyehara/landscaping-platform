import { Server } from '@hocuspocus/server';
import { Database } from '@hocuspocus/provider-database';
import { Pool } from '@hocuspocus/server';

const PORT = parseInt(process.env.PORT || '1234');
const DB_TYPE = process.env.DB_TYPE || 'memory';

const configuration = {
    port: PORT,
    name: 'landscaping-collaboration',

    async onConnect(data: { context: any }) {
        console.log(`Client connected: ${data?.context?.user?.name || 'anonymous'}`);
    },
    async onDisconnect(data: { context: any }) {
        console.log(`Client disconnected: ${data?.context?.user?.name || 'anonymous'}`);
    },
    async onAuthenticate(data: { token: string }) {
        // TODO: Validate JWT token from Auth.js session
        // For MVP, accept all connections
        if (!data.token) {
            throw new Error('No token provided');
        }
        return {
            user: {
                name: 'Anonymous User',
                // Parse JWT payload here in production
            }
        };
    }
};

// Add database persistence for production (Postgres)
if (DB_TYPE === 'database') {
    const dbUrl = process.env.DB_URL || 'postgres://landscape:postgres@localhost:5432/landscaping';
    
    const pool = new Pool({
        connectionString: dbUrl,
        max: 10,
        idleTimeoutMillis: 30000,
        connectionTimeoutMillis: 2000,
    });

    // @ts-ignore - Custom extension for database provider
    Server.configure({
        async onStoreDocument(data: { document: any, documentName: string }) {
            const client = await pool.connect();
            try {
                await client.query(`
                    INSERT INTO yjs_documents (name, content, updated_at)
                    VALUES ($1, $2, NOW())
                    ON CONFLICT (name) DO UPDATE SET
                        content = $2,
                        updated_at = NOW()
                `, [data.documentName, Buffer.from(data.document)]);
            } finally {
                client.release();
            }
        },
        async onLoadDocument(data: { documentName: string }) {
            const client = await pool.connect();
            try {
                const result = await client.query(
                    'SELECT content FROM yjs_documents WHERE name = $1',
                    [data.documentName]
                );
                return result.rows[0]?.content || null;
            } finally {
                client.release();
            }
        }
    });
}

// Start server
const server = Server.configure(configuration);

server.listen().then(() => {
    console.log(`Collaboration server running on port ${PORT}`);
    console.log(`Persistence: ${DB_TYPE === 'memory' ? 'In-memory (MVP)' : 'PostgreSQL'}`);
});

// Graceful shutdown
process.on('SIGINT', async () => {
    await server.destroy();
    process.exit(0);
});
