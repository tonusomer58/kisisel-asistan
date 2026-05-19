# 🤖 Kişisel Asistan (Akıllı Finans Asistanı)

📌 DİKKAT: Güvenlik önlemleri gereği yapay zeka (Gemini) API anahtarımız sadece canlı web sitemiz (Vercel) üzerinden çalışacak şekilde kısıtlanmıştır. Projenin tüm özelliklerini eksiksiz test edebilmek için lütfen derlenmiş projemizi şu linkten inceleyiniz: https://kisisel-asistan-one.vercel.app/

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Gemini](https://img.shields.io/badge/Google_Gemini-8E75B2?style=for-the-badge&logo=google&logoColor=white)

Bireyler ve KOBİ'ler için geliştirilmiş, Google Gemini yapay zeka destekli, kapsamlı ve modern finansal yönetim platformu. Gelir-gider takibinizi yapay zeka asistanı ile otomatikleştirin, finansal hedeflerinizi yönetin ve bütçenizi akıllıca planlayın.

## ✨ Öne Çıkan Özellikler

*   **🧠 Yapay Zeka Destekli Finans Asistanı:** Google Gemini entegrasyonu sayesinde harcamalarınızı sesli veya yazılı komutlarla akıllıca kaydedin ve analiz edin.
*   **📊 Kapsamlı Dashboard:** Finansal durumunuzu özetleyen modern, mobil ve web uyumlu grafiksel arayüz.
*   **🔐 Güvenli Kimlik Doğrulama:** Firebase Auth ile desteklenen bireysel ve kurumsal (KOBİ) özel kayıt ve giriş akışları.
*   **🎯 Birikim Hedefleri:** Etkileşimli hedefler belirleyin, ilerlemenizi takip edin ve hedeflerinize daha hızlı ulaşın.
*   **🔄 Sabit Giderler ve Yaklaşan Ödemeler:** Tekrarlayan ödemelerinizi ve faturalarınızı sistem üzerinden kolayca takip edip hatırlatıcılar kurun.
*   **🌙 Dinamik Tema Desteği:** Kusursuz tasarlanmış, göz yormayan Karanlık ve Aydınlık (Dark/Light) mod seçenekleri.
*   **🌐 Çapraz Platform (Cross-Platform):** Tek bir kod tabanı üzerinden hem Web hem de Android'de pürüzsüz çalışma deneyimi.

## 🛠️ Kullanılan Teknolojiler

*   **Frontend:** Flutter, Dart
*   **Backend & Veritabanı:** Firebase (Authentication, Cloud Firestore)
*   **Yapay Zeka:** Google Generative AI (Gemini Pro/Flash API)
*   **Durum Yönetimi (State Management):** Provider / Riverpod (Mevcut mimariye bağlı olarak)

## 🚀 Başlarken

Bu projeyi yerel ortamınızda çalıştırmak için aşağıdaki adımları izleyin:

### Ön Koşullar

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (En güncel stabil sürüm)
- Firebase CLI ve aktif bir Firebase projesi
- Geçerli bir Google Gemini API Anahtarı

### Kurulum

1. Repoyu bilgisayarınıza klonlayın:
   ```bash
   git clone https://github.com/tonusomer58/kisisel-asistan.git
   ```
2. Proje dizinine gidin:
   ```bash
   cd kisisel-asistan
   ```
3. Gerekli paketleri indirin:
   ```bash
   flutter pub get
   ```
4. Firebase yapılandırmanızı `lib/firebase_options.dart` veya ilgili konfigürasyon dosyalarına ekleyin.
5. Gemini API anahtarınızı projedeki ilgili `.env` veya servis dosyasına entegre edin.
6. Uygulamayı başlatın:
   ```bash
   flutter run -d chrome  # Web için
   # veya
   flutter run            # Mobil cihaz/emülatör için
   ```

## 🤝 Katkıda Bulunma

Bu proje hackathon veya özel geliştirme süreçleri için oluşturulmuştur. Katkıda bulunmak isterseniz lütfen bir Issue açın veya Pull Request gönderin.

---
⭐️ *Eğer bu projeyi faydalı bulduysanız, yıldıza basmayı unutmayın!* ⭐️
