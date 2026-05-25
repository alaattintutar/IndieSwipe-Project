require('dotenv').config();
const mongoose = require('mongoose');
const axios = require('axios');
const Game = require('./models/Game');

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

// ── Step 1: Fetch top 50 indie game App IDs from SteamSpy ──────────────────
// SteamSpy returns all games tagged as "Indie" with their review counts.
// We sort by positive reviews and pick the top 50.
async function fetchTopIndieAppIds(count = 50) {
  console.log('Fetching top indie games from SteamSpy...');
  const response = await axios.get(
    'https://steamspy.com/api.php?request=tag&tag=Indie'
  );
  const games = Object.values(response.data);

  // Sort by positive review count descending, pick top N
  const sorted = games
    .filter(g => g.positive > 0)
    .sort((a, b) => b.positive - a.positive)
    .slice(0, count);

  console.log(`Found ${sorted.length} games from SteamSpy\n`);
  return sorted.map(g => String(g.appid));
}

// ── Step 2: Fetch game details from Steam Store API ────────────────────────
async function fetchGameDetails(appId) {
  try {
    const response = await axios.get(
      `https://store.steampowered.com/api/appdetails?appids=${appId}&cc=us&l=english`
    );
    const data = response.data[appId];
    if (!data?.success) return null;
    return data.data;
  } catch (err) {
    return null;
  }
}

// ── Step 3: Fetch review summary ───────────────────────────────────────────
async function fetchReviewSummary(appId) {
  try {
    const response = await axios.get(
      `https://store.steampowered.com/appreviews/${appId}?json=1&language=all&purchase_type=all`
    );
    return response.data?.query_summary?.review_score_desc || 'No Reviews';
  } catch {
    return 'No Reviews';
  }
}

// ── Step 4: Extract HLS video URL from movies array ────────────────────────
// Steam now uses HLS/DASH streams instead of direct mp4/webm links
function extractVideoUrl(movies) {
  if (!movies || movies.length === 0) return '';
  return movies[0]?.hls_h264 || movies[0]?.dash_h264 || '';
}

// ── Main seed function ─────────────────────────────────────────────────────
async function seed() {
  await mongoose.connect(process.env.MONGODB_URI);
  console.log('Connected to MongoDB');

  await Game.deleteMany({});
  console.log('Cleared existing games\n');

  const appIds = await fetchTopIndieAppIds(50);
  const games = [];

  for (let i = 0; i < appIds.length; i++) {
    const appId = appIds[i];
    console.log(`[${i + 1}/${appIds.length}] Fetching App ID: ${appId}...`);

    const details = await fetchGameDetails(appId);
    if (!details) {
      console.log('  Skipped — no data\n');
      await sleep(1500);
      continue;
    }

    // Skip games without a header image (incomplete entries)
    if (!details.header_image) {
      console.log(`  Skipped — no image\n`);
      await sleep(1500);
      continue;
    }

    const reviewSummary = await fetchReviewSummary(appId);

    const game = {
      steamAppId: appId,
      title: details.name,
      gifUrl: details.header_image,
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
    console.log(`  ✓ ${game.title} — ${game.price} — ${game.reviewSummary}`);
    console.log(`    Video: ${game.videoUrl ? 'found' : 'not available'}\n`);

    await sleep(1500);
  }

  await Game.insertMany(games);
  console.log(`\nSeeded ${games.length} games successfully!`);
  process.exit(0);
}

seed().catch(err => {
  console.error('Seed error:', err.message);
  process.exit(1);
});
