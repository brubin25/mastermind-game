import 'package:flutter/material.dart';
import './ui/screen/game.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mastermind Game',
      theme: ThemeData(
        primarySwatch: Colors.grey,
        brightness: Brightness.dark,
      ),
      home: const MainScaffold(),
    );
  }
}

class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mastermind Game'),
      ),
      drawer: Drawer(
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/drawer/drawer-background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            color: Colors.white.withOpacity(0.5), // semi-transparent white overlay
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 200),

                ListTile(
                  leading: const Icon(Icons.login, color: Colors.black),
                  title: const Text('Login', style: TextStyle(color: Colors.black)),
                  onTap: () {
                    Navigator.pop(context);
                    // Add navigation logic here
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline, color: Colors.black),
                  title: const Text('How to Play', style: TextStyle(color: Colors.black)),
                  onTap: () {
                    Navigator.pop(context);
                    // Add navigation logic here
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings, color: Colors.black),
                  title: const Text('Settings', style: TextStyle(color: Colors.black)),
                  onTap: () {
                    Navigator.pop(context);
                    // Add navigation logic here
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: GameScreen(),
    );
  }
}
