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

// Start the server and listen for incoming connections on the specified port
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
