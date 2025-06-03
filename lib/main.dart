import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'ui/screen/login_screen.dart';
import 'ui/screen/record_screen.dart';
import 'ui/screen/leaderboard_screen.dart';
import 'ui/screen/home_screen.dart';
import 'ui/screen/game_mechanics_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mastermind Game',
      theme: ThemeData(primarySwatch: Colors.grey, brightness: Brightness.dark),
      home: const AuthenticationWrapper(),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return const MainScaffold();
        }
        return const LoginScreen();
      },
    );
  }
}

class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mastermind Game')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF0D47A1)),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.rule),
              title: const Text('Game Mechanics'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const GameMechanicsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('My History'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const RecordScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events),
              title: const Text('Leaderboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LeaderboardScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.of(context).pop();
                await FirebaseAuth.instance.signOut();
              },
            ),
          ],
        ),
      ),
      body: ModeSelectionScreen(),
    );
  }
}
