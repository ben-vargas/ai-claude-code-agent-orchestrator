import Database from 'better-sqlite3';
import { join } from 'path';
import { existsSync, mkdirSync } from 'fs';
import { config } from '../config';
import { logger } from '../index';

let db: Database.Database;

export async function initializeDatabase(): Promise<void> {
  const dbDir = join(config.database.path, '..');
  
  if (!existsSync(dbDir)) {
    mkdirSync(dbDir, { recursive: true });
  }

  db = new Database(config.database.path, {
    verbose: config.database.verbose ? logger.info : undefined
  });

  if (config.database.walMode) {
    db.pragma('journal_mode = WAL');
  }

  db.pragma('foreign_keys = ON');

  await runMigrations();
}

export function getDb(): Database.Database {
  if (!db) {
    throw new Error('Database not initialized. Call initializeDatabase() first.');
  }
  return db;
}

async function runMigrations(): Promise<void> {
  const db = getDb();
  
  db.exec(`
    CREATE TABLE IF NOT EXISTS migrations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);

  const migrationFiles = [
    '001_initial_schema.sql',
    '002_add_indexes.sql'
  ];

  const appliedMigrations = db.prepare('SELECT name FROM migrations').all() as { name: string }[];
  const appliedNames = new Set(appliedMigrations.map(m => m.name));

  for (const migrationFile of migrationFiles) {
    if (!appliedNames.has(migrationFile)) {
      logger.info(`Running migration: ${migrationFile}`);
      
      try {
        const migrationPath = join(__dirname, 'migrations', migrationFile);
        const migrationSql = require('fs').readFileSync(migrationPath, 'utf8');
        
        db.exec(migrationSql);
        
        db.prepare('INSERT INTO migrations (name) VALUES (?)').run(migrationFile);
        
        logger.info(`Migration ${migrationFile} completed`);
      } catch (error) {
        logger.error(`Migration ${migrationFile} failed:`, error);
        throw error;
      }
    }
  }
}

export function closeDatabase(): void {
  if (db) {
    db.close();
  }
}