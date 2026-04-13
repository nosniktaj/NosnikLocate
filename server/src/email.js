const nodemailer = require('nodemailer');
const crypto = require('crypto');

/**
 * Create the SMTP transporter from environment variables.
 *
 * For Proton Mail users:
 *   1. Install and run Proton Mail Bridge on your server.
 *   2. Set SMTP_HOST=127.0.0.1, SMTP_PORT=1025 (Bridge SMTP port).
 *   3. Set SMTP_USER and SMTP_PASS to your Bridge credentials
 *      (shown in Bridge under your account → Mailbox configuration).
 *   4. Set SMTP_SECURE=false (Bridge handles encryption locally).
 *   5. Set SMTP_FROM to your desired sender address.
 */
const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || '127.0.0.1',
  port: parseInt(process.env.SMTP_PORT, 10) || 1025,
  secure: process.env.SMTP_SECURE === 'true',
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
  // Proton Mail Bridge uses a self-signed certificate
  tls: {
    rejectUnauthorized: false,
  },
});

/**
 * Generate a random 6-digit verification code.
 */
function generateVerificationCode() {
  return crypto.randomInt(100000, 1000000).toString();
}

/**
 * Send a verification email with the given code.
 *
 * @param {string} to - Recipient email address.
 * @param {string} code - 6-digit verification code.
 * @returns {Promise}
 */
async function sendVerificationEmail(to, code) {
  const from = process.env.SMTP_FROM || 'NosnikLocate <noreply@nosniktaj.com>';

  const mailOptions = {
    from,
    to,
    subject: 'NosnikLocate – Verify Your Email',
    text: `Your NosnikLocate verification code is: ${code}\n\nThis code expires in 15 minutes.\n\nIf you did not create an account, please ignore this email.`,
    html: `
      <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 480px; margin: 0 auto; padding: 32px; background: #1A1A2E; color: #FFFFFF; border-radius: 16px;">
        <h1 style="color: #BB86FC; text-align: center; margin-bottom: 8px;">NosnikLocate</h1>
        <p style="text-align: center; color: #B0B0B0; margin-bottom: 24px;">Verify your email address</p>
        <div style="background: #16213E; border: 1px solid #333355; border-radius: 12px; padding: 24px; text-align: center; margin-bottom: 24px;">
          <p style="color: #B0B0B0; margin: 0 0 12px 0;">Your verification code is:</p>
          <p style="font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #BB86FC; margin: 0;">${code}</p>
        </div>
        <p style="color: #B0B0B0; font-size: 13px; text-align: center;">This code expires in 15 minutes.</p>
        <p style="color: #666688; font-size: 12px; text-align: center; margin-top: 24px;">If you did not create an account, please ignore this email.</p>
      </div>
    `,
  };

  return transporter.sendMail(mailOptions);
}

module.exports = {
  generateVerificationCode,
  sendVerificationEmail,
};
