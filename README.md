<p align="center">
  <img src="frontend/assets/indieswipe_logo.png" width="140" alt="IndieSwipe Logo"/>
</p>

<h1 align="center">IndieSwipe</h1>
<p align="center"><em>"Günde Sadece 10 Oyun. Gizli Cevherleri Keşfet."</em></p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter" />
  <img src="https://img.shields.io/badge/Node.js-Express-339933?logo=nodedotjs" />
  <img src="https://img.shields.io/badge/MongoDB-Atlas-47A248?logo=mongodb" />
  <img src="https://img.shields.io/badge/Deployed-Vercel-000000?logo=vercel" />
</p>

---

IndieSwipe, Steam'in bağımsız oyun kataloğundan özenle seçilmiş oyunları **Tinder tarzı video kartlarıyla** keşfettiren bir mobil uygulamadır. Uzun listeler ve yazı yığınları yerine saf oynanış videosu — beğendiklerini bir kaydırmayla arşivine kaydet.

## Özellikler

- **Video Swipe Kartlar** — Her kart oyunun gerçek oynanış videosunu (MP4) oynatır
- **Tek Tıkla Detay** — Karta dokunmak oyun detaylarını ve Steam linkini açar
- **Çift Tıkla Kaydet** — İki kez dokunmak sağa kaydırır, oyunu arşivine ekler
- **Mute / Unmute** — Kart üzerinde anlık ses kontrolü
- **Tür Filtreleme** — Action, Adventure, RPG, Strategy, Simulation, Casual chip'leriyle
- **Save Room** — Kaydedilen oyunların kişisel galerisi, tek tıkla Steam'e yönlendir
- **JWT Kimlik Doğrulama** — Kayıt / giriş, otomatik token yönetimi (interceptor)
- **Glassmorphism Nav Bar** — Blur efektli navigasyon çubuğu

## Tech Stack

| Katman | Teknoloji |
|--------|-----------|
| Frontend | Flutter · Riverpod · Dio · flutter_card_swiper · video_player · Google Fonts |
| Backend | Node.js · Express.js · MongoDB Atlas · JWT · bcrypt |
| Deploy | Vercel (API) · MongoDB Atlas (DB) |
| Veri | SteamSpy + Steam Store API (77 seçilmiş indie oyun) |

## Tasarım Dili

| Rol | Renk |
|-----|------|
| Arka Plan — Midnight Void | `#09090B` |
| Kart — Arcade Zinc | `#18181B` |
| Vurgu — Neon Pink | `#FF0055` |

Yazı tipleri: **Space Grotesk** (başlıklar) · **Outfit** (açıklamalar)

## Kurulum

### Backend

```bash
cd backend
npm install
```

`.env` oluştur:

```
MONGODB_URI=<MongoDB Atlas bağlantı dizesi>
JWT_SECRET=<güçlü bir secret>
```

```bash
npm start        # geliştirme sunucusu
node seed.js     # SteamSpy'dan 77 oyunu veritabanına yükle
```

Canlı API: `https://indieswipe-api.vercel.app/api`

### Frontend

```bash
cd frontend
flutter pub get
flutter run
```

## Proje Yapısı

```
IndieSwipe-Project/
├── backend/
│   ├── models/        # Mongoose şemaları (Game, User)
│   ├── routes/        # auth ve games API route'ları
│   ├── seed.js        # SteamSpy → MongoDB seed scripti
│   └── server.js      # Express + Vercel serverless handler
└── frontend/
    ├── assets/        # Logo
    └── lib/
        ├── core/      # ApiService, AppConstants
        └── features/
            ├── auth/       # Login / Register ekranları
            ├── games/      # SwipeScreen, GamesProvider, VideoCard
            └── save_room/  # Kaydedilen oyunlar galerisi
```
