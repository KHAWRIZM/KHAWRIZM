const express = require('express');
const app = express();
app.get('/', (req, res) => res.send('🚀 CometX is alive (ACA + ACR)'));
const port = process.env.PORT || 8080;
app.listen(port, () => console.log('CometX listening on ' + port));
