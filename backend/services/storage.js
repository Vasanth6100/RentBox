const fs = require('fs');
const path = require('path');
const https = require('https');
require('dotenv').config();

// Determine local/volume uploads directory
const DEFAULT_UPLOADS_DIR = path.join(__dirname, '..', 'public', 'uploads');
const UPLOADS_DIR = process.env.UPLOADS_DIR || DEFAULT_UPLOADS_DIR;

if (!fs.existsSync(UPLOADS_DIR)) {
  fs.mkdirSync(UPLOADS_DIR, { recursive: true });
}

/**
 * Checks if Cloudinary credentials are fully configured.
 */
const isCloudinaryConfigured = () => {
  return Boolean(
    process.env.CLOUDINARY_URL ||
    (process.env.CLOUDINARY_CLOUD_NAME && process.env.CLOUDINARY_API_KEY && process.env.CLOUDINARY_API_SECRET)
  );
};

/**
 * Uploads a base64 or buffer image directly to Cloudinary via HTTPS REST API.
 */
const uploadToCloudinary = async (base64Data, filename) => {
  let cloudName = process.env.CLOUDINARY_CLOUD_NAME;
  let apiKey = process.env.CLOUDINARY_API_KEY;
  let apiSecret = process.env.CLOUDINARY_API_SECRET;

  if (process.env.CLOUDINARY_URL) {
    try {
      const parsed = new URL(process.env.CLOUDINARY_URL);
      apiKey = parsed.username;
      apiSecret = parsed.password;
      cloudName = parsed.hostname;
    } catch (_) {}
  }

  if (!cloudName || !apiKey || !apiSecret) {
    throw new Error('Incomplete Cloudinary credentials.');
  }

  const crypto = require('crypto');
  const timestamp = Math.floor(Date.now() / 1000);
  const folder = process.env.CLOUDINARY_FOLDER || 'rentbox_uploads';
  const publicId = (filename ? path.parse(filename).name : 'img')
    .replace(/[^a-zA-Z0-9_-]/g, '_')
    .substring(0, 30) + `_${Date.now()}`;

  // Signature calculation: sha1(folder=...&public_id=...&timestamp=...<apiSecret>)
  const paramString = `folder=${folder}&public_id=${publicId}&timestamp=${timestamp}${apiSecret}`;
  const signature = crypto.createHash('sha1').update(paramString).digest('hex');

  const postData = JSON.stringify({
    file: base64Data.startsWith('data:') ? base64Data : `data:image/jpeg;base64,${base64Data}`,
    api_key: apiKey,
    timestamp: timestamp,
    public_id: publicId,
    folder: folder,
    signature: signature
  });

  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'api.cloudinary.com',
      port: 443,
      path: `/v1_1/${cloudName}/image/upload`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    };

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', (d) => { body += d; });
      res.on('end', () => {
        try {
          const parsed = JSON.parse(body);
          if (res.statusCode >= 200 && res.statusCode < 300 && parsed.secure_url) {
            resolve({
              url: parsed.secure_url,
              fullUrl: parsed.secure_url,
              provider: 'cloudinary',
              publicId: parsed.public_id,
              bytes: parsed.bytes
            });
          } else {
            reject(new Error(parsed.error?.message || `Cloudinary upload failed (status ${res.statusCode})`));
          }
        } catch (e) {
          reject(e);
        }
      });
    });

    req.on('error', (e) => reject(e));
    req.write(postData);
    req.end();
  });
};

/**
 * Saves an uploaded image:
 * - If Cloudinary is configured, uploads directly to Cloudinary CDN
 * - Otherwise saves to local/persistent disk storage and returns accessible URL
 */
const saveImage = async ({ rawData, filename, req }) => {
  if (!rawData) {
    throw new Error('No image data provided.');
  }

  // 1. Production Cloudinary Storage if configured
  if (isCloudinaryConfigured()) {
    try {
      console.log('[RentBox Storage] Uploading to Cloudinary CDN...');
      return await uploadToCloudinary(rawData, filename);
    } catch (cloudErr) {
      console.warn('[RentBox Storage] Cloudinary upload failed, falling back to disk:', cloudErr.message);
    }
  }

  // 2. Persistent volume / Local disk fallback
  let buffer;
  let ext = 'jpg';

  const dataUriMatch = rawData.match(/^data:image\/([a-zA-Z0-9+]+);base64,(.+)$/);
  if (dataUriMatch) {
    ext = dataUriMatch[1].replace('jpeg', 'jpg');
    buffer = Buffer.from(dataUriMatch[2], 'base64');
  } else {
    buffer = Buffer.from(rawData, 'base64');
  }

  const safeBase = (filename ? path.parse(filename).name : 'img')
    .replace(/[^a-zA-Z0-9_-]/g, '_')
    .substring(0, 30);
  const uniqueName = `${safeBase}_${Date.now()}_${Math.random().toString(36).substring(2, 7)}.${ext}`;
  const targetPath = path.join(UPLOADS_DIR, uniqueName);

  fs.writeFileSync(targetPath, buffer);

  const relativeUrl = `/uploads/${uniqueName}`;
  const protocol = (req && req.protocol === 'https') || process.env.NODE_ENV === 'production' ? 'https' : (req?.protocol || 'http');
  const host = req?.get('host') || process.env.PUBLIC_DOMAIN || 'localhost:5000';
  const fullUrl = `${protocol}://${host}${relativeUrl}`;

  console.log(`[RentBox Storage] Saved file locally: ${uniqueName} (${buffer.length} bytes)`);

  return {
    url: relativeUrl,
    fullUrl: fullUrl,
    filename: uniqueName,
    sizeBytes: buffer.length,
    provider: 'local_disk'
  };
};

module.exports = {
  saveImage,
  UPLOADS_DIR,
  isCloudinaryConfigured
};
