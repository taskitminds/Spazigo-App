const mongoose = require('mongoose');

const documentSchema = new mongoose.Schema({
  user_id: {
    type: String, // Store as String to match PostgreSQL UUID
    required: [true, 'Document must belong to a user'],
    index: true, // Index for faster lookups by user_id
  },
  document_type: {
    type: String,
    required: [true, 'Document type is required'],
    enum: ['business_license', 'gst_certificate', 'registration_document', 'other'], // Example types
  },
  file_name: {
    type: String,
    required: [true, 'File name is required'],
  },
  mimetype: {
    type: String,
    required: [true, 'File mimetype is required'],
  },
  // For storing actual file content in MongoDB.
  // For small files, base64 is okay. For larger files, GridFS or external storage (S3/GCS) is better.
  // If using external storage, `file_path` would store the URL.
  file_path: { // This will store base64 string for now
    type: String,
    required: true,
  },
  uploaded_at: {
    type: Date,
    default: Date.now,
  },
});

const Document = mongoose.model('Document', documentSchema);

module.exports = Document;