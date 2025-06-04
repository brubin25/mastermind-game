// lib/ui/screen/game_mechanics_screen.dart

import 'package:flutter/material.dart';

class GameMechanicsScreen extends StatelessWidget {
  const GameMechanicsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Mechanics'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How to Play',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge!.color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '1. The computer generates a secret code consisting of 4 colored pegs.\n'
                    '2. Each round, you guess the combination by selecting 4 colors.\n'
                    '3. You receive feedback in the form of black-and-white markers:\n'
                    '   • Black peg: Correct color in the correct position.\n'
                    '   • White peg: Correct color in the wrong position.\n'
                    '4. You have a limited number of rounds and time to crack the code.\n'
                    '5. The goal is to find the exact code within the allowed rounds/time.\n',
                style: TextStyle(
                  fontSize: 16,
                  color: theme.textTheme.bodyMedium!.color,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tips:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge!.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '- Start with a diverse guess to narrow down colors.\n'
                    '- Use feedback wisely to eliminate impossible combinations.\n'
                    '- Keep track of your previous guesses and feedback.\n',
                style: TextStyle(
                  fontSize: 16,
                  color: theme.textTheme.bodyMedium!.color,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
