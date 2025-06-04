import 'package:flutter/material.dart';
import 'package:kassoua/constants/colors.dart';

class AppBarAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDark;

  const AppBarAction({
    Key? key,
    required this.icon,
    required this.onPressed,
    required this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: isDark ? DMColors.dark : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isDark ? DMColors.textWhite : DMColors.black,
          size: 20,
        ),
        onPressed: onPressed,
      ),
    );
  }
}
