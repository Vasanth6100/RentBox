const express = require('express');
const fs = require('fs');
const path = require('path');

const router = express.Router();
const versionFilePath = path.join(__dirname, '..', 'data', 'app_version.json');

// Default version config
const defaultVersionInfo = {
  version: '1.0.1',
  versionCode: 2,
  minVersion: '1.0.0',
  apkUrl: '/rentbox.apk',
  releaseNotes: [
    'Performance improvements and faster loading',
    'Bug fixes and enhanced stability',
    'Automatic update notification system'
  ],
  forceUpdate: false,
  publishedAt: new Date().toISOString()
};

function getVersionInfo() {
  try {
    if (fs.existsSync(versionFilePath)) {
      const data = fs.readFileSync(versionFilePath, 'utf8');
      return { ...defaultVersionInfo, ...JSON.parse(data) };
    }
  } catch (err) {
    console.error('Error reading app_version.json:', err.message);
  }
  return defaultVersionInfo;
}

// GET /api/app/version
router.get('/version', (req, res) => {
  try {
    const info = getVersionInfo();
    // Resolve absolute URL if apkUrl is a relative path
    const host = req.get('host');
    const protocol = req.protocol === 'https' || req.headers['x-forwarded-proto'] === 'https' ? 'https' : 'http';
    const downloadUrl = info.apkUrl.startsWith('http') 
      ? info.apkUrl 
      : `${protocol}://${host}${info.apkUrl.startsWith('/') ? '' : '/'}${info.apkUrl}`;

    res.json({
      success: true,
      ...info,
      downloadUrl
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// POST /api/app/version (Update latest version)
router.post('/version', (req, res) => {
  try {
    const { version, versionCode, minVersion, apkUrl, releaseNotes, forceUpdate } = req.body;
    const current = getVersionInfo();
    
    const updated = {
      ...current,
      ...(version && { version }),
      ...(versionCode && { versionCode: Number(versionCode) }),
      ...(minVersion && { minVersion }),
      ...(apkUrl && { apkUrl }),
      ...(releaseNotes && { releaseNotes: Array.isArray(releaseNotes) ? releaseNotes : [releaseNotes] }),
      ...(typeof forceUpdate === 'boolean' && { forceUpdate }),
      publishedAt: new Date().toISOString()
    };

    const dir = path.dirname(versionFilePath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    fs.writeFileSync(versionFilePath, JSON.stringify(updated, null, 2), 'utf8');

    res.json({ success: true, message: 'App version updated successfully', data: updated });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
