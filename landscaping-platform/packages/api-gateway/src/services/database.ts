import type { Pool } from 'pg';

export interface QueryResult {
  rows: any[];
  rowCount: number;
}

export class DatabaseService {
  constructor(private pool: Pool) {}

  async query<T = any>(text: string, params?: any[]): Promise<QueryResult> {
    const result = await this.pool.query(text, params);
    return {
      rows: result.rows as T[],
      rowCount: result.rowCount ?? 0
    };
  }

  async getClient() {
    return this.pool.connect();
  }

  async transaction<T>(callback: (client: any) => Promise<T>): Promise<T> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');
      const result = await callback(client);
      await client.query('COMMIT');
      return result;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }
}
