// Filename: spazigo-backend/utils/firebaseAdmin.js
const admin = require('firebase-admin');
const AppError = require('./appError');
const path = require('path'); // Added for path resolution
const fs = require('fs');     // Added for file system operations

let firebaseApp;

const initFirebaseAdmin = () => {
  try {
    const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_KEY_PATH;
    if (!serviceAccountPath) {
      throw new Error('FIREBASE_SERVICE_ACCOUNT_KEY_PATH not defined in .env');
    }

    // Resolve the path correctly for cross-platform compatibility
    const absolutePath = path.resolve(process.cwd(), serviceAccountPath);
    const serviceAccount = JSON.parse(fs.readFileSync(absolutePath, 'utf8'));

    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    console.log('Firebase Admin SDK initialized!');
  } catch (error) {
    console.error('Error initializing Firebase Admin SDK:', error.message);
    // IMPORTANT: For production, if Firebase is critical, you might want to
    // throw an AppError here to prevent the server from starting.
    // e.g., throw new AppError(`Firebase initialization failed: ${error.message}`, 500);
  }
};

const sendPushNotification = async (fcmToken, title, body, data = {}) => {
  if (!firebaseApp) {
    console.error('Firebase Admin SDK not initialized. Cannot send push notification.');
    return; // Or throw new AppError(...)
  }
  if (!fcmToken) {
    console.warn('No FCM token provided for notification. Skipping.');
    return;
  }

  const message = {
    notification: {
      title,
      body,
    },
    data: { // Data payload must be strings
      ...Object.fromEntries(Object.entries(data).map(([key, value]) => [key, String(value)])),
      click_action: 'FLUTTER_NOTIFICATION_CLICK', // Standard for Flutter
    },
    token: fcmToken,
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('Successfully sent FCM message:', response);
  } catch (error) {
    console.error('Error sending FCM message:', error);
    if (error.code === 'messaging/invalid-argument' || error.code === 'messaging/registration-token-not-registered') {
        console.warn(`FCM token ${fcmToken} might be invalid or expired.`);
    }
  }
};

module.exports = { initFirebaseAdmin, sendPushNotification };