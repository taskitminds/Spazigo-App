// Filename: spazigo-backend/models/pg/messageModel.js
// This file describes the PostgreSQL schema for the 'messages' table.
// The application uses direct 'pg' queries via pgPool, not a Sequelize ORM instance.

const messageSchema = {
  id: {
    type: 'UUID',
    defaultValue: 'UUIDV4', // Typically handled by database default or query logic
    primaryKey: true,
  },
  sender_id: {
    type: 'UUID',
    allowNull: false,
    references: {
      model: 'users',
      key: 'id',
    },
    onDelete: 'CASCADE',
  },
  receiver_id: {
    type: 'UUID',
    allowNull: false,
    references: {
      model: 'users',
      key: 'id',
    },
    onDelete: 'CASCADE',
  },
  container_id: {
    type: 'UUID',
    allowNull: true,
    references: {
      model: 'containers',
      key: 'id',
    },
    onDelete: 'SET NULL',
  },
  message: {
    type: 'TEXT',
    allowNull: false,
  },
  timestamp: {
    type: 'TIMESTAMP WITH TIME ZONE', // Corrected from DATE to a more precise timestamp type for PostgreSQL
    defaultValue: 'NOW()', // Typically handled by database default
  },
};

// For reference, the table name is 'messages'
const tableName = 'messages';

// Indexes (for reference)
const indexes = [
  {
    fields: ['sender_id', 'receiver_id'],
    name: 'idx_messages_sender_receiver',
  },
  {
    fields: ['container_id'],
    name: 'idx_messages_container_id',
  },
  {
    fields: ['timestamp'],
    name: 'idx_messages_timestamp',
  },
];

// Exporting for documentation or external tooling.
// This object is not used by the current application logic which uses raw pgPool queries.
module.exports = {
  tableName,
  schema: messageSchema,
  indexes,
};