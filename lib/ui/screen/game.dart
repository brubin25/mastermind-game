import 'package:flutter/material.dart';
import 'package:mastermind_game/models/game.dart';
import 'package:mastermind_game/ui/screen/components/key_input.dart';
import 'dart:math';

typedef OnDeleteFunc = void Function(BuildContext context, int index);

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<KeyInputType> buttons = [];
  GameState gameState = GameState.playing;
  List<KeyInputType?> input = [];

  List<AnswerType> answers = [
    AnswerType(
      input: [
        KeyInputType(value: '2'),
        KeyInputType(value: '2'),
        KeyInputType(value: '3'),
        KeyInputType(value: '4'),
      ],
      onPlace: 2,
      misplaced: 2,
    ),

    AnswerType(
      input: [
        KeyInputType(value: '5'),
        KeyInputType(value: '4'),
        KeyInputType(value: '3'),
        KeyInputType(value: '2'),
      ],
      onPlace: 3,
      misplaced: 0,
    ),
  ];

  late int secretCodeLength;
  late String secretCode;

  @override
  void initState() {
    super.initState();

    buttons = createKeyInputTypeList(6);
    secretCodeLength = 4;
    handleReset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent.withOpacity(0.5),
        elevation: 0,
        leading: IconButton(onPressed: null, icon: Icon(Icons.arrow_back)),
      ),
      body: Flex(
        direction: Axis.horizontal,
        children: [_buildMainLayout(context), _buildKeyInput(context)],
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
            flex: gameState == GameState.playing ? 1 : 2,
            child: Container(
              padding: EdgeInsets.only(
                top: 10.0,
                bottom: 10.0,
                left: 5.0,
                right: 5.0,
              ),
              child:
                  (gameState == GameState.playing
                      ? InputComponent(input: input, onDelete: handleOnDelete)
                      : WinComponent(answers: answers, onReset: handleReset)),
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

  handleOnPressed(BuildContext context, KeyInputType value) {
    if (gameState != GameState.playing) {
      return;
    }
    // get the first null index from input
    var index = input.indexWhere((e) => e == null);

    // store the value to  input where value is missing
    setState(() {
      input[index] = value;
    });

    // check if all inputs are filled
    var count = input.where((e) => e != null).length;
    if (count < secretCodeLength) {
      return;
    }

    // create string from input
    var answer = input.map((e) => e!.value).join('');

    var onPlace = 0;
    var misplaced = 0;

    for (var i = 0; i < secretCodeLength; i++) {
      final char = answer[i];
      var isOnPlace = char == secretCode[i];

      if (isOnPlace) {
        onPlace++;
      } else if (secretCode.contains(char)) {
        misplaced++;
      }
    }

    if (onPlace == secretCodeLength) {
      gameState = GameState.win;
    }

    // add the answer to the answers list, new answer will be added to the top
    answers = [
      AnswerType(
        input: input.map((e) => e!).toList(),
        onPlace: onPlace,
        misplaced: misplaced,
      ),
      ...answers,
    ];

    // reset the input
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

  handleReset() {
    setState(() {
      answers = [];
      gameState = GameState.playing;
      input = List.filled(secretCodeLength, null);
      secretCode = generateRandomString(secretCodeLength, false);
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
                                  color = Colors.black;
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
            'You Win!',
            // style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        Center(
          child: Text(
            'You took $length $plural to win.',
            // style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
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
          onPressed: () {
            onDelete(context, index);
          },
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
