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

    res.json({ games });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// GET /api/games/feed - Next batch of unseen games for the card stack
// Query params:
//   exclude (optional) — comma-separated IDs already loaded in the frontend
//   limit   (optional) — how many games to return (default: 10)
//
// Why exclude instead of page/skip?
// skip + $nin:seenGames creates a moving-window problem: every swipe grows
// seenGames and shrinks the pool, so skip(N) no longer lands at the right
// position. Sending the IDs the frontend already holds is always precise —
// the backend simply excludes them and returns the first `limit` fresh games.
router.get('/feed', authMiddleware, async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 10;

    // Parse the comma-separated list of IDs currently in the frontend stack
    const excludeParam = req.query.exclude || '';
    const frontendIds = excludeParam
      ? excludeParam.split(',').filter(Boolean)
      : [];

    const user = await User.findById(req.user.userId);

    // Combine: games already swiped (seenGames) + games currently on screen
    const allExclude = [
      ...user.seenGames.map(id => id.toString()),
      ...frontendIds,
    ];

    const games = await Game.find({ _id: { $nin: allExclude } }).limit(limit);
    const total = await Game.countDocuments({ _id: { $nin: allExclude } });

    // hasMore is true when the pool still has games beyond what we just fetched
    const hasMore = total > games.length;

    res.json({ games, hasMore });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// POST /api/games/save/:gameId - Save a game to user's saved list
router.post('/save/:gameId', authMiddleware, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);

    const alreadySaved = user.savedGames.some(id => id.toString() === req.params.gameId);
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

// GET /api/games/saved - Get user's saved games
router.get('/saved', authMiddleware, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId).populate('savedGames');
    res.json({ games: user.savedGames });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// POST /api/games/seen/:gameId - Mark a game as seen
router.post('/seen/:gameId', authMiddleware, async (req, res) => {
  try {
    await User.findByIdAndUpdate(req.user.userId, {
      $addToSet: { seenGames: req.params.gameId }
    });
    res.json({ message: 'Game marked as seen' });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

module.exports = router;