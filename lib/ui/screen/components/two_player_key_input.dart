// lib/ui/screen/components/two_player_key_input.dart

import 'package:flutter/material.dart';

class TwoPlayerKeyInput extends StatelessWidget {
  final String value;
  final VoidCallback onTap;
  final bool isHost;

  const TwoPlayerKeyInput({
    Key? key,
    required this.value,
    required this.onTap,
    required this.isHost,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: theme.dividerColor),
          color: Colors.transparent, // 占位透明
        ),
        child: Center(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 18,
              color: isHost
                  ? theme.colorScheme.primary
                  : theme.colorScheme.secondary,
            ),
          ),
        ),
      ),
    );
  }
}
