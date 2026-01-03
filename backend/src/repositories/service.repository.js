const { pool } = require('../config/db');

function listServices() {
  return pool
    .query('SELECT * FROM "Service"')
    .then((result) => result.rows);
}

module.exports = { listServices };
