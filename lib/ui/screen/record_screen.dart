import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mastermind_game/models/game_mode.dart';
import 'package:mastermind_game/ui/screen/game.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  static const int _initialTimeSec = 300;
  late final String _uid;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _uid = user?.uid ?? '';
  }

  @override
  Widget build(BuildContext context) {
    if (_uid.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('You must be signed in to view your records.'),
        ),
      );
    }

    final gamesQuery = FirebaseFirestore.instance
        .collection('games')
        .where('uid', isEqualTo: _uid)
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('My History')),
      body: StreamBuilder<QuerySnapshot>(
        stream: gamesQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading records: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No games found.\nPlay a round to see it here!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final Timestamp ts = data['createdAt'] as Timestamp;
              final DateTime date = ts.toDate();

              final steps = (data['steps'] as List<dynamic>?) ?? [];
              final String winOrLose = (data['winOrLose'] as String?) ?? 'lose';
              final bool isWon = winOrLose == 'win';
              final int remaining = (data['remainingTime'] as int?) ?? 0;
              final int spentSec = _initialTimeSec - remaining;
              final String formattedTime = _formatSeconds(spentSec);

              final String outcome = isWon ? 'WON' : 'LOST';
              final String title =
                  '$outcome in ${steps.length} steps, spent $formattedTime.';
              print(steps.map((step) => AnswerType.fromJson(step)).toList());

              return ListTile(
                onTap: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Game Details'),
                          content: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.8,
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: Answers(
                              answers:
                                  steps
                                      .map((step) => AnswerType.fromJson(step))
                                      .toList(),
                              maxDigits: 5,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                  );
                },
                leading: Lottie.asset(
                  'assets/images/victory.json',
                  width: 45,
                  height: 45,
                  fit: BoxFit.cover,
                ),
                title: Text(title, style: const TextStyle(fontSize: 18)),
                trailing: Lottie.asset(
                  'assets/images/confetti.json',
                  width: 45,
                  height: 45,
                  fit: BoxFit.cover,
                ),
                subtitle: Text(
                  'Played on ${_formatDateTime(date)}',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatSeconds(int total) {
    final minutes = (total ~/ 60).toString().padLeft(2, '0');
    final seconds = (total % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatDateTime(DateTime dt) {
    final month = _monthName(dt.month);
    final day = dt.day;
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$month $day, $year at $hour:$minute';
  }

  String _monthName(int monthIndex) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[monthIndex - 1];
  }
}
