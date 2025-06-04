// lib/ui/screen/settings_screen.dart

import 'package:flutter/material.dart';
import '../../main.dart'; // 访问全局 themeNotifier

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 本地保留当前选中的 ThemeMode，以便 RadioListTile 正确高亮
  late ThemeMode _chosenTheme;

  @override
  void initState() {
    super.initState();
    // 页面打开时，从全局拿当前的 themeMode
    _chosenTheme = themeNotifier.value;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // —— 大标题：“Theme”
          Text(
            'Theme',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge!.color,
            ),
          ),
          const SizedBox(height: 12),

          // —— 系统默认
          RadioListTile<ThemeMode>(
            title: Text(
              'System Default',
              style: TextStyle(color: theme.textTheme.bodyMedium!.color),
            ),
            value: ThemeMode.system,
            groupValue: _chosenTheme,
            onChanged: (ThemeMode? newMode) {
              if (newMode == null) return;
              setState(() {
                _chosenTheme = newMode;
              });
              // 更新全局值，触发 MyApp 重建
              themeNotifier.value = newMode;
            },
          ),

          // —— Light
          RadioListTile<ThemeMode>(
            title: Text(
              'Light',
              style: TextStyle(color: theme.textTheme.bodyMedium!.color),
            ),
            value: ThemeMode.light,
            groupValue: _chosenTheme,
            onChanged: (ThemeMode? newMode) {
              if (newMode == null) return;
              setState(() {
                _chosenTheme = newMode;
              });
              themeNotifier.value = newMode;
            },
          ),

          // —— Dark
          RadioListTile<ThemeMode>(
            title: Text(
              'Dark',
              style: TextStyle(color: theme.textTheme.bodyMedium!.color),
            ),
            value: ThemeMode.dark,
            groupValue: _chosenTheme,
            onChanged: (ThemeMode? newMode) {
              if (newMode == null) return;
              setState(() {
                _chosenTheme = newMode;
              });
              themeNotifier.value = newMode;
            },
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),

          // —— 之后可以继续在这里加入“Sound Effects”开关、BGM 开关等
          //    比如：SwitchListTile(label: Text('Tap Sounds'), value: _tapSoundOn, onChanged: …)
        ],
      ),
    );
  }
}
