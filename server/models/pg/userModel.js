// Filename: spazigo-backend/models/pg/userModel.js
// This file describes the PostgreSQL schema for the 'users' table.
// The application uses direct 'pg' queries via pgPool, not a Sequelize ORM instance.

const userSchema = {
  id: {
    type: 'UUID',
    defaultValue: 'UUIDV4', // Typically handled by database default or query logic
    primaryKey: true,
  },
  role: {
    type: "ENUM('lsp', 'msme', 'admin')",
    allowNull: false,
  },
  email: {
    type: 'VARCHAR(255)',
    unique: true,
    allowNull: false,
  },
  password: {
    type: 'VARCHAR(255)',
    allowNull: false,
  },
  company: {
    type: 'VARCHAR(255)',
    allowNull: false,
  },
  phone: {
    type: 'VARCHAR(20)',
    allowNull: false,
  },
  status: {
    type: "ENUM('pending', 'verified', 'rejected')",
    defaultValue: 'pending',
  },
  rejection_reason: {
    type: 'TEXT',
  },
  fcm_token: {
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

// For reference, the table name is 'users'
const tableName = 'users';

// Indexes (for reference)
const indexes = [
  {
    fields: ['email'],
    name: 'idx_users_email',
  },
];

// Exporting for documentation or external tooling.
// This object is not used by the current application logic which uses raw pgPool queries.
module.exports = {
  tableName,
  schema: userSchema,
  indexes,
};