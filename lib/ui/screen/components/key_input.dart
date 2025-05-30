import 'package:flutter/material.dart';
import 'package:mastermind_game/models/game.dart';

typedef OnPressFunc = void Function(BuildContext context, KeyInputType value);

class KeyInput extends StatelessWidget {
  final OnPressFunc onPressed;
  final List<KeyInputType> children;

  KeyInput({Key? key, required this.onPressed, required this.children});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      reverse: true,
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: children.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
      ),

      itemBuilder: (BuildContext context, int index) {
        return ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent),
          onPressed: () {
            onPressed(context, children[index]);
          },
          child: Text(
            children[index].value,
            style: TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }
}
