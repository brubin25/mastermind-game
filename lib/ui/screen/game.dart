// lib/ui/screen/game.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../models/game_mode.dart';
import 'game_mechanics_screen.dart';

class GameScreen extends StatefulWidget {
  final GameMode mode;
  const GameScreen({Key? key, required this.mode}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // ───────── 游戏常量 ─────────
  static const int maxRounds = 10;
  static const int startTimeInSeconds = 300; // 倒计时 5 分钟

  // ───────── 局部状态变量 ─────────
  late List<String> _secretCode;           // 存储随机生成的 4 个颜色名称
  List<List<String>> _guessHistory = [];    // 历史每一轮猜测的 List<颜色名称>
  List<Map<String, int>> _feedbackHistory = []; // 历史反馈：每轮 { 'blackPins': x, 'whitePins': y }
  List<String> _currentGuess = ['', '', '', '']; // 当前正在填写的 4 格
  int _currentRound = 0;                    // 当前第几轮
  int _remainingTime = startTimeInSeconds;  // 剩余秒数
  Timer? _timer;                            // 定时器

  bool _isGameOver = false; // 标记游戏是否结束
  bool _isVictory = false;  // 标记是否胜利

  // ───────── Firebase Realtime Database 根引用 ─────────
  // 注意：firebase_database >= v9.x 用 .ref() 而不是 .reference()
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _startNewGame(); // 页面打开时立刻开始新一局
  }

