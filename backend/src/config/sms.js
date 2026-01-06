const https = require('https');

function normalizeVietnamPhone(input) {
  const digits = String(input || '').replace(/[^\d+]/g, '');
  if (digits.startsWith('+84')) {
    return `84${digits.slice(3)}`;
  }
  if (digits.startsWith('84')) {
    return digits;
  }
  if (digits.startsWith('0')) {
    return `84${digits.slice(1)}`;
  }
  return digits;
}

function buildEsmsUrl({ phone, content, apiKey, secretKey, brandName, smsType }) {
  const params = new URLSearchParams({
    Phone: phone,
    Content: content,
    ApiKey: apiKey,
    SecretKey: secretKey,
    SmsType: String(smsType || 2),
  });
  if (brandName) {
    params.set('Brandname', brandName);
  }
  return `https://rest.esms.vn/MainService.svc/json/SendMultipleMessage_V4_get?${params.toString()}`;
}

function sendEsmsOtp({ phone, content, apiKey, secretKey, brandName, smsType }) {
  return new Promise((resolve, reject) => {
    const url = buildEsmsUrl({
      phone,
      content,
      apiKey,
      secretKey,
      brandName,
      smsType,
    });
    const req = https.get(url, (res) => {
      let body = '';
      res.on('data', (chunk) => {
        body += chunk;
      });
      res.on('end', () => {
        try {
          const parsed = JSON.parse(body || '{}');
          resolve({ status: res.statusCode, data: parsed });
        } catch (error) {
          reject(error);
        }
      });
    });
    req.on('error', reject);
  });
}

async function sendSmsOtp({ phone, code }) {
  const provider = (process.env.SMS_PROVIDER || '').trim().toLowerCase();
  if (!provider) {
    const error = new Error('SMS OTP is not configured.');
    error.status = 501;
    throw error;
  }
  if (provider !== 'esms') {
    const error = new Error('SMS provider is not supported.');
    error.status = 501;
    throw error;
  }

  const apiKey = process.env.ESMS_API_KEY;
  const secretKey = process.env.ESMS_SECRET_KEY;
  const brandName = process.env.ESMS_BRANDNAME || '';
  const smsType = process.env.ESMS_SMS_TYPE || 2;
  if (!apiKey || !secretKey) {
    const error = new Error('ESMS config is missing.');
    error.status = 500;
    throw error;
  }

  const content = `Ma xac thuc cua ban la ${code}. Hieu luc 10 phut.`;
  const normalizedPhone = normalizeVietnamPhone(phone);
  const debug = String(process.env.SMS_DEBUG || '') === '1';
  if (debug) {
    console.log('[SMS] ESMS request', {
      phone: normalizedPhone,
      smsType: String(smsType),
      hasBrandName: Boolean(brandName),
    });
  }
  const response = await sendEsmsOtp({
    phone: normalizedPhone,
    content,
    apiKey,
    secretKey,
    brandName,
    smsType,
  });
  if (debug) {
    console.log('[SMS] ESMS response', response);
  }
  const resultCode = Number(response.data?.CodeResult);
  if (resultCode !== 100) {
    const message = response.data?.ErrorMessage || 'SMS send failed.';
    const error = new Error(message);
    error.status = 502;
    throw error;
  }
  return response.data;
}

module.exports = { sendSmsOtp };
