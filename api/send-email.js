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

module.exports = async (req, res) => {
  // CORS configuration
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader('Access-Control-Allow-Headers', 'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed. Use POST.' });
  }

  try {
    const { to, subject, html } = req.body || {};

    if (!to || !subject || !html) {
      return res.status(400).json({ error: 'Missing required parameters: to, subject, html' });
    }

    const mailOptions = {
      from: 'Piggy Trunk Support <piggytrunk@gmail.com>',
      to,
      subject,
      html,
    };

    const info = await transporter.sendMail(mailOptions);
    console.log('Email sent successfully via Gmail SMTP on Vercel:', info.messageId);

    return res.status(200).json({
      success: true,
      message: 'Email delivered successfully',
      messageId: info.messageId,
    });
  } catch (error) {
    console.error('Error sending email on Vercel:', error);
    return res.status(500).json({
      success: false,
      error: error.message || 'Internal server error while sending email',
    });
  }
};
