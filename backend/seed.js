require('dotenv').config();
const mongoose = require('mongoose');
const axios = require('axios');
const Game = require('./models/Game');

// Steam App IDs for the indie games we want to seed
const STEAM_APP_IDS = [
  '367520',  // Hollow Knight
  '1145360', // Hades
  '504230',  // Celeste
  '413150',  // Stardew Valley
  '588650',  // Dead Cells
  '268910',  // Cuphead
  '753640',  // Outer Wilds
  '391540',  // Undertale
  '646570',  // Slay the Spire
  '105600',  // Terraria
  '653530',  // Return of the Obra Dinn
  '632470',  // Disco Elysium
  '1092790', // Inscryption
  '1794680', // Vampire Survivors
  '1868140', // Dave the Diver
];

// Wait between requests to respect Steam rate limits
const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

// Fetch game details (name, description, price, video) from Steam Store API
async function fetchGameDetails(appId) {
  try {
    const response = await axios.get(
      `https://store.steampowered.com/api/appdetails?appids=${appId}&cc=us&l=english`
    );
    const data = response.data[appId];
    if (!data.success) return null;
    return data.data;
  } catch (err) {
    console.log(`Failed to fetch details for ${appId}: ${err.message}`);
    return null;
  }
}

// Fetch review summary from Steam (e.g. "Overwhelmingly Positive")
async function fetchReviewSummary(appId) {
  try {
    const response = await axios.get(
      `https://store.steampowered.com/appreviews/${appId}?json=1&language=all&purchase_type=all`
    );
    return response.data?.query_summary?.review_score_desc || 'No Reviews';
  } catch (err) {
    return 'No Reviews';
  }
}

// Extract video URL from the movies array
// Steam now returns HLS/DASH streams instead of direct mp4/webm links
function extractVideoUrl(movies) {
  if (!movies || movies.length === 0) return '';
  const first = movies[0];
  return first?.hls_h264 || first?.dash_h264 || '';
}

async function seed() {
  await mongoose.connect(process.env.MONGODB_URI);
  console.log('Connected to MongoDB');

  await Game.deleteMany({});
  console.log('Cleared existing games\n');

  const games = [];

  for (const appId of STEAM_APP_IDS) {
    console.log(`Fetching App ID: ${appId}...`);

    const details = await fetchGameDetails(appId);
    if (!details) {
      console.log(`  Skipping — no data returned\n`);
      await sleep(1500);
      continue;
    }

    const reviewSummary = await fetchReviewSummary(appId);

    const game = {
      steamAppId: appId,
      title: details.name,
      gifUrl: details.header_image || '',
      videoUrl: extractVideoUrl(details.movies),
      description: details.short_description || '',
      steamLink: `https://store.steampowered.com/app/${appId}`,
      price: details.is_free
        ? 'Free to Play'
        : details.price_overview?.final_formatted || 'N/A',
      reviewSummary,
      tags: details.genres?.map(g => g.description.toLowerCase()) || [],
    };

    games.push(game);
    console.log(`  ✓ ${game.title}`);
    console.log(`    Price: ${game.price}`);
    console.log(`    Reviews: ${game.reviewSummary}`);
    console.log(`    Video: ${game.videoUrl ? 'found' : 'not available'}\n`);

    // 1.5 second delay between requests to avoid rate limiting
    await sleep(1500);
  }

  await Game.insertMany(games);
  console.log(`Seeded ${games.length} games successfully!`);
  process.exit(0);
}

seed().catch((err) => {
  console.error('Seed error:', err);
  process.exit(1);
});
