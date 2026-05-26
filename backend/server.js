// Import the CORS middleware to enable Cross-Origin Resource Sharing
const cors = require('cors');

// Load environment variables from a .env file into process.env
require('dotenv').config();
const mongoose = require('mongoose');

// Load the authentication routes defined in the 'auth.js' file
const authRoutes = require('./routes/auth');

// Import the Express framework to handle HTTP routing
const express = require('express');

// Create an Express application instance
const app = express();

// Use the environment's PORT if available (e.g. when deployed to Render/Railway),
// otherwise fall back to 3000 for local development
const PORT = process.env.PORT || 3000;

// Define a GET route for the root path '/'
// req = incoming request object, res = outgoing response object
app.get('/', (req, res) => {
  res.send('IndieSwipe Backend is running!');
});

app.get('/api/health', async (req, res) => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    res.json({ status: 'ok', readyState: mongoose.connection.readyState });
  } catch (err) {
    res.status(500).json({ status: 'error', error: err.message });
  }
});

app.use(cors()); // Middleware to enable CORS

app.use(express.json()); // Middleware to parse JSON request bodies

// Use the authentication routes for any requests starting with '/api/auth'
app.use('/api/auth', authRoutes);

// Load the game routes defined in the 'games.js' file and use them for any requests starting with '/api/games'
const gameRoutes = require('./routes/games');
app.use('/api/games', gameRoutes);

// Serverless-safe MongoDB connection: reuse the existing connection across
// warm invocations instead of reconnecting on every cold start.
let isConnected = false;

async function connectDB() {
  if (isConnected) return;
  await mongoose.connect(process.env.MONGODB_URI);
  isConnected = true;
  console.log('Connected to MongoDB');
}

// Ensure DB is connected before every request hits a route handler.
app.use(async (req, res, next) => {
  try {
    await connectDB();
    next();
  } catch (err) {
    console.error('MongoDB connection error:', err);
    res.status(500).json({ message: 'Database connection failed', error: err.message });
  }
});

if (require.main === module) {
  connectDB().then(() => {
    app.listen(PORT, () => console.log(`Server is running on port ${PORT}`));
  });
}

// Export the Express app so Vercel can use it as a serverless handler.
module.exports = app;
