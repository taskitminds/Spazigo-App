const multer = require('multer');
const AppError = require('../utils/appError');

// Configure Multer storage
// For now, storing in memory for processing (e.g., base64 encoding for MongoDB)
// For local file system, use `multer.diskStorage` and specify `destination`
const multerStorage = multer.memoryStorage();

// Filter files
const multerFilter = (req, file, cb) => {
  if (file.mimetype.startsWith('image') || file.mimetype === 'application/pdf') {
    cb(null, true);
  } else {
    cb(new AppError('Not an image or PDF! Please upload only images or PDFs.', 400), false);
  }
};

const upload = multer({
  storage: multerStorage,
  fileFilter: multerFilter,
  limits: {
    fileSize: 5 * 1024 * 1024 // 5 MB file size limit
  }
});

// Middleware for single file upload (e.g., registration document)
exports.uploadSingleDocument = upload.single('document');

// Middleware for multiple image uploads (e.g., product images, if needed)
exports.uploadProductImages = upload.array('images', 5); // Max 5 images

// Note: For actual storage, you'd typically send these to S3/GCS
// and store the resulting URL in your database.
// If saving to MongoDB documents collection, you'd convert to base64 from `req.file.buffer`
