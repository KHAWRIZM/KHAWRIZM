const express = require('express');
const path = require('path');

const app = express();
const port = process.env.PORT || 8080;

app.get('/healthz', (_req, res) => res.status(200).send('ok'));
app.use(express.static(path.join(__dirname, 'dist')));
app.get('*', (_req, res) => res.sendFile(path.join(__dirname, 'dist', 'index.html')));

app.listen(port, () => console.log('Server up on ' + port));
