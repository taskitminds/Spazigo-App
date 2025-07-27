// Filename: spazigo-backend/models/pg/bookingModel.js
// This file describes the PostgreSQL schema for the 'bookings' table.
// The application uses direct 'pg' queries via pgPool, not a Sequelize ORM instance.

const bookingSchema = {
  id: {
    type: 'UUID',
    defaultValue: 'UUIDV4', // Typically handled by database default or query logic
    primaryKey: true,
  },
  container_id: {
    type: 'UUID',
    allowNull: false,
    references: {
      model: 'containers',
      key: 'id',
    },
    onDelete: 'CASCADE',
  },
  msme_id: {
    type: 'UUID',
    allowNull: false,
    references: {
      model: 'users',
      key: 'id',
    },
    onDelete: 'CASCADE',
  },
  product_name: {
    type: 'VARCHAR(255)',
    allowNull: false,
  },
  category: {
    type: 'VARCHAR(255)',
  },
  weight: {
    type: 'DECIMAL',
    allowNull: false,
  },
  image_url: {
    type: 'TEXT',
  },
  status: {
    type: "ENUM('pending', 'accepted', 'rejected', 'cancelled')",
    defaultValue: 'pending',
  },
  rejection_reason: {
    type: 'TEXT',
  },
  payment_status: {
    type: "ENUM('pending', 'paid', 'failed')",
    defaultValue: 'pending',
  },
  razorpay_order_id: {
    type: 'VARCHAR(255)',
  },
  razorpay_payment_id: {
    type: 'VARCHAR(255)',
  },
  created_at: {
    type: 'TIMESTAMP WITH TIME ZONE', // Corrected from DATE to a more precise timestamp type for PostgreSQL
    defaultValue: 'NOW()', // Typically handled by database default
  },
  updated_at: {
    type: 'TIMESTAMP WITH TIME ZONE', // Corrected from DATE to a more precise timestamp type for PostgreSQL
    defaultValue: 'NOW()', // Typically handled by database default
  },
};

// For reference, the table name is 'bookings'
const tableName = 'bookings';

// Indexes (for reference)
const indexes = [
  {
    fields: ['container_id'],
    name: 'idx_bookings_container_id',
  },
  {
    fields: ['msme_id'],
    name: 'idx_bookings_msme_id',
  },
  {
    fields: ['status', 'payment_status'],
    name: 'idx_bookings_status_payment',
  },
];

const uniqueKeys = {
  unique_booking: {
    fields: ['container_id', 'msme_id', 'product_name'],
  },
};

// Exporting for documentation or external tooling.
// This object is not used by the current application logic which uses raw pgPool queries.
module.exports = {
  tableName,
  schema: bookingSchema,
  indexes,
  uniqueKeys
};