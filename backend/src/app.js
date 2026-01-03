const express = require('express');
const cors = require('cors');

const routes = require('./routes');
const { errorHandler } = require('./middleware/error-handler');

function createApp() {
  const app = express();

  app.use(cors());
  app.use(express.json());
  app.use((req, _res, next) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.originalUrl}`);
    next();
  });

  app.use('/api', routes);

  app.use(errorHandler);

  return app;
}

module.exports = { createApp };
