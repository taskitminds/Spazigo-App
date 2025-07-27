const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.PG_URL,
  ssl: process.env.PG_SSL === 'true' ? { rejectUnauthorized: false } : false,
});

module.exports = pool;
