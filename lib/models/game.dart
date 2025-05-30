import 'package:flutter/material.dart';

enum GameState { playing, win }

List<Color> colors = [
  Colors.red,
  Colors.blue,
  Colors.yellow,
  Colors.pink,
  Colors.brown,
  Colors.teal,
  Colors.purple,
];

class KeyInputType {
  String value;

  KeyInputType({required this.value});
}

class AnswerType {
  List<KeyInputType> input;
  int onPlace;
  int misplaced;

  AnswerType({
    required this.input,
    required this.onPlace,
    required this.misplaced,
  });
}

List<KeyInputType> createKeyInputTypeList(int size) {
  return List<String>.generate(
    size,
    (i) => (i + 1).toString(),
  ).map((e) => KeyInputType(value: e)).toList();
}
