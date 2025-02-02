import 'package:flutter/material.dart';

class FilterButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final int length;

  const FilterButton(
      {super.key, this.onPressed, required this.text, required this.length});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
            (states) => Theme.of(context).focusColor),
      ),
      onPressed: onPressed,
      child: Row(
        children: [
          Text(
            text,
            overflow: TextOverflow.ellipsis,
          ),
          if (length > 1)
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).buttonTheme.colorScheme!.primary,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  "$length",
                  style: TextStyle(
                    color: Theme.of(context).buttonTheme.colorScheme!.onPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
