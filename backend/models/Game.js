const mongoose = require('mongoose');

const gameSchema = new mongoose.Schema({
  title: { type: String, required: true },
  gifUrl: { type: String, required: true },
  description: { type: String, required: true },
  steamLink: { type: String, required: true },
  tags: [String],
}, { timestamps: true });

module.exports = mongoose.model('Game', gameSchema);