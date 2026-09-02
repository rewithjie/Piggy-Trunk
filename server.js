const http = require('http');
const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: 'smtp.gmail.com',
  port: 465,
  secure: true,
  auth: {
    user: process.env.GMAIL_USER || 'piggytrunk@gmail.com',
    pass: process.env.GMAIL_APP_PASSWORD || 'nuicsizzrnmhnuva',
  },
});

const server = http.createServer(async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  if (req.method === 'POST') {
    let body = '';
    req.on('data', chunk => {
      body += chunk;
    });
    req.on('end', async () => {
      try {
        const { to, subject, html } = JSON.parse(body || '{}');
        if (!to || !subject || !html) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'Missing to, subject, or html' }));
          return;
        }

        const info = await transporter.sendMail({
          from: 'Piggy Trunk Support <piggytrunk@gmail.com>',
          to,
          subject,
          html,
        });

        console.log(`[Piggy Trunk Local SMTP Bridge] Email successfully sent to ${to}: ${info.messageId}`);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: true, messageId: info.messageId }));
      } catch (err) {
        console.error('[Piggy Trunk Local SMTP Bridge Error]', err);
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: false, error: err.message }));
      }
    });
  } else {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('Piggy Trunk SMTP Bridge is running.');
  }
});

const PORT = 3001;
server.listen(PORT, () => {
  console.log(`Piggy Trunk SMTP Bridge running on http://localhost:${PORT}`);
});
