const express = require('express');
const path = require('path');
const app = express();
const port = process.env.PORT || 80;

// Serve static files from public directory
app.use(express.static(path.join(__dirname, 'public')));

// Basic health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});

// Readiness probe endpoint
app.get('/ready', (req, res) => {
  res.status(200).json({ status: 'ready' });
});

// Main application endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Welcome to the sample application',
    timestamp: new Date(),
    version: '1.0.0',
    kubernetes: {
      pod: process.env.HOSTNAME || 'local-dev',
      namespace: process.env.NAMESPACE || 'default'
    }
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
