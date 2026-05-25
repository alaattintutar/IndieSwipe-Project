const mongoose = require('mongoose');

const gameSchema = new mongoose.Schema({
  title: { type: String, required: true },
  gifUrl: { type: String, required: true },
  description: { type: String, required: true },
  steamLink: { type: String, required: true },
  tags: [String],
  steamAppId: { type: String, required: true },
  videoUrl: { type: String, default: '' },
  price: { type: String, default: 'N/A' },
  reviewSummary: { type: String, default: '' },
}, { timestamps: true });

module.exports = mongoose.model('Game', gameSchema);