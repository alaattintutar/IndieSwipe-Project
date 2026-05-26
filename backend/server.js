require('dotenv').config();
const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');

const authRoutes = require('./routes/auth');
const gameRoutes = require('./routes/games');

const app = express();
const PORT = process.env.PORT || 3000;

// ── MongoDB connection cache (serverless-safe) ─────────────────────────────
let isConnected = false;

async function connectDB() {
  if (isConnected) return;
  await mongoose.connect(process.env.MONGODB_URI);
  isConnected = true;
  console.log('Connected to MongoDB');
}

// ── Global middleware ──────────────────────────────────────────────────────
app.use(cors());
app.use(express.json());

// Ensure DB is ready before every route handler runs.
app.use(async (req, res, next) => {
  try {
    await connectDB();
    next();
  } catch (err) {
    console.error('MongoDB connection error:', err.message);
    res.status(500).json({ message: 'Database connection failed', error: err.message });
  }
});

// ── Routes ─────────────────────────────────────────────────────────────────
app.get('/', (req, res) => res.send('IndieSwipe Backend is running!'));
app.use('/api/auth', authRoutes);
app.use('/api/games', gameRoutes);

// ── Local dev server ───────────────────────────────────────────────────────
if (require.main === module) {
  connectDB().then(() => {
    app.listen(PORT, () => console.log(`Server is running on port ${PORT}`));
  });
}

module.exports = app;