  /// 从头开始初始化一盘游戏
  void _startNewGame() {
    // 生成随机密钥
    _secretCode = _generateRandomCode();
    // 清空历史
    _guessHistory.clear();
    _feedbackHistory.clear();
    _currentGuess = ['', '', '', ''];
    _currentRound = 0;
    _remainingTime = startTimeInSeconds;
    _isGameOver = false;
    _isVictory = false;

    // 启动倒计时
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        timer.cancel();
        _onTimeUp(); // 时间到，触发时间结束逻辑
      }
    });
  }

  /// 生成 4 个不重复的随机颜色名称，来自 game_mode.dart 中的 colors 列表
  List<String> _generateRandomCode() {
    final allColors = [
      'red',
      'blue',
      'green',
      'yellow',
      'purple',
      'orange'
    ];
    allColors.shuffle(); // 随机排序
    return allColors.take(4).toList();
  }

  /// 倒计时结束后触发
  void _onTimeUp() {
    setState(() {
      _isGameOver = true;
      _isVictory = false;
    });
    _recordResult(false);      // 记录到数据库为失败
    _showEndDialog(false);     // 弹出 Game Over 对话框
  }

  /// 处理用户点击“Submit”按钮时的逻辑
  void _submitGuess() {
    // 如果当前还有空格尚未填写，就直接返回
    if (_currentGuess.any((c) => c == '')) return;

    // 计算反馈信息：黑点 / 白点
    final feedback = _calculateFeedback(_currentGuess, _secretCode);
    _guessHistory.add(List.from(_currentGuess));      // 把本轮猜测记录到历史
    _feedbackHistory.add(feedback);
    _currentRound++;

    // 如果反馈里 blackPins = 4，则胜利
    if (feedback['blackPins'] == 4) {
      _isVictory = true;
      _isGameOver = true;
      _timer?.cancel();
      _recordResult(true);     // 记录为胜利
      _showEndDialog(true);    // 弹出胜利对话框
    } else if (_currentRound >= maxRounds) {
      // 用完最大回合数
      _isVictory = false;
      _isGameOver = true;
      _timer?.cancel();
      _recordResult(false);
      _showEndDialog(false);
    } else {
      // 进入下一轮，先清空 _currentGuess
      setState(() {
        _currentGuess = ['', '', '', ''];
      });
    }
  }

  /// 计算黑点/白点：
  /// - 黑点（blackPins）：位置和颜色都对
  /// - 白点（whitePins）：颜色对、位置不对
  Map<String, int> _calculateFeedback(
      List<String> guess, List<String> secret) {
    int blackPins = 0, whitePins = 0;
    final secretCopy = List<String>.from(secret);
    final guessCopy = List<String>.from(guess);

    // 先算黑点
    for (int i = 0; i < 4; i++) {
      if (guessCopy[i] == secretCopy[i]) {
        blackPins++;
        secretCopy[i] = '';
        guessCopy[i] = '';
      }
    }
    // 再算白点
    for (int i = 0; i < 4; i++) {
      if (guessCopy[i] != '' && secretCopy.contains(guessCopy[i])) {
        whitePins++;
        secretCopy[secretCopy.indexOf(guessCopy[i])] = '';
      }
    }
    return {'blackPins': blackPins, 'whitePins': whitePins};
  }

  /// 把本局结果存到 Firebase Realtime Database 下
  Future<void> _recordResult(bool isVictory) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final timeLeft = _remainingTime;
    final usedTime = startTimeInSeconds - timeLeft;
    final recordRef = _dbRef.child('records').child(user.uid).push();
    await recordRef.set({
      'gameMode': 'Single',
      'timeTaken': usedTime,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    // 同时更新排行榜节点：如果当前成绩优于之前最好成绩，更新之
    final lbRef = _dbRef.child('leaderboard').child(user.uid);
    final snapshot = await lbRef.get();
    if (snapshot.exists) {
      final existingTime = (snapshot.value as Map)['bestTime'] as int? ?? 999999;
      if (usedTime < existingTime) {
        await lbRef.update({'bestTime': usedTime});
      }
    } else {
      await lbRef.set({
        'username': user.email ?? 'Unknown',
        'bestTime': usedTime,
      });
    }
  }

  /// 显示游戏结束对话框
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
                ? 'Congratulations, you guessed the code!'
                : 'Better luck next time!\nThe code was: ${_secretCode.join(', ')}',
            style: TextStyle(color: theme.textTheme.bodyMedium!.color),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();  // 关闭对话框
                _startNewGame();             // 重新开始一局
                setState(() {});             // 刷新界面
              },
              child: Text(
                'Play Again',
                style: TextStyle(color: theme.primaryColor),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// 把“颜色名称”字符串映射到真实的 Color
  Color _mapColorNameToColor(String name) {
    switch (name) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'purple':
        return Colors.purple;
      case 'orange':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// 颜色选择小部件：“彩球”按钮，传入颜色名称和点击回调
  Widget _colorBall(String colorName, VoidCallback onTap) {
    final ballColor = _mapColorNameToColor(colorName);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ballColor, // 玩法颜色硬编码（不随主题）
        ),
      ),
    );
  }

  /// 当用户点击“某一位置”想替换颜色时，会弹出底部弹窗，让用户选 6 种彩球
  void _showColorPicker(int index) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
            color: theme.bottomSheetTheme.backgroundColor ?? // 背景随主题
                theme.canvasColor, // 如果 bottomSheetTheme.backgroundColor 为空，就用 canvasColor 兜底
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              crossAxisCount: 3,
              children: ['red', 'blue', 'green', 'yellow', 'purple', 'orange']
                  .map((colorName) => GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          setState(() {
                            _currentGuess[index] = colorName;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _mapColorNameToColor(colorName),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          width: 48,
                          height: 48,
                        ),
                      ))
                          .toList(),
                    ),
                  );
          // color: theme.bottomAppBarColor, // 背景随主题
          // padding: const EdgeInsets.all(16.0),
          // child: GridView.count(
          //   crossAxisCount: 3,
          //   children: ['red', 'blue', 'green', 'yellow', 'purple', 'orange']
          //       .map((colorName) => GestureDetector(
          //     onTap: () {
          //       Navigator.of(context).pop();
          //       setState(() {
          //         _currentGuess[index] = colorName;
          //       });
          //     },
          //     child: Container(
          //       margin: const EdgeInsets.all(8.0),
          //       decoration: BoxDecoration(
          //         shape: BoxShape.circle,
          //         color: _mapColorNameToColor(colorName),
          //         border: Border.all(color: theme.dividerColor),
          //       ),
          //       width: 48,
          //       height: 48,
          //     ),
          //   ))
          //       .toList(),
          // ),
        // );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Single Player Game'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // —— 倒计时显示
            Text(
              'Time Left: $_remainingTime s',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.error, // 倒计时红色提示
              ),
            ),
            const SizedBox(height: 16),

            // —— 当前猜测行：4 个圆球槽，可以点开底部弹窗选择颜色
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) {
                final colorName = _currentGuess[index];
                return GestureDetector(
                  onTap: _isGameOver
                      ? null
                      : () {
                    _showColorPicker(index);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.dividerColor),
                      color: colorName.isEmpty
                          ? Colors.transparent
                          : _mapColorNameToColor(colorName),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),

            // —— Submit 按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,         // 代替过时的 primary
                  foregroundColor: theme.colorScheme.onPrimary, // 代替过时的 onPrimary
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed:
                _isGameOver || _currentGuess.contains('') ? null : _submitGuess,
                child: const Text('Submit'),
              ),
            ),

            const SizedBox(height: 24),

            // —— 历史记录列表（每一行显示猜测结果和反馈）
            Expanded(
              child: ListView.builder(
                itemCount: _guessHistory.length,
                itemBuilder: (context, idx) {
                  final guess = _guessHistory[idx];
                  final feedback = _feedbackHistory[idx];
                  return Card(
                    color: theme.cardColor,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: Text(
                        '${feedback['blackPins']}/${feedback['whitePins']}',
                        style: TextStyle(
                          fontSize: 18,
                          color: theme.textTheme.bodyMedium!.color,
                        ),
                      ),
                      title: Row(
                        children: guess
                            .map((colorName) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _mapColorNameToColor(colorName),
                            ),
                          ),
                        ))
                            .toList(),
                      ),
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
}
