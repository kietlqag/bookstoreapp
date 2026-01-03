require('dotenv').config();

const { createApp } = require('./app');

const PORT = Number(process.env.PORT || 8080);

const app = createApp();

app.listen(PORT, () => {
  console.log(`Backend listening on port ${PORT}`);
});
