import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:mastermind_game/models/game_mode.dart';
import 'package:mastermind_game/ui/screen/game.dart';
import 'package:mastermind_game/ui/screen/components/two_player_key_input.dart';

enum Player { player1, player2 }

class TwoPlayerGameScreen extends StatefulWidget {
  final GameMode mode;
  final String gameId;

  const TwoPlayerGameScreen({
    super.key,
    required this.mode,
    required this.gameId,
  }) : assert(mode == GameMode.twoPlayer);

  @override
  State<TwoPlayerGameScreen> createState() => _TwoPlayerGameScreenState();
}

class _TwoPlayerGameScreenState extends State<TwoPlayerGameScreen> {
  Player? currentPlayer;
  Player? winner;
  bool gameOver = false;

  late List<KeyInputType?> inputP1;
  late List<KeyInputType?> inputP2;

  List<AnswerType> answersP1 = [];
  List<AnswerType> answersP2 = [];

  late int secretCodeLength;
  late String secretCode;
  late List<KeyInputType> buttons;

  Timer? _roundTimer;
  int _timeRemainingSec = _initialTimeSec;
  bool _timerStarted = false;

  static const int _initialTimeSec = 300;
  static const int maxTurnsPerPlayer = 5;

  final _gamesRef = FirebaseFirestore.instance.collection('games');
  late final DocumentReference _gameDocRef;
  StreamSubscription<DocumentSnapshot>? _gameSub;

  late final String myUid;
  String? player1Uid;
  String? player2Uid;

  @override
  void initState() {
    super.initState();
    assert(widget.mode == GameMode.twoPlayer);

    buttons = createKeyInputTypeList(9);
    secretCodeLength = 4;
    inputP1 = List<KeyInputType?>.filled(secretCodeLength, null);
    inputP2 = List<KeyInputType?>.filled(secretCodeLength, null);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User must be signed in to play.');
    myUid = user.uid;

    _gameDocRef = _gamesRef.doc(widget.gameId);
    _gameSub = _gameDocRef.snapshots().listen(
      _onGameDocUpdate,
      onError: (_) {},
    );
  }

  void _onGameDocUpdate(DocumentSnapshot snapshot) {
    if (!snapshot.exists) return;
    final data = snapshot.data() as Map<String, dynamic>;

    final fetchedSecret = data['secretCode'] as String;
    final fetchedLength = data['codeLength'] as int;
    final fetchedP1 = data['player1'] as String?;
    final fetchedP2 = data['player2'] as String?;
    final fetchedCurrent = data['currentPlayer'] as String;
    final rawP1 = (data['stepsP1'] as List<dynamic>?) ?? [];
    final rawP2 = (data['stepsP2'] as List<dynamic>?) ?? [];
    final w = data['winner'] as String?;
    final rem = data['remainingTime'] as int?;

    // final previouslyHadP2 = player2Uid != null;

    setState(() {
      secretCode = fetchedSecret;
      if (secretCodeLength != fetchedLength) {
        secretCodeLength = fetchedLength;
        inputP1 = List<KeyInputType?>.filled(secretCodeLength, null);
        inputP2 = List<KeyInputType?>.filled(secretCodeLength, null);
      }

      player1Uid = fetchedP1;
      player2Uid = fetchedP2;
      currentPlayer = fetchedCurrent == 'P1' ? Player.player1 : Player.player2;

      answersP1 = _parseAnswers(rawP1);
      answersP2 = _parseAnswers(rawP2);

      if (w == 'P1') {
        winner = Player.player1;
        _roundTimer?.cancel();
        print("w == 'P1'");
      } else if (w == 'P2') {
        winner = Player.player2;
        _roundTimer?.cancel();
        print("w == 'P2'");
      } else {
        winner = null;
      }

      if (rem != null) {
        _timeRemainingSec = rem;
      }
    });

    if (!_timerStarted && fetchedP2 != null) {
      _timerStarted = true;
      _startTimer();
    }
  }

  List<AnswerType> _parseAnswers(List<dynamic> raw) {
    return raw.map((e) {
      final m = e as Map<String, dynamic>;
      final digits =
          (m['input'] as String)
              .split('')
              .map((d) => KeyInputType(value: d))
              .toList();
      return AnswerType(
        input: digits,
        onPlace: m['onPlace'] as int,
        misplaced: m['misplaced'] as int,
      );
    }).toList();
  }

