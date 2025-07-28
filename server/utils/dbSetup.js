// Filename: server/utils/dbSetup.js
const pgPool = require('./db');

const createPgTables = async () => {
  const client = await pgPool.connect();
  try {
    // It's crucial to create tables in the correct order due to foreign key constraints.
    // 1. Users table (no dependencies)
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY,
        role VARCHAR(10) NOT NULL CHECK (role IN ('lsp', 'msme', 'admin')),
        email VARCHAR(255) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        company VARCHAR(255) NOT NULL,
        phone VARCHAR(20) NOT NULL,
        status VARCHAR(10) DEFAULT 'pending' CHECK (status IN ('pending', 'verified', 'rejected')),
        rejection_reason TEXT,
        fcm_token VARCHAR(255),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
    `);
    console.log('Table "users" checked/created successfully.');

    // 2. Containers table (depends on users)
    await client.query(`
      CREATE TABLE IF NOT EXISTS containers (
        id UUID PRIMARY KEY,
        lsp_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        origin VARCHAR(255) NOT NULL,
        destination VARCHAR(255) NOT NULL,
        routes TEXT[],
        space_total DECIMAL NOT NULL,
        space_left DECIMAL NOT NULL,
        price DECIMAL NOT NULL,
        modal VARCHAR(10) NOT NULL CHECK (modal IN ('road', 'rail', 'sea', 'air')),
        deadline TIMESTAMP WITH TIME ZONE NOT NULL,
        departure_time TIMESTAMP WITH TIME ZONE NOT NULL,
        status VARCHAR(10) DEFAULT 'active' CHECK (status IN ('active', 'expired', 'full')),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
    `);
    console.log('Table "containers" checked/created successfully.');

    // 3. Bookings table (depends on users and containers)
    await client.query(`
      CREATE TABLE IF NOT EXISTS bookings (
        id UUID PRIMARY KEY,
        container_id UUID NOT NULL REFERENCES containers(id) ON DELETE CASCADE,
        msme_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        product_name VARCHAR(255) NOT NULL,
        category VARCHAR(255),
        weight DECIMAL NOT NULL,
        image_url TEXT,
        status VARCHAR(10) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'cancelled')),
        rejection_reason TEXT,
        payment_status VARCHAR(10) DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'failed')),
        razorpay_order_id VARCHAR(255),
        razorpay_payment_id VARCHAR(255),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
    `);
    console.log('Table "bookings" checked/created successfully.');
    
    // 4. Messages table (depends on users and containers)
    await client.query(`
      CREATE TABLE IF NOT EXISTS messages (
        id UUID PRIMARY KEY,
        sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        receiver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        container_id UUID REFERENCES containers(id) ON DELETE SET NULL,
        message TEXT NOT NULL,
        timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
    `);
    console.log('Table "messages" checked/created successfully.');

  } catch (err) {
    console.error('Error creating PostgreSQL tables:', err);
    process.exit(1); // Exit if tables can't be created
  } finally {
    client.release();
  }
};

module.exports = { createPgTables };