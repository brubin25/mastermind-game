// lib/ui/screen/components/key_input.dart

import 'package:flutter/material.dart';

class KeyInput extends StatelessWidget {
  final String value;
  final VoidCallback onTap;
  const KeyInput({
    Key? key,
    required this.value,
    required this.onTap,
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
          color: Colors.transparent, // 纯占位，保持透明
        ),
        child: Center(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 18,
              color: theme.textTheme.bodyMedium!.color,
            ),
          ),
        ),
      ),
    );
  }
}
