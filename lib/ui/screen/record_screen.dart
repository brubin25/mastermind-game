// lib/ui/screen/record_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class Record {
  final String gameMode;
  final int timeTaken;
  final DateTime timestamp;

  Record({
    required this.gameMode,
    required this.timeTaken,
    required this.timestamp,
  });
}

class RecordScreen extends StatefulWidget {
  const RecordScreen({Key? key}) : super(key: key);

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final _dbRef = FirebaseDatabase.instance.ref();
  List<Record> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  Future<void> _fetchRecords() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // final snapshot = await _dbRef.child('records').child(user.uid).once();
      // final data = snapshot.value as Map<dynamic, dynamic>?;
      DataSnapshot snapshot = await _dbRef.child(user.uid).get();

      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        final List<Record> temp = [];
        data.forEach((key, value) {
          final gameMode = value['gameMode'] as String? ?? '';
          final time = value['timeTaken'] as int? ?? 0;
          final ts = value['timestamp'] as int? ?? 0;
          temp.add(Record(
            gameMode: gameMode,
            timeTaken: time,
            timestamp: DateTime.fromMillisecondsSinceEpoch(ts),
          ));
        });
        // 按时间倒序排列
        temp.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        setState(() {
          _records = temp;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e){
      // Capture errors (network, permissions, etc.)
      setState(() {
        _records = [];
        _isLoading = false;
      });

    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My History'),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
        ),
      )
          : _records.isEmpty
          ? Center(
        child: Text(
          'No records yet!',
          style: TextStyle(
            fontSize: 16,
            color: theme.textTheme.bodyMedium!.color,
          ),
        ),
      )
          : ListView.builder(
        itemCount: _records.length,
        itemBuilder: (context, index) {
          final record = _records[index];
          final minutes = record.timeTaken ~/ 60;
          final seconds = record.timeTaken % 60;
          return Card(
            color: theme.cardColor,
            margin:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(
                Icons.history,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                record.gameMode,
                style: TextStyle(
                  color: theme.textTheme.bodyMedium!.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Time: ${minutes}m ${seconds}s\n'
                    'Played on: ${record.timestamp.year}-${record.timestamp.month.toString().padLeft(2, '0')}-${record.timestamp.day.toString().padLeft(2, '0')} '
                    '${record.timestamp.hour.toString().padLeft(2, '0')}:${record.timestamp.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: theme.textTheme.bodySmall!.color,
                  fontSize: 14,
                ),
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
