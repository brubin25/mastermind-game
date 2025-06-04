// lib/ui/screen/home_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mastermind Game'),
      ),
      drawer: Material(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drawer Header
              DrawerHeader(
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                ),
                child: const Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    'Menu',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Home 按钮
              ListTile(
                leading: Icon(Icons.home, color: theme.iconTheme.color),
                title: Text(
                  'Home',
                  style: TextStyle(color: theme.textTheme.bodyMedium!.color),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacementNamed('/home');
                },
              ),

              // My History 按钮
              ListTile(
                leading: Icon(Icons.history, color: theme.iconTheme.color),
                title: Text(
                  'My History',
                  style: TextStyle(color: theme.textTheme.bodyMedium!.color),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed('/record');
                },
              ),

              // Leaderboard 按钮
              ListTile(
                leading: Icon(Icons.emoji_events, color: theme.iconTheme.color),
                title: Text(
                  'Leaderboard',
                  style: TextStyle(color: theme.textTheme.bodyMedium!.color),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed('/leaderboard');
                },
              ),

              // Settings 按钮
              ListTile(
                leading: Icon(Icons.settings, color: theme.iconTheme.color),
                title: Text(
                  'Settings',
                  style: TextStyle(color: theme.textTheme.bodyMedium!.color),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed('/settings');
                },
              ),

              // Logout 按钮
              ListTile(
                leading: Icon(Icons.logout, color: theme.iconTheme.color),
                title: Text(
                  'Logout',
                  style: TextStyle(color: theme.textTheme.bodyMedium!.color),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  await FirebaseAuth.instance.signOut();
                },
              ),
            ],
          ),
        ),
      ),

      // 主体：模式选择
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          children: [
            // 欢迎文字
            Text(
              'Welcome to Mastermind!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleLarge!.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // —— 单人模式按钮 (Lone Wolf)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed: () {
                  Navigator.of(context).pushNamed('/game');
                },
                child: const Text('Lone Wolf'),
              ),
            ),
            const SizedBox(height: 20),

            // —— 双人模式按钮 (It Takes Two)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: theme.colorScheme.onSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed: () {
                  Navigator.of(context).pushNamed('/two_player_lobby');
                },
                child: const Text('It Takes Two'),
              ),
            ),
            const SizedBox(height: 20),

            // —— 游戏说明按钮 (Game Mechanics)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.primaryColor,
                  side: BorderSide(color: theme.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed: () {
                  Navigator.of(context).pushNamed('/game_mechanics');
                },
                child: const Text('Game Mechanics'),
              ),
            ),

            const Spacer(),

            // —— 版本号或其他信息
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodySmall!.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
