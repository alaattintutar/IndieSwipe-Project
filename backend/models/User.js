const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  username: { type: String, required: true, unique: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { type: String, enum: ['gamer', 'dev'], default: 'gamer' },
  savedGames: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Game' }],
  seenGames: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Game' }],
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);