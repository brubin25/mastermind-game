import 'package:flutter/material.dart';

class GameMechanicsScreen extends StatelessWidget {
  const GameMechanicsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Mechanics')),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/levels/level2.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mastermind is a code-breaking game where the player tries to guess a sequence of colors (or numbers) set by the computer.',
                style: TextStyle(fontSize: 16, height: 1.5, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'After each guess, the system provides feedback using pegs:',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Icon(Icons.circle, color: Colors.red, size: 14),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Red = correct color in the correct position',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: const [
                  Icon(Icons.circle, color: Colors.white, size: 14),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'White = correct color in the wrong position',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Use logic and deduction to crack the code in as few attempts as possible!',
                style: TextStyle(fontSize: 16, height: 1.5, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
