import 'package:flutter/material.dart';

class QuickAddFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;

  const QuickAddFAB({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(onPressed: onPressed, child: Icon(icon));
  }
}
