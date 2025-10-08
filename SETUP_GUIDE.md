# Kurulum ve Kullanım Rehberi

Bu rehber, **Takım Yönetim Sistemi** Flutter uygulamasını Android Studio'da açmak ve çalıştırmak için gerekli adımları detaylı olarak açıklamaktadır.

## İçindekiler

1. [Gerekli Yazılımlar](#gerekli-yazılımlar)
2. [Android Studio Kurulumu](#android-studio-kurulumu)
3. [Flutter SDK Kurulumu](#flutter-sdk-kurulumu)
4. [Projeyi Açma](#projeyi-açma)
5. [Firebase Yapılandırması](#firebase-yapılandırması)
6. [Demo Kullanıcıları Oluşturma](#demo-kullanıcıları-oluşturma)
7. [Uygulamayı Çalıştırma](#uygulamayı-çalıştırma)
8. [Sorun Giderme](#sorun-giderme)

## Gerekli Yazılımlar

Projeyi çalıştırmak için aşağıdaki yazılımlara ihtiyacınız var:

- **Android Studio** (Arctic Fox veya daha yeni)
- **Flutter SDK** (3.24.5 veya üzeri)
- **Java Development Kit (JDK)** 17 veya üzeri
- **Git** (opsiyonel)

## Android Studio Kurulumu

### Windows

1. [Android Studio resmi sitesinden](https://developer.android.com/studio) indirin
2. İndirilen `.exe` dosyasını çalıştırın
3. Kurulum sihirbazını takip edin
4. "Android Virtual Device" seçeneğini işaretleyin
5. Kurulumu tamamlayın

### macOS

1. [Android Studio resmi sitesinden](https://developer.android.com/studio) indirin
2. `.dmg` dosyasını açın
3. Android Studio'yu Applications klasörüne sürükleyin
4. İlk açılışta kurulum sihirbazını takip edin

### Linux

```bash
# Ubuntu/Debian için
sudo snap install android-studio --classic

# Veya manuel kurulum
wget https://redirector.gvt1.com/edgedl/android/studio/ide-zips/2023.1.1.28/android-studio-2023.1.1.28-linux.tar.gz
tar -xvf android-studio-*-linux.tar.gz
cd android-studio/bin
./studio.sh
```

## Flutter SDK Kurulumu

### Windows

1. [Flutter SDK'yı indirin](https://docs.flutter.dev/get-started/install/windows)
2. ZIP dosyasını `C:\src\flutter` gibi bir konuma açın
3. Sistem ortam değişkenlerine `flutter\bin` yolunu ekleyin:
   - Başlat > "Ortam değişkenlerini düzenle" arayın
   - "Path" değişkenine `C:\src\flutter\bin` ekleyin
4. Komut istemini açın ve doğrulayın:
   ```cmd
   flutter doctor
   ```

### macOS

```bash
# Flutter SDK'yı indirin
cd ~/development
git clone https://github.com/flutter/flutter.git -b stable

# PATH'e ekleyin
echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zshrc
source ~/.zshrc

# Doğrulayın
flutter doctor
```

### Linux

```bash
# Flutter SDK'yı indirin
cd ~/development
git clone https://github.com/flutter/flutter.git -b stable

# PATH'e ekleyin
echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.bashrc
source ~/.bashrc

# Doğrulayın
flutter doctor
```

### Flutter Doctor Kontrolleri

`flutter doctor` komutunu çalıştırın ve eksik bileşenleri kurun:

```bash
flutter doctor
```

Çıktı şuna benzer olmalı:
```
Doctor summary (to see all details, run flutter doctor -v):
[✓] Flutter (Channel stable, 3.24.5, on macOS)
[✓] Android toolchain - develop for Android devices
[✓] Xcode - develop for iOS and macOS (Xcode 15.0)
[✓] Chrome - develop for the web
[✓] Android Studio (version 2023.1)
[✓] VS Code (version 1.85)
[✓] Connected device (2 available)
```

## Projeyi Açma

### Adım 1: Projeyi Ayıklayın

`user_role_management.zip` dosyasını istediğiniz bir konuma ayıklayın.

### Adım 2: Android Studio'da Açın

1. Android Studio'yu başlatın
2. "Open" veya "Open an Existing Project" seçeneğini tıklayın
3. `user_role_management` klasörünü seçin
4. "OK" tıklayın

### Adım 3: Bağımlılıkları Yükleyin

Android Studio projeyi açtığında otomatik olarak `flutter pub get` komutunu çalıştırır. Eğer çalışmazsa:

1. Terminal'i açın (View > Tool Windows > Terminal)
2. Şu komutu çalıştırın:
   ```bash
   flutter pub get
   ```

## Firebase Yapılandırması

### Adım 1: Firebase Console'a Giriş

1. [Firebase Console](https://console.firebase.google.com/) adresine gidin
2. Google hesabınızla giriş yapın
3. Mevcut projenizi seçin: **denem01-1fe53**

### Adım 2: Authentication'ı Etkinleştirin

1. Sol menüden **Build > Authentication** seçin
2. "Get started" butonuna tıklayın
3. **Sign-in method** sekmesine gidin
4. **Email/Password** seçeneğini bulun
5. "Enable" butonunu açın
6. "Save" tıklayın

### Adım 3: Firestore Database Oluşturun

1. Sol menüden **Build > Firestore Database** seçin
2. "Create database" butonuna tıklayın
3. **Test mode** seçin (geliştirme için)
4. Lokasyon seçin (örn: `europe-west1`)
5. "Enable" tıklayın

### Adım 4: Firestore Güvenlik Kuralları (Opsiyonel)

Üretim için güvenlik kurallarını güncelleyin:

1. Firestore Database > Rules sekmesine gidin
2. Aşağıdaki kuralları yapıştırın:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                      (request.auth.uid == userId || 
                       get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
    }
  }
}
```

3. "Publish" tıklayın

## Demo Kullanıcıları Oluşturma

### Adım 1: Authentication'da Kullanıcı Ekleyin

1. Firebase Console > **Authentication > Users** sekmesine gidin
2. "Add user" butonuna tıklayın
3. Aşağıdaki kullanıcıları tek tek ekleyin:

| Email | Şifre | Rol |
|-------|-------|-----|
| fatma@example.com | password | captain |
| admin@example.com | password | admin |
| user@example.com | password | user |

### Adım 2: Firestore'da Kullanıcı Dokümanları Oluşturun

Her kullanıcı için Firestore'da bir doküman oluşturun:

1. Firestore Database > Data sekmesine gidin
2. "Start collection" tıklayın
3. Collection ID: `users`
4. İlk dokümanı ekleyin:
   - **Document ID**: Authentication'dan aldığınız kullanıcının UID'sini kullanın
   - Alanları ekleyin:

**Fatma (Captain) için:**
```
email: fatma@example.com (string)
displayName: Fatma Yılmaz (string)
role: captain (string)
createdAt: (timestamp - şu anki zaman)
lastLogin: null
teamId: null
```

**Admin için:**
```
email: admin@example.com (string)
displayName: Admin Kullanıcı (string)
role: admin (string)
createdAt: (timestamp - şu anki zaman)
lastLogin: null
teamId: null
```

**User için:**
```
email: user@example.com (string)
displayName: Normal Kullanıcı (string)
role: user (string)
createdAt: (timestamp - şu anki zaman)
lastLogin: null
teamId: null
```

**ÖNEMLİ**: Document ID'nin Authentication'daki kullanıcının UID'si ile aynı olması gerekir!

### Hızlı Yöntem: Firebase Console Script

Alternatif olarak, Firebase Console'da şu scripti çalıştırabilirsiniz (Firestore > Rules > Playground):

```javascript
// Bu kodu doğrudan Firestore'a ekleyemezsiniz, 
// ancak Firebase Admin SDK ile çalıştırabilirsiniz
```

## Uygulamayı Çalıştırma

### Android Emulator ile

1. Android Studio'da **Tools > Device Manager** açın
2. "Create Device" tıklayın
3. Bir cihaz seçin (örn: Pixel 6)
4. Sistem imajı indirin (örn: Android 13)
5. Emulator'ü başlatın
6. Android Studio'da yeşil "Run" butonuna tıklayın

### Fiziksel Android Cihaz ile

1. Cihazınızda **Geliştirici Seçenekleri**'ni etkinleştirin:
   - Ayarlar > Telefon Hakkında
   - "Yapı Numarası"na 7 kez dokunun
2. **USB Hata Ayıklama**'yı açın:
   - Ayarlar > Geliştirici Seçenekleri
   - USB Hata Ayıklama'yı etkinleştirin
3. Cihazı USB ile bilgisayara bağlayın
4. Android Studio'da cihazınızı seçin
5. "Run" butonuna tıklayın

### Web Tarayıcı ile

```bash
flutter run -d chrome
```

### iOS Simulator ile (Sadece macOS)

```bash
open -a Simulator
flutter run
```

## Sorun Giderme

### Gradle Build Hatası

**Hata**: `Could not resolve all files for configuration`

**Çözüm**:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### Firebase Bağlantı Hatası

**Hata**: `[core/no-app] No Firebase App '[DEFAULT]' has been created`

**Çözüm**:
- `firebase_options.dart` dosyasının `lib` klasöründe olduğundan emin olun
- `main.dart` dosyasında import edildiğini kontrol edin
- Uygulamayı yeniden başlatın

### Kullanıcı Giriş Yapamıyor

**Olası Nedenler**:
1. Firebase Authentication etkinleştirilmemiş
2. Email/Password sign-in method aktif değil
3. Firestore'da kullanıcı dokümanı yok
4. Document ID ile Authentication UID eşleşmiyor

**Çözüm**:
1. Firebase Console > Authentication'ı kontrol edin
2. Firestore'da `users` koleksiyonunu kontrol edin
3. Document ID'lerin doğru olduğundan emin olun

### Flutter Doctor Sorunları

**Android License Hatası**:
```bash
flutter doctor --android-licenses
```

**Xcode Hatası (macOS)**:
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

### Bağımlılık Çakışması

```bash
flutter pub upgrade --major-versions
flutter pub get
```

## Ek Kaynaklar

- [Flutter Dokümantasyonu](https://docs.flutter.dev/)
- [Firebase Flutter Dokümantasyonu](https://firebase.google.com/docs/flutter/setup)
- [Android Studio Kullanım Kılavuzu](https://developer.android.com/studio/intro)
- [Dart Programlama Dili](https://dart.dev/guides)

## Destek

Sorunlarınız devam ediyorsa:

1. `flutter doctor -v` çıktısını kontrol edin
2. Android Studio'nun güncel olduğundan emin olun
3. Flutter SDK'nın güncel olduğundan emin olun
4. Proje klasöründe `flutter clean` çalıştırın

---

**Son Güncelleme**: Ekim 2025  
**Flutter Versiyon**: 3.24.5  
**Android Studio**: 2023.1 veya üzeri
