import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'two_player_game_screen.dart';
import 'package:mastermind_game/models/game_mode.dart';

class TwoPlayerLobbyScreen extends StatefulWidget {
  const TwoPlayerLobbyScreen({super.key});

  @override
  State<TwoPlayerLobbyScreen> createState() => _TwoPlayerLobbyScreenState();
}

class _TwoPlayerLobbyScreenState extends State<TwoPlayerLobbyScreen> {
  final TextEditingController _joinController = TextEditingController();
  final CollectionReference _gamesRef = FirebaseFirestore.instance.collection(
    'games',
  );

  String? _errorText;
  bool _isLoading = false;

  @override
  void dispose() {
    _joinController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorText = 'You must be signed in to create a room.';
        _isLoading = false;
      });
      return;
    }

    final uid = user.uid;
    final secretCode = _generateRandomString(4, repeatsAllowed: false);
    print('=============== secret code: $secretCode ===============');

    try {
      final docRef = await _gamesRef.add({
        'secretCode': secretCode,
        'codeLength': 4,
        'player1': uid,
        'player2': null,
        'currentPlayer': 'P1',
        'stepsP1': [],
        'stepsP2': [],
        'winner': null,
        'remainingTime': 300,
        'createdAt': FieldValue.serverTimestamp(),
      });
      final roomId = docRef.id;

      setState(() => _isLoading = false);

      await showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Room Created'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Share this Room ID with Player 2:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: SelectableText(
                          roomId,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Copy button
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.blueAccent),
                        tooltip: 'Copy to clipboard',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: roomId));
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Room ID copied to clipboard'),
                              duration: Duration(milliseconds: 800),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder:
              (_) =>
                  TwoPlayerGameScreen(mode: GameMode.twoPlayer, gameId: roomId),
        ),
      );
    } catch (e) {
      setState(() {
        _errorText = 'Error creating room: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _joinRoom() async {
    final roomId = _joinController.text.trim();
    if (roomId.isEmpty) {
      setState(() => _errorText = 'Please enter a room ID.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorText = 'You must be signed in to join a room.';
        _isLoading = false;
      });
      return;
    }

    final uid = user.uid;
    final docRef = _gamesRef.doc(roomId);

    try {
      final snapshot = await docRef.get();
      if (!snapshot.exists) {
        setState(() {
          _errorText = 'Room "$roomId" does not exist.';
          _isLoading = false;
        });
        return;
      }

      final data = snapshot.data() as Map<String, dynamic>;
      if (data['player2'] != null) {
        setState(() {
          _errorText = 'Room "$roomId" is already full.';
          _isLoading = false;
        });
        return;
      }
      if (data['player1'] == uid) {
        setState(() {
          _errorText = 'You are already Player 1 in this room.';
          _isLoading = false;
        });
        return;
      }

      await docRef.update({'player2': uid});
      setState(() => _isLoading = false);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder:
              (_) =>
                  TwoPlayerGameScreen(mode: GameMode.twoPlayer, gameId: roomId),
        ),
      );
    } catch (e) {
      setState(() {
        _errorText = 'Error joining room: $e';
        _isLoading = false;
      });
    }
  }

  String _generateRandomString(int length, {bool repeatsAllowed = true}) {
    final digits = List<String>.generate(9, (i) => (i + 1).toString());
    if (!repeatsAllowed) {
      digits.shuffle();
      return digits.sublist(0, length).join();
    }
    final rnd = Random();
    final sb = StringBuffer();
    for (var i = 0; i < length; i++) {
      sb.write(digits[rnd.nextInt(digits.length)]);
    }
    return sb.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Two-Player Lobby')),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background6.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _isLoading ? null : _createRoom,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(60),
                  backgroundColor: const Color(0xFF0D47A1),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text(
                          'Create Room',
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
              ),

              const SizedBox(height: 100),
              const Text(
                '— OR —',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 32),

              TextField(
                controller: _joinController,
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                decoration: InputDecoration(
                  labelText: 'Enter Room ID',
                  labelStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  errorText: _errorText,
                  border: const OutlineInputBorder(),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  // add a Paste icon to the TextField so users can tap to paste from clipboard
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste, color: Colors.white),
                    tooltip: 'Paste from clipboard',
                    onPressed: () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data?.text != null) {
                        _joinController.text = data!.text!;
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isLoading ? null : _joinRoom,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(60),
                  backgroundColor: const Color(0xFF0D47A1),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text(
                          'Join Room',
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
