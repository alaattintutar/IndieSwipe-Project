# 🎮 IndieSwipe

> "Günde Sadece 10 Oyun. Gizli Cevherleri Keşfet."

IndieSwipe, bağımsız (indie) oyunlar ve nostaljik mod paketleri için tasarlanmış, metinsiz, tamamen video/oynanış odaklı, "Tinder tarzı" bir oyun keşif platformudur.

## 🌟 Proje Vizyonu (MVP)
Günümüzün bilgi yığını ve sonsuz kaydırma (doomscrolling) çılgınlığına karşı bir panzehir:
* **Günlük 10 Kart Ritüeli:** Kullanıcıya günde sadece özenle seçilmiş 10 oyun sunulur. Sonsuz kaydırma (bağımlılık) yoktur.
* **Sıfır Metin, Sadece Oynanış:** Uzun ve sıkıcı yazılar yerine, oyunun ruhunu anlatan saf oynanış kesitleri (GIF).
* **Save Room (Kayıt Odası):** Beğendiğin (sağa kaydırdığın) oyunlar kendi kişisel arşivine kaydedilir ve tek tıkla Steam sayfasına yönlendirir.

## 🛠️ Teknoloji Yığını (Tech Stack)

### Backend
* **Node.js & Express.js:** Hızlı ve ölçeklenebilir RESTful API.
* **MongoDB & Mongoose:** Esnek NoSQL veritabanı.
* **Güvenlik:** JWT tabanlı kimlik doğrulama, bcrypt şifreleme.

### Frontend
* **Flutter:** Tek kod tabanı ile mobil, web ve masaüstü arayüzü.
* **Riverpod:** Modern, performanslı durum yönetimi (State Management).
* **Dio:** Güçlü HTTP istemcisi (Interceptors ile otomatik Token yönetimi).
* **Card Swiper:** Pürüzsüz kaydırma animasyonları.

## 🎨 Tasarım Dili
* **Arka Plan (Midnight Void):** `#09090B` (Kapkaranlık, derin ve odaklayıcı)
* **Kartlar (Arcade Zinc):** `#18181B`
* **Vurgular (Neon Pink):** `#FF0055` (Cyberpunk hissiyatı, tetikleyici aksiyon rengi)

## 🚀 Kurulum ve Çalıştırma

### 1. Backend'i Başlatma
```bash
cd backend
npm install
# .env dosyanıza MONGODB_URI ve JWT_SECRET eklemeyi unutmayın!
npm start
```

### 2. Veritabanını Doldurma (Seed)
Veritabanına efsanevi 15 bağımsız oyunu yüklemek için:
```bash
cd backend
node seed.js
```

### 3. Frontend'i Başlatma
```bash
cd frontend
flutter pub get
flutter run
```
*(Not: Android Emülatör kullanıyorsanız `core/constants.dart` içindeki API adresi `10.0.2.2` olmalıdır. Web testi için `localhost` kalmalıdır.)*

---
*Made with ❤️ by a Solo Dev exploring the frontiers of AI Pair Programming.*