  @override
  void dispose() {
    _roundTimer?.cancel();
    _gameSub?.cancel();
    super.dispose();
  }

  Future<void> handleOnPressed(BuildContext ctx, KeyInputType value) async {
    if (winner != null || currentPlayer == null || gameOver) return;

    final isP1Turn = currentPlayer == Player.player1 && player1Uid == myUid;
    final isP2Turn = currentPlayer == Player.player2 && player2Uid == myUid;
    if (!isP1Turn && !isP2Turn) return;

    // Check players if used all 5 turns
    final p1Turns = answersP1.length;
    final p2Turns = answersP2.length;
    if (isP1Turn && p1Turns >= maxTurnsPerPlayer) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          backgroundColor: Colors.black87,
          content: Text(
            'You’ve used all 5 turns already.',
            style: TextStyle(
              color: Colors.redAccent[700],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          duration: Duration(milliseconds: 800),
        ),
      );
      return;
    }
    if (isP2Turn && p2Turns >= maxTurnsPerPlayer) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          backgroundColor: Colors.black87,
          content: Text(
            'You’ve used all 5 turns already.',
            style: TextStyle(
              color: Colors.redAccent[700],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          duration: Duration(milliseconds: 800),
        ),
      );
      return;
    }

    final activeInput = isP1Turn ? inputP1 : inputP2;

    // prevent input duplication
    final alreadyPicked = activeInput
        .where((e) => e != null)
        .any((e) => e!.value == value.value);
    if (alreadyPicked) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.black87,
          content: Text(
            'Each colour should be unique.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          duration: Duration(milliseconds: 800),
        ),
      );
      return;
    }

    final idx = activeInput.indexWhere((e) => e == null);
    if (idx == -1) return;

    setState(() => activeInput[idx] = value);
    if (activeInput.where((e) => e != null).length < secretCodeLength) return;

    final guess = activeInput.map((e) => e!.value).join();
    var onPlace = 0, misplaced = 0;
    for (var i = 0; i < secretCodeLength; i++) {
      if (guess[i] == secretCode[i]) {
        onPlace++;
      } else if (secretCode.contains(guess[i])) {
        misplaced++;
      }
    }

    final newAnswer = {
      'input': guess,
      'onPlace': onPlace,
      'misplaced': misplaced,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };

    final isP1 = currentPlayer == Player.player1;
    final isP2 = currentPlayer == Player.player2;
    final nextPlayer = isP1 ? 'P2' : 'P1';
    final isWin = onPlace == secretCodeLength;

    final updates = <String, Object>{
      if (isP1) 'stepsP1': FieldValue.arrayUnion([newAnswer]),
      if (!isP1) 'stepsP2': FieldValue.arrayUnion([newAnswer]),
      'currentPlayer': nextPlayer,
      if (isWin) 'winner': isP1 ? 'P1' : 'P2',
      if (isWin) 'remainingTime': _timeRemainingSec,
    };

    await _gameDocRef.update(updates);

    if (!isWin) {
      setState(() {
        if (isP1) {
          inputP1 = List<KeyInputType?>.filled(secretCodeLength, null);
        } else {
          inputP2 = List<KeyInputType?>.filled(secretCodeLength, null);
        }
      });

      final newP1Turns = isP1 ? (p1Turns + 1) : p1Turns;
      final newP2Turns = isP2 ? (p2Turns + 1) : p2Turns;

      // If both players have used 5 turns, end the game
      if (newP1Turns >= maxTurnsPerPlayer && newP2Turns >= maxTurnsPerPlayer) {
        setState(() => gameOver = true);
      }
    } else {
      _roundTimer?.cancel();
      setState;
    }
  }

  void handleOnDelete(BuildContext ctx, int index) {
    if (winner != null || currentPlayer == null || gameOver) return;
    final isP1Turn = currentPlayer == Player.player1 && player1Uid == myUid;
    final isP2Turn = currentPlayer == Player.player2 && player2Uid == myUid;
    if (!isP1Turn && !isP2Turn) return;

    setState(() {
      if (currentPlayer == Player.player1) {
        inputP1[index] = null;
      } else {
        inputP2[index] = null;
      }
    });
  }

  void _startTimer() {
    _roundTimer?.cancel();
    _timeRemainingSec = _initialTimeSec;
    _roundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemainingSec > 0) {
        setState(() => _timeRemainingSec--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (player2Uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Waiting Room')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Waiting for another Player to join…',
                style: TextStyle(fontSize: 20),
              ),
            ],
          ),
        ),
      );
    }

    final isMePlayer1 = myUid == player1Uid;
    final myLabel = isMePlayer1 ? 'You are Player 1' : 'You are Player 2';

    final isMyTurn =
        winner == null &&
        !gameOver &&
        ((currentPlayer == Player.player1 && player1Uid == myUid) ||
            (currentPlayer == Player.player2 && player2Uid == myUid));

    final bothFinished =
        answersP1.length >= maxTurnsPerPlayer &&
        answersP2.length >= maxTurnsPerPlayer;

    return Scaffold(
      appBar: AppBar(title: Text(myLabel)),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background3.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    Text(
                      'Time Remaining: $_timeRemainingSec s',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      winner != null
                          ? ('Player ${winner == Player.player1 ? "1" : "2"} Wins!')
                          : (bothFinished
                              ? 'Game Over! No one guessed!'
                              : 'Turn: Player ${currentPlayer == Player.player1 ? "1" : "2"}'),
                      style: const TextStyle(
                        color: Colors.pinkAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                flex: 5,
                child: _buildHistoryColumn('Player 1', answersP1),
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 5,
                child: _buildHistoryColumn('Player 2', answersP2),
              ),

              if (winner != null || bothFinished) ...[
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (winner != null)
                            Text(
                              myUid == player1Uid
                                  ? (winner == Player.player1
                                      ? "Congratulations!"
                                      : "Oops, maybe next time…")
                                  : (winner == Player.player1
                                      ? "Oops, maybe next time…"
                                      : "Congratulations!"),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.lightBlue,
                              ),
                              textAlign: TextAlign.center,
                            )
                          else
                            Text(
                              'Reached $maxTurnsPerPlayer turns each\nSecret: $secretCode',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed:
                                () => Navigator.of(
                                  context,
                                ).popUntil((r) => r.isFirst),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightBlue,
                            ),
                            child: const Text(
                              'Exit to Menu',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Not game-over: show InputComponent (flex 2) then KeyInput (flex 2):
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: InputComponent(
                      input:
                          (currentPlayer == Player.player1) ? inputP1 : inputP2,
                      onDelete: handleOnDelete,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    child: AbsorbPointer(
                      absorbing: !isMyTurn,
                      child: KeyInput(
                        onPressed: handleOnPressed,
                        children: buttons,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryColumn(String title, List<AnswerType> answers) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Divider(color: Colors.grey, height: 1),
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: answers.length,
              itemBuilder: (ctx, i) {
                final ans = answers[i];
                final pegSize =
                    MediaQuery.of(ctx).size.width / (secretCodeLength * 8);
                return Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children:
                            ans.input.map((e) {
                              return Container(
                                width: pegSize,
                                height: pegSize,
                                margin: EdgeInsets.symmetric(
                                  horizontal: pegSize * 0.2,
                                ),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _colorFromValue(e.value),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.5),
                                      spreadRadius: 1,
                                      blurRadius: 1,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                      Row(
                        children: [
                          for (var k = 0; k < ans.onPlace; k++)
                            Container(
                              width: pegSize * 0.5,
                              height: pegSize * 0.5,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.redAccent[700],
                              ),
                            ),
                          for (var k = 0; k < ans.misplaced; k++)
                            Container(
                              width: pegSize * 0.5,
                              height: pegSize * 0.5,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFromValue(String val) {
    final idx = int.tryParse(val);
    if (idx == null || idx < 1 || idx > 9) return Colors.grey;
    const palette = [
      Colors.white,
      Colors.redAccent,
      Colors.deepOrange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.brown,
      Colors.black,
    ];
    return palette[idx - 1];
  }
}
