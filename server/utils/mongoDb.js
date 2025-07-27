// Filename: spazigo-backend/utils/mongoDb.js
const mongoose = require('mongoose');

const connectMongoDB = () => {
  mongoose.connect(process.env.MONGO_URI, {
    // useNewUrlParser: true, // Deprecated in Mongoose 6+ and removed
    // useUnifiedTopology: true, // Deprecated in Mongoose 6+ and removed
  })
    .then(() => console.log('MongoDB connected successfully!'))
    .catch(err => {
      console.error('MongoDB connection error:', err);
      process.exit(1); // Exit process with failure
    });
};

module.exports = connectMongoDB;