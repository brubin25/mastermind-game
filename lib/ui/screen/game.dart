import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mastermind_game/models/game.dart';
import 'package:mastermind_game/ui/screen/components/key_input.dart';
import 'dart:math';

const int maxRounds = 10;
typedef OnDeleteFunc = void Function(BuildContext context, int index);

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<KeyInputType> buttons = [];
  GameState gameState = GameState.playing;
  List<KeyInputType?> input = [];

  List<AnswerType> answers = [];

  late int secretCodeLength;
  late String secretCode;
  final CollectionReference gamesRef = FirebaseFirestore.instance.collection(
    'games',
  );
  late DocumentReference _currentGameRef;

  // seconds per round
  static const int _initialTimeSec = 300;
  // time remaining
  int _timeRemainingSec = _initialTimeSec;
  Timer? _roundTimer;

  // show elapsed time instead of countdown
  // final Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();

    buttons = createKeyInputTypeList(6);
    secretCodeLength = 4;
    _startNewGame();
  }

  @override
  void dispose() {
    _roundTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Flex(
            direction: Axis.horizontal,
            children: [_buildMainLayout(context), _buildKeyInput(context)],
          ),
        ),
      ),
    );
  }

  _buildKeyInput(BuildContext context) {
    return Flexible(
      flex: 2,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            margin: EdgeInsets.all(10.0),
            child: KeyInput(onPressed: handleOnPressed, children: buttons),
          ),
        ],
      ),
    );
  }

  _buildMainLayout(BuildContext context) {
    return Flexible(
      flex: 8,
      child: Column(
        children: [
          // timer ui
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            color: Colors.black54,
            width: double.infinity,
            child: Center(
              child: Text(
                'Time Remaining: $_timeRemainingSec s',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),

          Expanded(
            flex: gameState == GameState.playing ? 9 : 8,
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(40.0),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Answers(answers: answers, maxDigits: secretCodeLength),
            ),
          ),
          Expanded(
            flex: gameState == GameState.playing ? 1 : 3,
            child: Container(
              padding: EdgeInsets.only(
                top: 10.0,
                bottom: 10.0,
                left: 5.0,
                right: 5.0,
              ),
              child: () {
                switch (gameState) {
                  case GameState.playing:
                    return InputComponent(
                      input: input,
                      onDelete: handleOnDelete,
                    );
                  case GameState.win:
                    return WinComponent(
                      answers: answers,
                      onReset: _startNewGame,
                    );
                  case GameState.lose:
                    return LoseComponent(
                      onReset: _startNewGame,
                      secretCode: secretCode,
                    );
                }
              }(),
            ),
          ),
        ],
      ),
    );
  }

  String generateRandomString(int secretCodeLength, bool repeatNumber) {
    var list = buttons.map((e) => e.value).toList();
    // remove duplicates
    if (!repeatNumber) {
      list.shuffle();
      var sc = list.sublist(0, secretCodeLength).join();
      print('Secret code: $sc');
      return sc;
    }

    var random = Random();
    var sb = StringBuffer();

    for (var i = 0; i < secretCodeLength; i++) {
      sb.write(list[random.nextInt(list.length)]);
    }

    print('Secret code: ${sb.toString()}');
    return sb.toString();
  }

  Future<void> handleOnPressed(BuildContext context, KeyInputType value) async {
    if (gameState != GameState.playing) return;

    // fill empty slot
    final index = input.indexWhere((e) => e == null);
    setState(() {
      input[index] = value;
    });

    // check if all slots are filled
    final filledCount = input.where((e) => e != null).length;
    if (filledCount < secretCodeLength) return;

    // evaluate onPlace / misplaced
    final guess = input.map((e) => e!.value).join();
    int onPlace = 0, misplaced = 0;
    for (var i = 0; i < secretCodeLength; i++) {
      if (guess[i] == secretCode[i]) {
        onPlace++;
      } else if (secretCode.contains(guess[i])) {
        misplaced++;
      }
    }

    // update answers, gameState, and reset input
    setState(() {
      // new guess
      answers = [
        AnswerType(
          input: input.map((e) => e!).toList(),
          onPlace: onPlace,
          misplaced: misplaced,
        ),
        ...answers,
      ];
    });

    // win
    if (onPlace == secretCodeLength) {
      _roundTimer?.cancel();

      try {
        await _currentGameRef.update({'remainingTime': _timeRemainingSec});
      } catch (e) {
        print('Error updating remainingTime: $e');
      }

      setState(() {
        gameState = GameState.win;
      });
      return;
    }

    // lose
    if (answers.length >= maxRounds - 1) {
      _roundTimer?.cancel();
      setState(() {
        gameState = GameState.lose;
      });
      return;
    }

    // clear the input for the next guess
    input = List.filled(secretCodeLength, null);
  }

  handleOnDelete(BuildContext context, int index) {
    if (gameState != GameState.playing) {
      return;
    }

    setState(() {
      input[index] = null;
    });
  }

  Future<void> _startNewGame() async {
    // generate a new secretCode
    final newCode = generateRandomString(secretCodeLength, false);

    try {
      // tie this document to the current user
      final currentUser = FirebaseAuth.instance.currentUser;
      final uid = currentUser?.uid;

      _currentGameRef = await gamesRef.add({
        'createdAt': FieldValue.serverTimestamp(),
        if (uid != null) 'uid': uid,
        'secretCode': newCode,
        'codeLength': secretCodeLength,
        // add remainingTime later when the user wins
      });
    } catch (e) {
      print('Error writing secretCode to Firestore: $e');
    }

    _startTimer();

    // update local state so the UI resets
    setState(() {
      answers = [];
      gameState = GameState.playing;
      input = List.filled(secretCodeLength, null);
      secretCode = newCode;
    });
  }

  void _startTimer() {
    // cancel any previous timer
    _roundTimer?.cancel();

    _timeRemainingSec = _initialTimeSec;

    // new timer
    _roundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemainingSec > 0) {
        setState(() {
          _timeRemainingSec--;
        });
      } else {
        // time up
        timer.cancel();
        setState(() {
          gameState = GameState.lose;
        });
      }
    });
  }
}

