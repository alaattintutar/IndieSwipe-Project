const express = require('express');
const router = express.Router();
const Game = require('../models/Game');
const User = require('../models/User');

// Middleware to protect routes
const authMiddleware = require('../middleware/auth');

// GET /api/games/daily - Get daily game recommendations
router.get('/daily', authMiddleware, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);

    const games = await Game.find({
      _id: { $nin: user.seenGames }
    }).limit(10);

    if (games.length === 0) {
      return res.json({ message: 'No new games today', nextDeckIn: '24h' });
    }

    const gameIds = games.map(game => game._id);
    await User.findByIdAndUpdate(req.user.userId, {
      $push: { seenGames: { $each: gameIds } }
    });

    res.json({ games });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// POST /api/games/save/:gameId - Save a game to user's saved list
router.post('/save/:gameId', authMiddleware, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);

    const alreadySaved = user.savedGames.includes(req.params.gameId);
    if (alreadySaved) {
      return res.status(400).json({ message: 'Game already saved' });
    }

    await User.findByIdAndUpdate(req.user.userId, {
      $push: { savedGames: req.params.gameId }
    });

    res.json({ message: 'Game saved successfully' });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

module.exports = router;