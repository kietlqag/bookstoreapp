const { Pool } = require('pg');

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error('DATABASE_URL is not set.');
}

// Parse connection string to add SSL for Render.com databases
const poolConfig = {
  connectionString,
  // For Render.com and other cloud databases, SSL is usually required
  ssl: process.env.DATABASE_URL?.includes('render.com') || process.env.DATABASE_URL?.includes('supabase.co')
    ? { rejectUnauthorized: false } // Render.com uses self-signed certificates
    : undefined,
};

const pool = new Pool(poolConfig);

// Test connection on startup
pool.on('connect', () => {
  console.log('Database connected successfully');
});

pool.on('error', (err) => {
  console.error('Unexpected database error:', err);
});

module.exports = { pool };
