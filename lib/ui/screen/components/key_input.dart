import 'package:flutter/material.dart';
import 'package:mastermind_game/models/game.dart';

typedef OnPressFunc = void Function(BuildContext context, KeyInputType value);

class KeyInput extends StatelessWidget {
  final OnPressFunc onPressed;
  final List<KeyInputType> children;

  const KeyInput({super.key, required this.onPressed, required this.children});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      reverse: true,
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: children.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        mainAxisSpacing: 10.0,
      ),

      itemBuilder: (BuildContext context, int index) {
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.all(0),
          ),
          onPressed: () {
            onPressed(context, children[index]);
          },
          child: ElementButton(keyInputType: children[index]),
          // child: Text(
          //   children[index].value,
          //   style: TextStyle(color: Colors.white),
          // ),
        );
      },
    );
  }
}

class ElementButton extends StatelessWidget {
  final KeyInputType keyInputType;

  const ElementButton({super.key, required this.keyInputType});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 2,
            offset: const Offset(0, 3),
          ),
        ],
        color: colors[int.parse(keyInputType.value) - 1],
      ),
    );
  }
}
