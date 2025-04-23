# LegalAI

LegalAI, hukuki konularda yapay zeka destekli danışmanlık ve belge yönetimi sağlayan Flutter tabanlı bir mobil uygulamadır.

## Özellikler

- Belge tarama ve işleme
- Hukuki belge oluşturma
- AI destekli hukuki soru cevaplama
- Belge yönetimi ve düzenleme
- Profil yönetimi

## Teknolojiler

- Flutter ve Dart
- Supabase (Backend ve Authentication)
- OpenAI API (AI modelleri)

## Kurulum

1. Repoyu klonlayın:
```
git clone https://github.com/kullaniciadi/legalai.git
```

2. Bağımlılıkları yükleyin:
```
flutter pub get
```

3. Supabase ve OpenAI API anahtarlarınızı yapılandırın.

4. Uygulamayı çalıştırın:
```
flutter run
```

## Proje Yapısı

```
lib/
├── core/
│   ├── theme/
│   └── utils/
├── features/
│   ├── home/
│   ├── chat/
│   └── document/
├── models/
└── main.dart
```

## Katkıda Bulunma

1. Repoyu forklayın
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Değişikliklerinizi commit edin (`git commit -m 'Add some amazing feature'`)
4. Branch'inize push edin (`git push origin feature/amazing-feature`)
5. Pull Request oluşturun

## Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Detaylar için `LICENSE` dosyasına bakınız.
