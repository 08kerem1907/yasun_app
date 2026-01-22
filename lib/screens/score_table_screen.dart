import 'package:flutter/material.dart';
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_currentUser == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: colorScheme.primary,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: Row(
          children: [
            Icon(
              Icons.leaderboard_rounded,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Puan Tablosu',
              style:
              textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
            ),
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
            dropdownColor: colorScheme.surface,
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
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
            icon: Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              color: colorScheme.onSurface,
            ),
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
            return Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Hata: ${snapshot.error}',
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'Henüz kullanıcı bulunmamaktadır.',
                style: textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            );
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

              // Görev Sonuçları Butonunun Görünürlük Mantığı
              final bool isOwnProfile = _currentUser!.uid == user.uid;

              return Card(
                color: colorScheme.surface,
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.workspace_premium_rounded,
                              color: colorScheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Rol: ${user.roleDisplayName}',
                            style: textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.military_tech_rounded,
                              color: colorScheme.secondary),
                          const SizedBox(width: 6),
                          Text(
                            'Toplam Puan: ${user.totalScore}',
                            style: textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.trending_up_rounded,
                              color: colorScheme.tertiary),
                          const SizedBox(width: 6),
                          Text(
                            'Bu Ayki Puan: $monthlyScore',
                            style: textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    GorevSonuclariScreen(user: user),
                              ),
                            );
                          },
                          child: isOwnProfile
                              ? const Text('Kendi Görev Sonuçlarım')
                              : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.assignment_turned_in_rounded,
                                  size: 18),
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
