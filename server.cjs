const express = require('express');
const path = require('path');

const app = express();
const port = process.env.PORT || 8080;

// Health check endpoint
app.get('/healthz', (_req, res) => res.status(200).send('ok'));

// Serve static files from dist (includes index.html)
app.use(express.static(path.join(__dirname, 'dist')));

app.listen(port, () => console.log('Server up on ' + port));
