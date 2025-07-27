// Filename: spazigo-backend/models/pg/containerModel.js
// This file describes the PostgreSQL schema for the 'containers' table.
// The application uses direct 'pg' queries via pgPool, not a Sequelize ORM instance.

const containerSchema = {
  id: {
    type: 'UUID',
    defaultValue: 'UUIDV4', // Typically handled by database default or query logic
    primaryKey: true,
  },
  lsp_id: {
    type: 'UUID',
    allowNull: false,
    references: {
      model: 'users',
      key: 'id',
    },
    onDelete: 'CASCADE',
  },
  origin: {
    type: 'VARCHAR(255)',
    allowNull: false,
  },
  destination: {
    type: 'VARCHAR(255)',
    allowNull: false,
  },
  routes: {
    type: 'TEXT[]', // PostgreSQL Array of Text
    allowNull: true,
  },
  space_total: {
    type: 'DECIMAL',
    allowNull: false,
  },
  space_left: {
    type: 'DECIMAL',
    allowNull: false,
  },
  price: {
    type: 'DECIMAL',
    allowNull: false,
  },
  modal: {
    type: "ENUM('road', 'rail', 'sea', 'air')",
    allowNull: false,
  },
  deadline: {
    type: 'TIMESTAMP WITH TIME ZONE', // Corrected from DATE to a more precise timestamp type for PostgreSQL
    allowNull: false,
  },
  departure_time: {
    type: 'TIMESTAMP WITH TIME ZONE', // Corrected from DATE to a more precise timestamp type for PostgreSQL
    allowNull: false,
  },
  status: {
    type: "ENUM('active', 'expired', 'full')",
    defaultValue: 'active',
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

// For reference, the table name is 'containers'
const tableName = 'containers';

// Indexes (for reference)
const indexes = [
  {
    fields: ['lsp_id'],
    name: 'idx_containers_lsp_id',
  },
  {
    fields: ['origin', 'destination'],
    name: 'idx_containers_origin_destination',
  },
  {
    fields: ['status', 'deadline'],
    name: 'idx_containers_status_deadline',
  },
];

// Exporting for documentation or external tooling.
// This object is not used by the current application logic which uses raw pgPool queries.
module.exports = {
  tableName,
  schema: containerSchema,
  indexes,
};