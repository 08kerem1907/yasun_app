# Takım Yönetim Sistemi - User Role Management App

Firebase entegrasyonlu, modern bir kullanıcı rol yönetimi uygulaması. Bu Flutter projesi, Figma tasarımına sadık kalarak geliştirilmiş olup, kullanıcı kimlik doğrulama, rol bazlı erişim kontrolü ve takım yönetimi özelliklerini içermektedir.

## Özellikler

### 🔐 Kimlik Doğrulama
- **Email/Şifre ile Giriş**: Firebase Authentication kullanarak güvenli giriş sistemi
- **Oturum Yönetimi**: Otomatik oturum kontrolü ve yönlendirme
- **Şifre Sıfırlama**: Email ile şifre sıfırlama desteği

### 👥 Kullanıcı Yönetimi
- **Kullanıcı Listesi**: Tüm kullanıcıları görüntüleme ve filtreleme
- **Rol Bazlı Filtreleme**: Yönetici, Kaptan ve Kullanıcı rollerine göre filtreleme
- **Kullanıcı Detayları**: Detaylı kullanıcı bilgilerini görüntüleme
- **Rol Düzenleme**: Kullanıcı rollerini güncelleme (yetki gerektirir)
- **Kullanıcı Silme**: Kullanıcıları sistemden kaldırma (yetki gerektirir)

### 📊 Dashboard
- **İstatistikler**: Toplam kullanıcı, rol bazlı kullanıcı sayıları
- **Hızlı İşlemler**: Sık kullanılan işlemlere hızlı erişim
- **Kişiselleştirilmiş Karşılama**: Kullanıcı adı ve rol bilgisi gösterimi

### 🎨 Kullanıcı Arayüzü
- **Modern Tasarım**: Material Design 3 prensipleri
- **Gradient Efektler**: Mor/mavi gradient arka planlar
- **Responsive Layout**: Farklı ekran boyutlarına uyumlu
- **Smooth Animations**: Akıcı geçişler ve animasyonlar

## Rol Sistemi

Uygulama üç farklı kullanıcı rolü desteklemektedir:

| Rol | İkon | Renk | Yetkiler |
|-----|------|------|----------|
| **Yönetici (Admin)** | 🛡️ | Kırmızı | Tüm yetkiler, kullanıcı ekleme/silme/düzenleme |
| **Kaptan (Captain)** | ⭐ | Turuncu | Kullanıcı görüntüleme, rol düzenleme |
| **Kullanıcı (User)** | 👤 | Yeşil | Temel görüntüleme yetkileri |

## Teknoloji Stack

### Frontend
- **Flutter**: 3.24.5
- **Dart**: 3.5.4
- **Material Design 3**: Modern UI bileşenleri

### Backend & Veritabanı
- **Firebase Authentication**: Kullanıcı kimlik doğrulama
- **Cloud Firestore**: NoSQL veritabanı
- **Firebase Core**: Temel Firebase servisleri

### State Management & Utilities
- **Provider**: 6.1.2 - State management
- **Google Fonts**: 6.2.1 - Özel fontlar
- **Intl**: 0.19.0 - Tarih/saat formatlama

## Proje Yapısı

```
lib/
├── constants/
│   └── colors.dart              # Renk sabitleri ve gradient tanımları
├── models/
│   └── user_model.dart          # Kullanıcı veri modeli
├── screens/
│   ├── login_screen.dart        # Giriş ekranı
│   ├── home_screen.dart         # Ana sayfa/Dashboard
│   └── users_list_screen.dart   # Kullanıcı listesi ekranı
├── services/
│   ├── auth_service.dart        # Authentication servisi
│   └── user_service.dart        # Kullanıcı yönetim servisi
├── firebase_options.dart        # Firebase yapılandırması
└── main.dart                    # Uygulama giriş noktası
```

## Kurulum

### Gereksinimler
- Flutter SDK (3.24.5 veya üzeri)
- Dart SDK (3.5.4 veya üzeri)
- Android Studio veya VS Code
- Firebase hesabı ve projesi

### Adımlar

1. **Projeyi İndirin**
   ```bash
   # ZIP dosyasını açın veya
   git clone <repository-url>
   cd user_role_management
   ```

2. **Bağımlılıkları Yükleyin**
   ```bash
   flutter pub get
   ```

3. **Firebase Yapılandırması**
   
   Firebase yapılandırma dosyası (`firebase_options.dart`) zaten projeye dahil edilmiştir. Eğer kendi Firebase projenizi kullanmak isterseniz:
   
   - Firebase Console'da yeni bir proje oluşturun
   - FlutterFire CLI'yi kurun:
     ```bash
     dart pub global activate flutterfire_cli
     ```
   - Firebase'i yapılandırın:
     ```bash
     flutterfire configure
     ```

4. **Firebase Authentication'ı Etkinleştirin**
   
   Firebase Console'da:
   - Authentication > Sign-in method
   - Email/Password'ü etkinleştirin

