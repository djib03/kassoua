import 'package:flutter/material.dart';
import 'package:dm_shop/constants/colors.dart';

class THelperFunctions {
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}

class TFormDivider extends StatelessWidget {
  const TFormDivider({super.key, required this.dividerText});

  final String dividerText;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Divider(
            color: dark ? DMColors.darkGrey : DMColors.grey,
            thickness: 0.5,
            indent: 60,
            endIndent: 5,
          ),
        ),
        Text(dividerText, style: Theme.of(context).textTheme.labelMedium),
        Flexible(
          child: Divider(
            color: dark ? DMColors.darkGrey : DMColors.grey,
            thickness: 0.5,
            indent:
                5, // Swapped indent and endIndent for symmetry or adjust as needed
            endIndent: 60,
          ),
        ),
      ],
    );
  }
}
