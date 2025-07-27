const crypto = require('crypto');
const secret = crypto.randomBytes(64).toString('hex');
console.log(secret);
// Example output: a2b4c6d8e0f2a4b6c8d0e2f4a6b8c0d2e4f6a8b0c2d4e6f8a0b2c4d6e8f0a2b4c8d0e2f4a6b8c0d2e4f6a8b0c2d4e6f8a0b2c4d6e8f0a2b4