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

app.use(cors()); // Middleware to enable CORS

app.use(express.json()); // Middleware to parse JSON request bodies

// Use the authentication routes for any requests starting with '/api/auth'
app.use('/api/auth', authRoutes);

// Load the game routes defined in the 'games.js' file and use them for any requests starting with '/api/games'
const gameRoutes = require('./routes/games');
app.use('/api/games', gameRoutes);

// Connect to MongoDB using the connection string from environment variables
mongoose.connect(process.env.MONGODB_URI)
  .then(() => console.log('Connected to MongoDB'))
  .catch((err) => console.log('MongoDB connection error:', err));

// Start the server only when this file is run directly (node server.js).
// When Vercel imports this file as a serverless function it uses the
// module.exports below — app.listen() must NOT be called in that case.
if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
  });
}

// Export the Express app so Vercel can use it as a serverless handler.
module.exports = app;
