// lib/ui/screen/two_player_game_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:mastermind_game/models/game_mode.dart';
import 'package:mastermind_game/ui/screen/components/two_player_key_input.dart';

enum Player { player1, player2 }

class TwoPlayerGameScreen extends StatefulWidget {
  final GameMode mode;
  final String gameId;

  const TwoPlayerGameScreen({
    super.key,
    required this.mode,
    required this.gameId,
  });

  @override
  State<TwoPlayerGameScreen> createState() => _TwoPlayerGameScreenState();
}

class _TwoPlayerGameScreenState extends State<TwoPlayerGameScreen> {
  late String _playerId;
  late Player _myRole;

  List<List<int>> _myKeys = [[], [], [], []];   // 每一轮填的 4 个数字（索引）
  List<Map<String, int>> _myFeedback = [];       // 每轮的黑白点反馈

  bool _isGameOver = false;
  bool _turnDone = false;
  bool _opponentDone = false;

  Timer? _timer;
  int _remainingTime = 300;

  late CollectionReference _gamesRef;
  late DocumentReference _gameDocRef;

  @override
  void initState() {
    super.initState();
    _playerId = FirebaseAuth.instance.currentUser!.uid;
    _gamesRef = FirebaseFirestore.instance.collection('games');
    _gameDocRef = _gamesRef.doc(widget.gameId);

    // 监听游戏文档的实时更新来获取对手的出招、比分、以及胜负
    _gameDocRef.snapshots().listen((snapshot) {
      if (!snapshot.exists) return;
      final data = snapshot.data() as Map<String, dynamic>;
      final hostId = data['host'] as String;
      _myRole = (hostId == _playerId) ? Player.player1 : Player.player2;

      // 1) 如果对手已经提交了这一轮，将对手的出招内容读出来，做对比
      final oppField = (_myRole == Player.player1) ? 'player2_keys' : 'player1_keys';
      final oppKeys = data[oppField] as List<dynamic>?;

      if (oppKeys != null && _myKeys.length > _myFeedback.length) {
        final oppList = List<int>.from(oppKeys);
        final secretList = (data['secret'] as List<dynamic>).cast<int>();
        final feedback = _calculateFeedback(secretList, oppList);
        setState(() {
          _myFeedback.add(feedback);
          _opponentDone = true;
        });

        // 2) 如果对手猜对或时间到或回合数到，就结束
        final black = feedback['blackPins']!;
        if (black == 4 || _myKeys.length >= 10) {
          _isGameOver = true;
          _showEndDialog(black == 4);
        }
      }
    });

    _startTimer();
  }

  void _startTimer() {
    _remainingTime = 300;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        t.cancel();
        setState(() {
          _isGameOver = true;
        });
        _showEndDialog(false);
      }
    });
  }

  Map<String, int> _calculateFeedback(List<int> secret, List<int> guess) {
    int black = 0, white = 0;
    final secretCopy = List<int>.from(secret);
    final guessCopy = List<int>.from(guess);

    for (int i = 0; i < 4; i++) {
      if (guessCopy[i] == secretCopy[i]) {
        black++;
        secretCopy[i] = -1;
        guessCopy[i] = -1;
      }
    }
    for (int i = 0; i < 4; i++) {
      if (guessCopy[i] != -1 && secretCopy.contains(guessCopy[i])) {
        white++;
        secretCopy[secretCopy.indexOf(guessCopy[i])] = -1;
      }
    }
    return {'blackPins': black, 'whitePins': white};
  }

  Future<void> _submitMyTurn() async {
    if (_turnDone || _isGameOver) return;
    final field = (_myRole == Player.player1) ? 'player1_keys' : 'player2_keys';
    await _gameDocRef.update({field: _myKeys.last});
    setState(() {
      _turnDone = true;
      _opponentDone = false;
    });
  }

  void _onKeyTap(int index) {
    if (_isGameOver || _turnDone) return;
    final currentRound = _myKeys.length - 1;
    setState(() {
      if (_myKeys[currentRound].contains(index)) return;
      _myKeys[currentRound].add(index);
      if (_myKeys[currentRound].length > 4) {
        _myKeys[currentRound] = _myKeys[currentRound].sublist(0, 4);
      }
    });
  }

  Widget _buildKeyRow(int round) {
    final theme = Theme.of(context);
    return Row(
      children: List.generate(4, (i) {
        final hasVal = (_myKeys[round].length > i);
        final idx = hasVal ? _myKeys[round][i] : 0;
        final color = _paletteColor(idx);
        return Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color, // 游戏内数字对应的调色板色
            border: Border.all(color: theme.dividerColor),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_myRole == Player.player1 ? 'You are Host' : 'You are Guest'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 倒计时
            Text(
              'Time: $_remainingTime s',
              style: TextStyle(
                fontSize: 28,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),

            // 当前可填四个 Key 的一行
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                return TwoPlayerKeyInput(
                  value: (_myKeys.last.length > i) ? '${_myKeys.last[i]}' : '',
                  isHost: _myRole == Player.player1,
                  onTap: () {
                    _onKeyTap(i + 1); // 这里 i+1 代表键的值
                  },
                );
              }),
            ),
            const SizedBox(height: 16),

            // 提交按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                onPressed: (_myKeys.last.length == 4 && !_turnDone) ? _submitMyTurn : null,
                child: const Text('Submit Turn'),
              ),
            ),

            const SizedBox(height: 24),

            // 历史列表
            Expanded(
              child: ListView.builder(
                itemCount: _myKeys.length,
                itemBuilder: (context, round) {
                  return Card(
                    color: theme.cardColor,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: Text(
                        '${_myFeedback.length > round ? _myFeedback[round]['blackPins'] : ''}'
                            '/'
                            '${_myFeedback.length > round ? _myFeedback[round]['whitePins'] : ''}',
                        style: TextStyle(color: theme.textTheme.bodyMedium!.color),
                      ),
                      title: _buildKeyRow(round),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _paletteColor(int idx) {
    // 仅用于游戏内显示数字对应的硬编码颜色
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
    if (idx - 1 >= 0 && idx - 1 < palette.length) {
      return palette[idx - 1];
    }
    return Colors.grey;
  }

  void _showEndDialog(bool victory) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.scaffoldBackgroundColor,
          title: Text(
            victory ? 'You Win!' : 'Game Over',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            victory
                ? 'Congratulations, you cracked it!'
                : 'Time’s up or max rounds reached.',
            style: TextStyle(color: theme.textTheme.bodyMedium!.color),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.pushReplacementNamed(context, '/home');
              },
              child: Text(
                'Home',
                style: TextStyle(color: theme.primaryColor),
              ),
            ),
          ],
        );
      },
    );
  }
}
