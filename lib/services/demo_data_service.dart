import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DemoDataService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Demo kullanıcıları oluştur
  Future<void> createDemoUsers() async {
    try {
      // Demo kullanıcı bilgileri
      final demoUsers = [
        {
          'email': 'admin@example.com',
          'password': 'password',
          'displayName': 'Admin Kullanıcı',
          'role': 'admin',
        },
        {
          'email': 'keremuzuner1907@gmail.com',
          'password': 'password',
          'displayName': 'Kerem Uzuner',
          'role': 'captain',
        },
        {
          'email': 'user@example.com',
          'password': 'password',
          'displayName': 'Normal Kullanıcı',
          'role': 'user',
        },
      ];

      for (var userData in demoUsers) {
        try {
          // Kullanıcının zaten var olup olmadığını kontrol et
          final methods = await _auth.fetchSignInMethodsForEmail(userData['email'] as String);

          if (methods.isEmpty) {
            // Kullanıcı yoksa oluştur
            UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
              email: userData['email'] as String,
              password: userData['password'] as String,
            );

            // Display name güncelle
            await userCredential.user!.updateDisplayName(userData['displayName'] as String);

            // ✅ Captain ise teamId'sini kendi uid'sine eşitle
            String? teamId;
            if (userData['role'] == 'captain') {
              teamId = userCredential.user!.uid;
            }

            // Firestore'a kullanıcı verilerini kaydet
            await _firestore.collection('users').doc(userCredential.user!.uid).set({
              'email': userData['email'],
              'displayName': userData['displayName'],
              'role': userData['role'],
              'createdAt': Timestamp.now(),
              'lastLogin': null,
              'teamId': teamId,
              'totalScore': 0,
              'monthlyScores': {},
            });

            print('✅ Demo kullanıcı oluşturuldu: ${userData['email']} (role: ${userData['role']}, teamId: $teamId)');
          } else {
            print('ℹ️  Kullanıcı zaten mevcut: ${userData['email']}');
          }
        } catch (e) {
          print('Kullanıcı oluşturma hatası (${userData['email']}): $e');
        }
      }

      print('Demo kullanıcılar kontrol edildi/oluşturuldu');
    } catch (e) {
      print('Demo veri oluşturma hatası: $e');
    }
  }

  // Firestore'da kullanıcı dokümanlarını kontrol et ve eksikleri oluştur
  Future<void> ensureUserDocuments() async {
    try {
      // Tüm Authentication kullanıcılarını al
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Mevcut kullanıcı için doküman kontrol et
      DocumentSnapshot doc = await _firestore.collection('users').doc(currentUser.uid).get();

      if (!doc.exists) {
        // Doküman yoksa oluştur
        String displayName = currentUser.displayName ?? currentUser.email?.split('@')[0] ?? 'Kullanıcı';
        String role = 'user';

        // Email'e göre rol ata
        if (currentUser.email == 'admin@example.com') {
          role = 'admin';
          displayName = 'Admin Kullanıcı';
        } else if (currentUser.email == 'keremuzuner1907@gmail.com') {
          role = 'captain';
          displayName = 'Kerem Uzuner';
        } else if (currentUser.email == 'user@example.com') {
          displayName = 'Normal Kullanıcı';
        }

        await _firestore.collection('users').doc(currentUser.uid).set({
          'email': currentUser.email,
          'displayName': displayName,
          'role': role,
          'createdAt': Timestamp.now(),
          'lastLogin': Timestamp.now(),
          'teamId': null,
        });

        print('Kullanıcı dokümanı oluşturuldu: ${currentUser.email}');
      }
    } catch (e) {
      print('Kullanıcı dokümanı kontrol hatası: $e');
    }
  }

  // ✅ YENİ: Tüm captain'ların teamId'lerini düzeltme fonksiyonu
  Future<void> fixAllCaptainTeamIds() async {
    try {
      print('🔧 Tüm captain teamId\'leri düzeltiliyor...');

      final captainsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'captain')
          .get();

      int fixedCount = 0;
      int alreadyCorrect = 0;

      for (var doc in captainsSnapshot.docs) {
        final data = doc.data();
        final currentTeamId = data['teamId'];

        if (currentTeamId != doc.id) {
          await _firestore.collection('users').doc(doc.id).update({
            'teamId': doc.id,
          });
          print('✅ Düzeltildi: ${data['displayName']} (${data['email']})');
          fixedCount++;
        } else {
          print('ℹ️  Zaten doğru: ${data['displayName']}');
          alreadyCorrect++;
        }
      }

      print('\n📊 Özet:');
      print('Toplam Captain: ${captainsSnapshot.docs.length}');
      print('Düzeltilen: $fixedCount');
      print('Zaten Doğru: $alreadyCorrect');
      print('✅ İşlem tamamlandı!');
    } catch (e) {
      print('❌ Captain teamId düzeltme hatası: $e');
      rethrow;
    }
  }
}