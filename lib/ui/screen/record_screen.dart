import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final int _initialTimeSec = 60;
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
      // screen only be reachable if the user is signed in
      return const Scaffold(
        body: Center(
          child: Text('You must be signed in to view your records.'),
        ),
      );
    }

    // all games for this user, most recent first
    final query = FirebaseFirestore.instance
        .collection('games')
        .where('uid', isEqualTo: _uid)
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('My History')),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
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

          // filter only the documents where the user won
          // final wonDocs =
          //     docs
          //         .where(
          //           (doc) =>
          //               doc.data() is Map<String, dynamic> &&
          //               (doc.data() as Map<String, dynamic>).containsKey(
          //                 'remainingTime',
          //               ),
          //         )
          //         .toList();

          // if (wonDocs.isEmpty) {
          //   return const Center(
          //     child: Text(
          //       'No completed games found.',
          //       style: TextStyle(fontSize: 16),
          //     ),
          //   );
          // }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final Timestamp ts = data['createdAt'] as Timestamp;
              final DateTime date = ts.toDate();

              final int remaining = (data['remainingTime'] as int?) ?? 0;
              final int spentSec = _initialTimeSec - remaining;
              final String formattedTime = _formatSeconds(spentSec);
              final bool isWon = data.containsKey('remainingTime');

              final String title =
                  (data['steps'] as List<dynamic>?) != null
                      ? '${data['steps'].length} steps ${isWon ? 'won' : 'lost'}'
                      : 'Lost';

              return ListTile(
                leading: Icon(
                  isWon ? Icons.thumb_up : Icons.thumb_down,
                  color: isWon ? Colors.green : Colors.red,
                ),
                title: Text(title, style: const TextStyle(fontSize: 18)),
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

  // seconds into MM:SS
  String _formatSeconds(int total) {
    final minutes = (total ~/ 60).toString().padLeft(2, '0');
    final seconds = (total % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // date/time
  String _formatDateTime(DateTime dt) {
    final datePart = '${_monthName(dt.month)} ${dt.day}, ${dt.year}';
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$datePart at $hour:$minute';
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