class Answers extends StatelessWidget {
  final List<AnswerType> answers;
  final int maxDigits;
  const Answers({super.key, required this.answers, required this.maxDigits});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      reverse: true,
      itemCount: answers.length,
      itemBuilder: (context, index) {
        var answer = answers[index];
        var spaceBetween = MediaQuery.of(context).size.height * 0.001;
        var ratio = maxDigits <= 5 ? 60 : 40;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children:
                          answers[index].input
                              .map(
                                (e) => SizedBox(
                                  width: spaceBetween * ratio,
                                  height: spaceBetween * ratio,
                                  child: ElementButton(keyInputType: e),
                                ),
                              )
                              .toList(),
                    ),
                    // child: Text(answer.input.map((e) => e.value).join('')),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ...List.generate(2, (rowIndex) {
                          var maxForRow = maxDigits ~/ 2;
                          if (maxDigits.isOdd && rowIndex == 0) {
                            maxForRow++;
                          }
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ...List.generate(maxForRow, (columnIndex) {
                                var number = rowIndex * maxForRow + columnIndex;

                                Color? color;
                                if (number < answer.onPlace) {
                                  color = Colors.redAccent[700];
                                } else if (number <
                                    answer.onPlace + answer.misplaced) {
                                  color = Colors.white;
                                }

                                return Container(
                                  width: 14,
                                  height: 14,
                                  margin: EdgeInsets.only(top: 5),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        color != null
                                            ? Colors.grey
                                            : Colors.transparent,
                                  ),
                                  child: Container(
                                    margin: EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: color,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          );
                        }),
                        // Text('onPlace: ' + answer.onPlace.toString()),
                        // Text('misplaced: ' + answer.misplaced.toString()),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                height: 1,
                margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
                color: Colors.grey,
              ),
            ],
          ),
        );
      },
    );
  }
}

class WinComponent extends StatelessWidget {
  final List<AnswerType> answers;
  final Function() onReset;

  const WinComponent({super.key, required this.answers, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final length = answers.length;
    final plural = length > 1 ? 'rounds' : 'round';

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Center(
          child: Text(
            'Congratulations! XD',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        Center(
          child: Text(
            'You took $length $plural to win.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 10.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32.0),
            ),
          ),
          onPressed: () {
            onReset();
          },
          child: const Text('Play Again'),
        ),
      ],
    );
  }
}

class LoseComponent extends StatelessWidget {
  final Function() onReset;
  final String secretCode;

  const LoseComponent({
    super.key,
    required this.onReset,
    required this.secretCode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Center(
          child: Text(
            'Game Over T.T',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        Center(
          child: Text(
            ' You\'ve used all $maxRounds rounds\nThe secret code was $secretCode',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 10.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32.0),
            ),
          ),
          onPressed: () {
            onReset();
          },
          child: const Text('Play Again'),
        ),
      ],
    );
  }
}

class InputComponent extends StatelessWidget {
  final List<KeyInputType?> input;
  final OnDeleteFunc onDelete;

  const InputComponent({
    super.key,
    required this.input,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: input.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        mainAxisSpacing: 10.0,
        // crossAxisSpacing: 20.0,
      ),
      itemBuilder: (context, index) {
        return MaterialButton(
          onPressed: () => onDelete(context, index),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minWidth: 0,
          height: 0,
          padding: EdgeInsets.all(3.0),
          shape: const CircleBorder(),
          color: Colors.grey.withOpacity(0.5),
          child:
              input[index] != null
                  ? ElementButton(keyInputType: input[index]!)
                  : null,
        );
      },
    );
  }
}
