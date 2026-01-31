import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mevcut kullanıcı stream'i
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Mevcut kullanıcının UserModel verilerini stream olarak getir
  Stream<UserModel?> get currentUserDataStream {
    if (currentUser == null) {
      return Stream.value(null);
    }
    return getUserDataStream(currentUser!.uid);
  }

  // Mevcut kullanıcı
  User? get currentUser => _auth.currentUser;

  // Email/Şifre ile giriş
  Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Kullanıcı dokümanının var olup olmadığını kontrol et
      await _ensureUserDocument(userCredential.user!);

      // Son giriş zamanını güncelle
      await _updateLastLogin(userCredential.user!.uid);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Kullanıcı dokümanının var olduğundan emin ol
  Future<void> _ensureUserDocument(User user) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        // Doküman yoksa oluştur
        String displayName = user.displayName ?? user.email?.split('@')[0] ?? 'Kullanıcı';
        String role = 'user'; // Varsayılan rol

        // Email'e göre özel rol ata
        if (user.email == 'keremuzuner1907@gmail.com') {
          role = 'admin';
          displayName = 'Kerem Uzuner';
        }

        // Captain ise teamId'sini kendi uid'sine eşitle
        String? teamId;
        String? captainId;

        if (role == 'captain') {
          teamId = user.uid; // Kaptan kendi takımının ID'sine sahip
        }

        await _createUserDocument(
          uid: user.uid,
          email: user.email!,
          displayName: displayName,
          role: role,
          teamId: teamId,
          captainId: captainId,
        );

        print('Kullanıcı dokümanı oluşturuldu: ${user.email} (role: $role, teamId: $teamId)');
      }
    } catch (e) {
      print('Kullanıcı dokümanı kontrolü hatası: $e');
    }
  }

  // Email/Şifre ile kayıt (Admin tarafından)
  Future<UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
    String role = 'user',
    String? teamId,
    String? captainId,
    bool keepAdminSession = false,
    String? adminEmail,
    String? adminPassword,
  }) async {
    try {
      // Mevcut admin'i sakla (şifre varsa)
      User? currentAdmin = _auth.currentUser;
      bool shouldRestoreAdmin = keepAdminSession &&
          adminEmail != null &&
          adminPassword != null &&
          currentAdmin != null;

      // Yeni kullanıcıyı oluştur
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Kullanıcı profilini güncelle
      await userCredential.user!.updateDisplayName(displayName);

      // Rol bazlı teamId ayarlaması
      String? finalTeamId = teamId;
      String? finalCaptainId = captainId;

      // Eğer kaptan ise, teamId'yi kendi uid'si yap
      if (role == 'captain') {
        finalTeamId = userCredential.user!.uid;
        finalCaptainId = null; // Kaptanın captainId'si yok
      }

      // Firestore'a kullanıcı verilerini kaydet
      await _createUserDocument(
        uid: userCredential.user!.uid,
        email: email,
        displayName: displayName,
        role: role,
        teamId: finalTeamId,
        captainId: finalCaptainId,
      );

      print('✅ Yeni kullanıcı oluşturuldu:');
      print('   Email: $email');
      print('   Rol: $role');
      print('   TeamId: $finalTeamId');
      print('   CaptainId: $finalCaptainId');

      // Admin oturumunu geri al (şifre verildiyse)
      if (shouldRestoreAdmin) {
        try {
          // Yeni oluşturulan kullanıcıyı signOut et
          await _auth.signOut();

          // Admin'i geri oturum aç
          UserCredential adminCredential = await _auth.signInWithEmailAndPassword(
            email: adminEmail,
            password: adminPassword,
          );

          print('✅ Admin oturumu geri alındı: $adminEmail');

          // Admin'in son giriş zamanını güncelle
          await _updateLastLogin(adminCredential.user!.uid);
        } catch (e) {
          print('⚠️ Admin oturumuna dönüşte hata: $e');
          // Hata olsa bile devam et
          rethrow;
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Kullanıcı dokümanı oluştur
  Future<void> _createUserDocument({
    required String uid,
    required String email,
    required String displayName,
    required String role,
    String? teamId,
    String? captainId,
  }) async {
    final userModel = UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      role: role,
      teamId: teamId,
      captainId: captainId,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
      totalScore: 0,
      monthlyScores: {},
    );

    await _firestore.collection('users').doc(uid).set(userModel.toMap());
  }

  // Son giriş zamanını güncelle
  Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLogin': Timestamp.now(),
      });
    } catch (e) {
      print('Son giriş zamanı güncellenemedi: $e');
      // Hata olsa bile devam et
    }
  }

  // Kullanıcı verilerini getir
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Kullanıcı verileri alınamadı: $e');
      return null;
    }
  }

  // Kullanıcı verilerini stream olarak getir
  Stream<UserModel?> getUserDataStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // Şifre sıfırlama emaili gönder
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Auth hatalarını işle
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Bu email adresiyle kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Hatalı şifre.';
      case 'email-already-in-use':
        return 'Bu email adresi zaten kullanımda.';
      case 'invalid-email':
        return 'Geçersiz email adresi.';
      case 'weak-password':
        return 'Şifre çok zayıf. En az 6 karakter olmalı.';
      case 'user-disabled':
        return 'Bu kullanıcı hesabı devre dışı bırakılmış.';
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin.';
      case 'operation-not-allowed':
        return 'Bu işlem şu anda kullanılamıyor.';
      default:
        return 'Bir hata oluştu: ${e.message}';
    }
  }
}
