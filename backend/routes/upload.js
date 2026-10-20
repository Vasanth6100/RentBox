const express = require('express');
const { saveImage } = require('../services/storage');

const router = express.Router();

// -------------------------------------------------------------
// POST /api/upload
// Accepts Base64 encoded image or data URI
// Uploads to Cloudinary (production) or local/persistent storage
// -------------------------------------------------------------
router.post('/', async (req, res) => {
  try {
    const { image, base64, filename } = req.body;
    const rawData = image || base64;

    if (!rawData) {
      return res.status(400).json({ success: false, error: 'No image data provided.' });
    }

    const result = await saveImage({
      rawData,
      filename,
      req
    });

    res.json({
      success: true,
      url: result.url,
      fullUrl: result.fullUrl,
      filename: result.filename,
      provider: result.provider,
      sizeBytes: result.sizeBytes || result.bytes
    });
  } catch (err) {
    console.error('[RentBox Upload] Error saving uploaded image:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
