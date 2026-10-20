/**
 * RentBox Root Server Launcher
 * Forwards execution to backend/server.js so running `node server.js` from the
 * project root directory works smoothly.
 */
const path = require('path');

const backendDir = path.join(__dirname, 'backend');
process.chdir(backendDir);
require(path.join(backendDir, 'server.js'));
