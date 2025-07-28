// Filename: spazigo-backend/utils/mongoDb.js
const mongoose = require('mongoose');
// Import your Mongoose models here to ensure they are registered
require('../models/mongo/documentModel');

const connectMongoDB = () => {
  mongoose.connect(process.env.MONGO_URI, {})
    .then(() => {
        console.log('MongoDB connected successfully!');
        // Mongoose will ensure collections are created based on the imported models
        // when the first document is inserted.
        console.log('Mongoose models registered. Collections will be created on first data write.');
    })
    .catch(err => {
      console.error('MongoDB connection error:', err);
      process.exit(1); // Exit process with failure
    });
};

module.exports = connectMongoDB;