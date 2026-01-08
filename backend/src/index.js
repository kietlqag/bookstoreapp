require('dotenv').config();

const { createApp } = require('./app');
const { pool } = require('./config/db');

const PORT = Number(process.env.PORT || 8080);

// Test database connection on startup
async function testDatabaseConnection() {
  try {
    const result = await pool.query('SELECT NOW() as current_time, current_database() as db_name');
    console.log('✅ Database connected successfully');
    console.log(`   Database: ${result.rows[0].db_name}`);
    console.log(`   Server time: ${result.rows[0].current_time}`);
    return true;
  } catch (error) {
    console.error('❌ Database connection failed:', error.message);
    return false;
  }
}

const app = createApp();

// Test connection before starting server
testDatabaseConnection().then((connected) => {
  if (connected) {
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`✅ Backend listening on port ${PORT}`);
    });
  } else {
    console.error('⚠️  Server not started due to database connection failure');
    process.exit(1);
  }
});
