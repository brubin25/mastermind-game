import 'package:flutter/material.dart';

enum GameState { playing, win, lose }

List<Color> colors = [
  Colors.white,
  Colors.redAccent[400]!,
  Colors.deepOrange,
  Colors.yellow,
  Colors.green,
  Colors.blue,
  Colors.purple,
  Colors.brown,
  Colors.black,
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
