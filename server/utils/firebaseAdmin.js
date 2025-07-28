// Filename: spazigo-backend/utils/firebaseAdmin.js
const admin = require('firebase-admin');

let firebaseApp;

const initFirebaseAdmin = () => {
  try {
    const serviceAccountBase64 = process.env.FIREBASE_CONFIG_BASE64;
    if (!serviceAccountBase64) {
      throw new Error('FIREBASE_CONFIG_BASE64 environment variable not found.');
    }

    // Decode the base64 string using 'utf8' for correct character handling.
    const serviceAccountJson = Buffer.from(serviceAccountBase64, 'base64').toString('utf8');
    const serviceAccount = JSON.parse(serviceAccountJson);

    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    console.log('Firebase Admin SDK initialized successfully from environment variable!');

  } catch (error) {
    console.error('CRITICAL: Error initializing Firebase Admin SDK:', error.message);
  }
};

const sendPushNotification = async (fcmToken, title, body, data = {}) => {
  if (!firebaseApp) {
    console.error('Firebase Admin SDK not initialized. Cannot send push notification.');
    return;
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
    data: {
      ...Object.fromEntries(Object.entries(data).map(([key, value]) => [key, String(value)])),
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },
    token: fcmToken,
  };

  try {
    const response = await admin.messaging().send(message);
  } catch (error) {
    console.error('Error sending FCM message:', error);
    if (error.code === 'messaging/registration-token-not-registered') {
        console.warn(`FCM token ${fcmToken} is invalid or has expired.`);
    }
  }
};

module.exports = { initFirebaseAdmin, sendPushNotification };