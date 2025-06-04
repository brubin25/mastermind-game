// lib/ui/screen/leaderboard_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class LeaderboardEntry {
  final String username;
  final int bestTime; // 秒为单位
  LeaderboardEntry({required this.username, required this.bestTime});
}

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final _dbRef = FirebaseDatabase.instance.ref();
  List<LeaderboardEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    // final snapshot = await _dbRef.child('leaderboard').once();
    // final data = snapshot.value as Map<dynamic, dynamic>?;
    DataSnapshot snapshot = await _dbRef.get();
    final data = snapshot.value as Map<dynamic, dynamic>?; // 这里 snapshot.value 是动态类型，可能为 null
    if (data != null) {
      final List<LeaderboardEntry> temp = [];
      data.forEach((key, value) {
        final username = value['username'] as String? ?? 'N/A';
        final bestTime = value['bestTime'] as int? ?? 0;
        temp.add(LeaderboardEntry(username: username, bestTime: bestTime));
      });
      temp.sort((a, b) => a.bestTime.compareTo(b.bestTime));
      setState(() {
        _entries = temp;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor:
          AlwaysStoppedAnimation<Color>(theme.primaryColor),
        ),
      )
          : _entries.isEmpty
          ? Center(
        child: Text(
          'No leaderboard data.',
          style: TextStyle(
            fontSize: 16,
            color: theme.textTheme.bodyMedium!.color,
          ),
        ),
      )
          : ListView.builder(
        itemCount: _entries.length,
        itemBuilder: (context, index) {
          final entry = _entries[index];
          final minutes = entry.bestTime ~/ 60;
          final seconds = entry.bestTime % 60;
          return ListTile(
            leading: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 20,
                color: theme.textTheme.bodyMedium!.color,
              ),
            ),
            title: Text(
              entry.username,
              style: TextStyle(
                fontSize: 18,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Best Time: ${minutes}m ${seconds}s',
              style: TextStyle(
                color: theme.textTheme.bodySmall!.color,
                fontSize: 14,
              ),
            ),
          );
        },
      ),
    );
  }
}
