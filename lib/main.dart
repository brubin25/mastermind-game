// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';

// 下面引入我们所有独立的 Screen（注意要确保路径和文件夹对应）
import 'ui/screen/login_screen.dart';
import 'ui/screen/signup_screen.dart';
import 'ui/screen/record_screen.dart';
import 'ui/screen/leaderboard_screen.dart';
import 'ui/screen/home_screen.dart';                 // ← ModeSelectionScreen 所在
import 'ui/screen/game.dart';                        // ← 单人游戏主界面
import 'ui/screen/game_mechanics_screen.dart';
import 'ui/screen/two_player_lobby_screen.dart';
import 'ui/screen/two_player_game_screen.dart';
import 'ui/screen/settings_screen.dart';
import 'models/game_mode.dart';

/// 全局的 ThemeMode 通知者
ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

/// MyApp：整个应用的根组件，只负责初始化 MaterialApp
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 用 ValueListenableBuilder 来监听 themeNotifier.value，
    // 当用户在 SettingsScreen 里更改后，这里会 rebuild，实时切换主题。
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, child) {
        return MaterialApp(
          title: 'Mastermind Game',
          debugShowCheckedModeBanner: false,

          // —— 亮色主题
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: Colors.grey[50],
            cardColor: Colors.white,
            // 如有需要可以在这里再定制更多 Light 主题下的默认样式
          ),

          // —— 暗色主题
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: Colors.grey[900],
            cardColor: Colors.grey[850],
            // 如需定制更多 Dark 主题下的样式也可以在这里写
          ),

          // —— 让 ThemeMode 根据当前 themeNotifier.value（System/Light/Dark）进行切换
          themeMode: currentTheme,

          // —— 根据登录状态决定首屏：如果已经登录，显示主页面；否则显示登录页
          home: const AuthenticationWrapper(),

          // —— 命名路由表（把所有 Screen 在此注册）
          routes: {
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignupScreen(),
            '/home': (context) => const ModeSelectionScreen(),
            '/record': (context) => const RecordScreen(),
            '/leaderboard': (context) => const LeaderboardScreen(),
            '/game': (context) => const GameScreen(mode: GameMode.single),
            '/two_player_lobby': (context) => const TwoPlayerLobbyScreen(),
            // '/two_player_game' 特殊：游戏 ID 需要通过 arguments 传递
            '/two_player_game': (context) => const TwoPlayerGameScreen(mode: GameMode.twoPlayer, gameId: ''),
            '/game_mechanics': (context) => const GameMechanicsScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
        );
      },
    );
  }
}

/// AuthenticationWrapper：自动根据用户是否登录来切换首屏
class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 如果有用户对象(已登录)，直接去主页面 → ModeSelectionScreen()
        if (snapshot.hasData && snapshot.data != null) {
          return const ModeSelectionScreen();
        }
        // 否则去登录页
        return const LoginScreen();
      },
    );
  }
}
