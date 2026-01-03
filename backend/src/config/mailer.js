const nodemailer = require('nodemailer');

function createTransport() {
  const host = process.env.SMTP_HOST;
  const port = Number(process.env.SMTP_PORT || 587);
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;
  const secure = String(process.env.SMTP_SECURE || 'false') === 'true';

  if (!host || !user || !pass) {
    return null;
  }

  return nodemailer.createTransport({
    host,
    port,
    secure,
    auth: { user, pass },
  });
}

async function sendOtpEmail({ to, code }) {
  const transport = createTransport();
  if (!transport) {
    const error = new Error('SMTP is not configured.');
    error.status = 500;
    throw error;
  }

  const from = process.env.SMTP_FROM || process.env.SMTP_USER;
  const subject = 'K-Book verification code';
  const text = [
    'K-Book Verification Code',
    '',
    `Your OTP code is: ${code}`,
    'This code expires in 10 minutes.',
    '',
    'If you did not request this, please ignore this email.',
  ].join('\n');
  const html = `
    <div style="font-family: Arial, Helvetica, sans-serif; background:#f6f7fb; padding:24px;">
      <div style="max-width:560px; margin:0 auto; background:#ffffff; border-radius:16px; padding:28px; box-shadow:0 12px 30px rgba(15,23,42,0.08);">
        <h2 style="margin:0 0 12px; color:#111827;">K-Book Verification</h2>
        <p style="margin:0 0 16px; color:#4b5563;">Use the code below to verify your email address.</p>
        <div style="text-align:center; margin:20px 0;">
          <span style="display:inline-block; font-size:28px; letter-spacing:6px; font-weight:700; color:#ea580c; background:#fff7ed; padding:12px 20px; border-radius:12px;">${code}</span>
        </div>
        <p style="margin:0 0 16px; color:#6b7280;">This code expires in 10 minutes.</p>
        <div style="height:1px; background:#e5e7eb; margin:20px 0;"></div>
        <p style="margin:0; color:#9ca3af; font-size:12px;">
          If you did not request this, you can safely ignore this email.
        </p>
      </div>
      <p style="text-align:center; color:#9ca3af; font-size:12px; margin-top:16px;">K-Book Team</p>
    </div>
  `;
  await transport.sendMail({
    from,
    to,
    subject,
    text,
    html,
  });
}

module.exports = { sendOtpEmail };
