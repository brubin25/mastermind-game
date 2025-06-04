// lib/ui/screen/two_player_lobby_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class TwoPlayerLobbyScreen extends StatefulWidget {
  const TwoPlayerLobbyScreen({Key? key}) : super(key: key);

  @override
  State<TwoPlayerLobbyScreen> createState() => _TwoPlayerLobbyScreenState();
}

class _TwoPlayerLobbyScreenState extends State<TwoPlayerLobbyScreen> {
  final _dbRef = FirebaseDatabase.instance.ref();
  String? _roomId;
  bool _isWaiting = false;
  StreamSubscription<DatabaseEvent>? _roomSubscription;

  @override
  void dispose() {
    _roomSubscription?.cancel();
    super.dispose();
  }

  Future<void> _createRoom() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final newRoomRef = _dbRef.child('rooms').push();
    final roomKey = newRoomRef.key!;
    await newRoomRef.set({
      'host': user.uid,
      'guest': '',
      'hostGuess': [],
      'guestGuess': [],
    });
    setState(() {
      _roomId = roomKey;
      _isWaiting = true;
    });

    // 监听 guest 字段，一旦有人加入就跳转到 game screen
    _roomSubscription = newRoomRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        final guest = data['guest'] as String? ?? '';
        if (guest.isNotEmpty) {
          Navigator.of(context).pushReplacementNamed(
            '/two_player_game',
            arguments: roomKey,
          );
        }
      }
    });
  }

  Future<void> _joinRoom(String roomIdInput) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final roomRef = _dbRef.child('rooms').child(roomIdInput);
    final snapshot = await roomRef.once();
    if (snapshot.snapshot.value != null) {
      // 更新 guest 字段
      await roomRef.update({'guest': user.uid});
      Navigator.of(context).pushReplacementNamed(
        '/two_player_game',
        arguments: roomIdInput,
      );
    } else {
      // 提示房间不存在
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Room not found!',
            style: TextStyle(color: Theme.of(context).colorScheme.onError),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Two Player Lobby'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_roomId == null) ...[
              Text(
                'Enter Room ID to Join:',
                style: TextStyle(
                  fontSize: 18,
                  color: theme.textTheme.bodyMedium!.color,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  hintText: 'Room ID',
                  hintStyle: TextStyle(color: theme.hintColor),
                ),
                style: TextStyle(color: theme.textTheme.bodyMedium!.color),
                onChanged: (val) {
                  setState(() {
                    _roomId = val.trim();
                  });
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed:
                  (_roomId == null || _roomId!.isEmpty) ? null : () => _joinRoom(_roomId!),
                  child: const Text(
                    'Join Room',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Divider(color: theme.dividerColor),
              const SizedBox(height: 24),
              Text(
                'Or create a new room:',
                style: TextStyle(
                  fontSize: 18,
                  color: theme.textTheme.bodyMedium!.color,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary,
                    foregroundColor: theme.colorScheme.onSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _createRoom,
                  child: const Text(
                    'Create Room',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ] else if (_isWaiting) ...[
              Text(
                'Waiting for opponent...',
                style: TextStyle(
                  fontSize: 18,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Room ID: $_roomId',
                style: TextStyle(
                  fontSize: 16,
                  color: theme.textTheme.bodySmall!.color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
