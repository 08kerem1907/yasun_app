import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mevcut kullanıcı stream'i
  Stream<User?> get authStateChanges => _auth.authStateChanges();

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
        if (user.email == 'admin@example.com') {
          role = 'admin';
          displayName = 'Admin Kullanıcı';
        } else if (user.email == 'keremuzuner1907@gmail.com') {
          role = 'captain';
          displayName = 'Kerem Uzuner';
        } else if (user.email == 'user@example.com') {
          displayName = 'Normal Kullanıcı';
        }
        
        await _createUserDocument(
          uid: user.uid,
          email: user.email!,
          displayName: displayName,
          role: role,
        );
        
        print('Kullanıcı dokümanı oluşturuldu: ${user.email}');
      }
    } catch (e) {
      print('Kullanıcı dokümanı kontrolü hatası: $e');
    }
  }

  // Email/Şifre ile kayıt
  Future<UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
    String role = 'user',
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Kullanıcı profilini güncelle
      await userCredential.user!.updateDisplayName(displayName);

      // Firestore'a kullanıcı verilerini kaydet
      await _createUserDocument(
        uid: userCredential.user!.uid,
        email: email,
        displayName: displayName,
        role: role,
      );

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
  }) async {
    final userModel = UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      role: role,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
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
