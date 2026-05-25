require('dotenv').config();
const mongoose = require('mongoose');
const Game = require('./models/Game');

// Sample game data to seed the database
const games = [
  {
    title: 'Hollow Knight',
    gifUrl: 'https://placehold.co/400x600/18181B/FF0055.png?text=Hollow+Knight',
    description: 'A challenging 2D action-adventure in a vast underground kingdom.',
    steamLink: 'https://store.steampowered.com/app/367520/Hollow_Knight/',
    tags: ['metroidvania', 'indie', 'platformer'],
  },
  {
    title: 'Hades',
    gifUrl: 'https://placehold.co/400x600/18181B/FF0055.png?text=Hades',
    description: 'A rogue-like dungeon crawler in which you defy the god of the dead.',
    steamLink: 'https://store.steampowered.com/app/1145360/Hades/',
    tags: ['roguelike', 'action', 'indie'],
  },
  {
    title: 'Celeste',
    gifUrl: 'https://placehold.co/400x600/18181B/FF0055.png?text=Celeste',
    description: 'Help Madeline survive her inner demons on her journey to the top of Celeste Mountain.',
    steamLink: 'https://store.steampowered.com/app/504230/Celeste/',
    tags: ['platformer', 'pixel-art', 'indie'],
  },
  {
    title: 'Stardew Valley',
    gifUrl: 'https://placehold.co/400x600/18181B/FF0055.png?text=Stardew+Valley',
    description: 'You\'ve inherited your grandfather\'s old farm plot. Armed with hand-me-down tools, you set out to begin your new life.',
    steamLink: 'https://store.steampowered.com/app/413150/Stardew_Valley/',
    tags: ['farming', 'rpg', 'cozy'],
  },
  {
    title: 'Dead Cells',
    gifUrl: 'https://placehold.co/400x600/18181B/FF0055.png?text=Dead+Cells',
    description: 'A rogue-lite, metroidvania action-platformer. You\'ll explore a sprawling, ever-changing castle.',
    steamLink: 'https://store.steampowered.com/app/588650/Dead_Cells/',
    tags: ['roguelite', 'metroidvania', 'action'],
  },
  {
    title: 'Cuphead',
    gifUrl: 'https://placehold.co/400x600/18181B/FF0055.png?text=Cuphead',
    description: 'A classic run and gun action game heavily focused on boss battles, inspired by 1930s cartoons.',
    steamLink: 'https://store.steampowered.com/app/268910/Cuphead/',
    tags: ['shoot-em-up', 'difficult', 'hand-drawn'],
  },
  {
    title: 'Outer Wilds',
    gifUrl: 'https://placehold.co/400x600/18181B/FF0055.png?text=Outer+Wilds',
    description: 'An open world mystery about a solar system trapped in an endless time loop.',
    steamLink: 'https://store.steampowered.com/app/753640/Outer_Wilds/',
    tags: ['exploration', 'mystery', 'space'],
  },
  {
    title: 'Undertale',
    gifUrl: 'https://placehold.co/400x600/18181B/FF0055.png?text=Undertale',
    description: 'A role-playing game where you don\'t have to destroy anyone.',
    steamLink: 'https://store.steampowered.com/app/391540/UNDERTALE/',
    tags: ['rpg', 'story-rich', 'great-soundtrack'],
  },
  {
    title: 'Slay the Spire',
    gifUrl: 'https://placehold.co/400x600/18181B/FF0055.png?text=Slay+the+Spire',
    description: 'We fused card games and roguelikes together to make the best single player deckbuilder we could.',
    steamLink: 'https://store.steampowered.com/app/646570/Slay_the_Spire/',
    tags: ['deckbuilder', 'roguelike', 'strategy'],
  },
  {
    title: 'Terraria',
    gifUrl: 'https://placehold.co/400x600/18181B/FF0055.png?text=Terraria',
    description: 'Dig, fight, explore, build! Nothing is impossible in this action-packed adventure game.',
    steamLink: 'https://store.steampowered.com/app/105600/Terraria/',
    tags: ['sandbox', 'survival', 'multiplayer'],
  },
  {
    title: 'Return of the Obra Dinn',
    gifUrl: 'https://placehold.co/400x600/18181B/FF0055.png?text=Obra+Dinn',
    description: 'An insurance adventure with minimal color. Discover the fate of the crew of the Obra Dinn.',
    steamLink: 'https://store.steampowered.com/app/653530/Return_of_the_Obra_Dinn/',
    tags: ['detective', 'puzzle', 'mystery'],
  },
  {
    title: 'Disco Elysium',
    gifUrl: 'https://placehold.co/400x600/18181B/FF0055.png?text=Disco+Elysium',
    description: 'A groundbreaking role playing game. You\'re a detective with a unique skill system at your disposal.',
    steamLink: 'https://store.steampowered.com/app/632470/Disco_Elysium__The_Final_Cut/',
    tags: ['rpg', 'story-rich', 'choices-matter'],
  },
  {
    title: 'Inscryption',
    gifUrl: 'https://placehold.co/400x600/18181B/FF0055.png?text=Inscryption',
    description: 'An inky black card-based odyssey that blends the deckbuilding roguelike, escape-room style puzzles, and psychological horror.',
    steamLink: 'https://store.steampowered.com/app/1092790/Inscryption/',
    tags: ['card-battler', 'horror', 'story-rich'],
  },
  {
    title: 'Vampire Survivors',
    gifUrl: 'https://placehold.co/400x600/18181B/FF0055.png?text=Vampire+Survivors',
    description: 'Mow down thousands of night creatures and survive until dawn!',
    steamLink: 'https://store.steampowered.com/app/1794680/Vampire_Survivors/',
    tags: ['bullet-hell', 'roguelite', 'action'],
  },
  {
    title: 'Dave the Diver',
    gifUrl: 'https://placehold.co/400x600/18181B/FF0055.png?text=Dave+the+Diver',
    description: 'A casual, singleplayer adventure RPG featuring deep-sea exploration and fishing during the day and sushi restaurant management at night.',
    steamLink: 'https://store.steampowered.com/app/1868140/DAVE_THE_DIVER/',
    tags: ['rpg', 'management', 'pixel-art'],
  }
];

// Connect to MongoDB and seed the database with initial game data
mongoose.connect(process.env.MONGODB_URI)
  .then(async () => {
    console.log('Connected to MongoDB');
    await Game.deleteMany({});
    await Game.insertMany(games);
    console.log('Database seeded successfully');
    process.exit(0);
  })
  .catch((err) => {
    console.log('Error:', err);
    process.exit(1);
  });