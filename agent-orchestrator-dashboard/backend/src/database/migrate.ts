import Database from 'better-sqlite3';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Database path - using the existing orchestrator database
const DB_PATH = process.env.DB_PATH || path.join(
  process.env.HOME || '', 
  '.claude', 
  'orchestrator.db'
);

// Ensure directory exists
const dbDir = path.dirname(DB_PATH);
if (!fs.existsSync(dbDir)) {
  fs.mkdirSync(dbDir, { recursive: true });
}

// Initialize database
const db = new Database(DB_PATH);
db.pragma('journal_mode = WAL');

// Read and execute schema
const schemaPath = path.join(__dirname, 'schema.sql');
const schema = fs.readFileSync(schemaPath, 'utf-8');

// Split schema into individual statements
const statements = schema
  .split(';')
  .map(s => s.trim())
  .filter(s => s.length > 0);

console.log('🔄 Starting database migration...');
console.log(`📁 Database path: ${DB_PATH}`);

try {
  // Execute each statement
  for (const statement of statements) {
    if (statement) {
      db.exec(statement);
    }
  }
  
  // Verify tables were created
  const tables = db.prepare(`
    SELECT name FROM sqlite_master 
    WHERE type='table' 
    ORDER BY name
  `).all();
  
  console.log('\n✅ Migration completed successfully!');
  console.log('📊 Created tables:');
  tables.forEach(table => {
    console.log(`   - ${table.name}`);
  });
  
  // Get table counts
  console.log('\n📈 Table statistics:');
  for (const table of tables) {
    const count = db.prepare(`SELECT COUNT(*) as count FROM ${table.name}`).get();
    console.log(`   - ${table.name}: ${count.count} rows`);
  }
  
} catch (error) {
  console.error('❌ Migration failed:', error);
  process.exit(1);
} finally {
  db.close();
}

console.log('\n✨ Database is ready for use!');