import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  static const int _initialTimeSec = 300;
  late Future<List<_UserBest>> _leaderboardFuture;

  @override
  void initState() {
    super.initState();
    _leaderboardFuture = _fetchLeaderboardData();
  }

  // fetch all winning game documents
  Future<List<_UserBest>> _fetchLeaderboardData() async {
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('games')
            .where('remainingTime', isGreaterThanOrEqualTo: 0)
            .get();

    final Map<String, int> bestTimeMap = {};

    for (final doc in querySnapshot.docs) {
      final Map<String, dynamic> data = doc.data();

      // skip invalid documents
      if (!data.containsKey('remainingTime') || data['remainingTime'] == null) {
        continue;
      }
      if (!data.containsKey('email') || data['email'] == null) {
        continue;
      }

      final email = data['email'] as String;
      final remaining = data['remainingTime'] as int;

      final timeSpent = _initialTimeSec - remaining;

      if (!bestTimeMap.containsKey(email) || timeSpent < bestTimeMap[email]!) {
        bestTimeMap[email] = timeSpent;
      }
    }

    final List<_UserBest> list =
        bestTimeMap.entries
            .map((e) => _UserBest(email: e.key, timeSpent: e.value))
            .toList();

    list.sort((a, b) => a.timeSpent.compareTo(b.timeSpent));

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/wolf.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: FutureBuilder<List<_UserBest>>(
        future: _leaderboardFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading leaderboard:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<_UserBest> leaderboard = snapshot.data!;

          if (leaderboard.isEmpty) {
            return const Center(
              child: Text(
                'No records yet.\nBe the first to solve a game!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: leaderboard.length,
            separatorBuilder: (c, i) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = leaderboard[index];
              final rank = index + 1;
              final formatted = _formatSeconds(entry.timeSpent);
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF0D47A1),
                  child: Text(
                    '$rank',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(entry.email, style: TextStyle(fontSize: 18)),
                trailing: Text(formatted, style: const TextStyle(fontSize: 18)),
              );
            },
          );
        },
      ),
      ),
    );
  }

  /// convert seconds into MM:SS
  String _formatSeconds(int total) {
    final minutes = (total ~/ 60).toString().padLeft(2, '0');
    final seconds = (total % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _UserBest {
  final String email;
  final int timeSpent;
  _UserBest({required this.email, required this.timeSpent});
}