5. **Firestore Veritabanını Oluşturun**
   
   Firebase Console'da:
   - Firestore Database oluşturun
   - Test modunda başlatın (daha sonra güvenlik kurallarını ekleyebilirsiniz)

6. **Demo Kullanıcıları Ekleyin** (Opsiyonel)
   
   Firebase Console > Authentication > Users bölümünden manuel olarak ekleyin:
   - fatma@example.com (şifre: password)
   - admin@example.com (şifre: password)
   - user@example.com (şifre: password)
   
   Ardından Firestore'da `users` koleksiyonunda her kullanıcı için bir doküman oluşturun:
   ```json
   {
     "email": "fatma@example.com",
     "displayName": "Fatma Yılmaz",
     "role": "captain",
     "createdAt": "2024-01-01T00:00:00Z",
     "lastLogin": null,
     "teamId": null
   }
   ```

## Çalıştırma

### Android
```bash
flutter run
```

### Web
```bash
flutter run -d chrome
```

### iOS (macOS gerektirir)
```bash
flutter run -d ios
```

## Firebase Güvenlik Kuralları

Üretim ortamı için aşağıdaki Firestore güvenlik kurallarını kullanmanız önerilir:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Kullanıcılar koleksiyonu
    match /users/{userId} {
      // Herkes kendi verilerini okuyabilir
      allow read: if request.auth != null && request.auth.uid == userId;
      
      // Sadece admin'ler tüm kullanıcıları görebilir
      allow read: if request.auth != null && 
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
      
      // Sadece admin'ler kullanıcı oluşturabilir
      allow create: if request.auth != null && 
                       get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
      
      // Admin ve captain'lar rol güncelleyebilir
      allow update: if request.auth != null && 
                       (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin' ||
                        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'captain');
      
      // Sadece admin'ler kullanıcı silebilir
      allow delete: if request.auth != null && 
                       get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

## Ekran Görüntüleri

### Giriş Ekranı
- Modern gradient arka plan
- Email ve şifre input alanları
- Demo hesapları bölümü
- Responsive tasarım

### Ana Sayfa (Dashboard)
- Kullanıcı karşılama bölümü
- İstatistik kartları (toplam kullanıcı, rol dağılımı)
- Hızlı işlem kartları
- Rol bazlı menü görünürlüğü

### Kullanıcı Listesi
- Filtreleme chip'leri (Tümü, Yönetici, Kaptan, Kullanıcı)
- Kullanıcı kartları (avatar, isim, email, rol, son giriş)
- Kullanıcı detay dialog'u
- Rol değiştirme ve silme işlemleri

## Geliştirme Notları

### Veri Modeli

**UserModel** sınıfı aşağıdaki özellikleri içerir:
- `uid`: Kullanıcı benzersiz kimliği
- `email`: Email adresi
- `displayName`: Görünen ad
- `role`: Kullanıcı rolü (admin, captain, user)
- `teamId`: Takım kimliği (opsiyonel)
- `createdAt`: Hesap oluşturma tarihi
- `lastLogin`: Son giriş tarihi

### Servisler

**AuthService**: Firebase Authentication işlemlerini yönetir
- `signInWithEmailPassword()`: Giriş yapma
- `signUpWithEmailPassword()`: Kayıt olma
- `signOut()`: Çıkış yapma
- `getUserData()`: Kullanıcı verilerini getirme
- `sendPasswordResetEmail()`: Şifre sıfırlama

**UserService**: Firestore kullanıcı işlemlerini yönetir
- `getAllUsers()`: Tüm kullanıcıları getir
- `getUsersByRole()`: Role göre filtrele
- `updateUserRole()`: Rol güncelle
- `deleteUser()`: Kullanıcı sil
- `getUserCountByRole()`: Rol bazlı istatistikler

## Bilinen Sorunlar ve Geliştirme Önerileri

### Yapılacaklar
- [ ] Kullanıcı arama fonksiyonu
- [ ] Yeni kullanıcı ekleme ekranı
- [ ] Profil düzenleme ekranı
- [ ] Takım yönetimi özellikleri
- [ ] Push notification desteği
- [ ] Dark mode desteği
- [ ] Çoklu dil desteği (i18n)
- [ ] Offline mode desteği
- [ ] Birim testleri
- [ ] Widget testleri

### Performans İyileştirmeleri
- Kullanıcı listesinde pagination eklenebilir
- Image caching optimize edilebilir
- Lazy loading uygulanabilir

## Lisans

Bu proje eğitim ve demo amaçlı oluşturulmuştur.

## İletişim

Sorularınız veya önerileriniz için lütfen iletişime geçin.

---

**Geliştirici**: Manus AI  
**Tarih**: Ekim 2025  
**Flutter Versiyon**: 3.24.5  
**Firebase**: Cloud Firestore + Authentication
