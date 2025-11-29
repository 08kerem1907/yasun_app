import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../services/user_service.dart';
import 'gorev_sonuclari_screen.dart'; // ✅ YENİ: Görev sonuçları ekranı eklendi

enum ScoreSortType {
  totalScore,
  monthlyScore,
}

class ScoreTableScreen extends StatefulWidget {
  const ScoreTableScreen({super.key});

  @override
  State<ScoreTableScreen> createState() => _ScoreTableScreenState();
}

class _ScoreTableScreenState extends State<ScoreTableScreen> {
  final UserService _userService = UserService();
  UserModel? _currentUser;
  ScoreSortType _currentSortType = ScoreSortType.totalScore;
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      UserModel? user = await _userService.getUser(firebaseUser.uid);
      setState(() {
        _currentUser = user;
      });
    }
  }

  String _getCurrentMonthKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(
              Icons.leaderboard_rounded,
              color: Colors.deepPurple, // veya Colors.indigo
            ),
            SizedBox(width: 8),
            Text('Puan Tablosu'),
          ],
        ),
        actions: [
          DropdownButton<ScoreSortType>(
            value: _currentSortType,
            onChanged: (ScoreSortType? newValue) {
              if (newValue != null) {
                setState(() {
                  _currentSortType = newValue;
                  _sortAscending = false;
                });
              }
            },
            items: const [
              DropdownMenuItem(
                value: ScoreSortType.totalScore,
                child: Text('Toplam Puana Göre'),
              ),
              DropdownMenuItem(
                value: ScoreSortType.monthlyScore,
                child: Text('Aylık Puana Göre'),
              ),
            ],
          ),
          IconButton(
            icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
            onPressed: () {
              setState(() {
                _sortAscending = !_sortAscending;
              });
            },
          ),
        ],
      ),

      body: StreamBuilder<List<UserModel>>(
        stream: _userService.getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Henüz kullanıcı bulunmamaktadır.'));
          }

          List<UserModel> users = snapshot.data!;

          // Sıralama işlemi
          users.sort((a, b) {
            int compareResult = 0;
            if (_currentSortType == ScoreSortType.totalScore) {
              compareResult = a.totalScore.compareTo(b.totalScore);
            } else if (_currentSortType == ScoreSortType.monthlyScore) {
              final currentMonthKey = _getCurrentMonthKey();
              final aMonthlyScore = a.monthlyScores[currentMonthKey] ?? 0;
              final bMonthlyScore = b.monthlyScores[currentMonthKey] ?? 0;
              compareResult = aMonthlyScore.compareTo(bMonthlyScore);
            }
            return _sortAscending ? compareResult : -compareResult;
          });

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final currentMonthKey = _getCurrentMonthKey();
              final monthlyScore = user.monthlyScores[currentMonthKey] ?? 0;

              // Görev Sonuçları Butonunun Görünürlük Mantığı için değişkenler
              final bool isOwnProfile = _currentUser!.uid == user.uid;
              final bool isTeamMember = _currentUser!.teamId != null && _currentUser!.teamId == user.teamId;
              final bool canSeeOthersResults = _currentUser!.isAdmin || // Yönetici herkesi görür
                  (isTeamMember && !isOwnProfile); // Kaptan/Üye kendi takım arkadaşını görür

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.workspace_premium_rounded, color: Colors.deepPurple),
                          const SizedBox(width: 6),
                          Text('Rol: ${user.roleDisplayName}'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.military_tech_rounded, color: Colors.amber),
                          const SizedBox(width: 6),
                          Text('Toplam Puan: ${user.totalScore}'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.trending_up_rounded, color: Colors.blueAccent),
                          const SizedBox(width: 6),
                          Text('Bu Ayki Puan: $monthlyScore'),
                        ],
                      ),


                      if (isOwnProfile)
                        Align(
                          alignment: Alignment.bottomRight,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GorevSonuclariScreen(user: user),
                                ),
                              );
                            },
                            child: const Text('Kendi Görev Sonuçlarım'),
                          ),
                        )
                      else if (canSeeOthersResults)
                        Align(
                          alignment: Alignment.bottomRight,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GorevSonuclariScreen(user: user),
                                ),
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.assignment_turned_in_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Text('Görev Sonuçları'),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
