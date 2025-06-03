import 'package:flutter/material.dart';

enum GameMode { single, twoPlayer }

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

  factory AnswerType.fromJson(Map<String, dynamic> json) {
    var inputList = json['input'] as String? ?? '';
    return AnswerType(
      input: inputList.split('').map((e) => KeyInputType(value: e)).toList(),
      onPlace: json['onPlace'] as int,
      misplaced: json['misplaced'] as int,
    );
  }
}

List<KeyInputType> createKeyInputTypeList(int size) {
  return List<String>.generate(
    size,
    (i) => (i + 1).toString(),
  ).map((e) => KeyInputType(value: e)).toList();
}
