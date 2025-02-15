import 'package:flutter/material.dart';

class NavigationDrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final GestureTapCallback onTap;
  final bool selected;
  const NavigationDrawerTile({
    required this.onTap,
    required this.icon,
    required this.label,
    super.key,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        child: Material(
          color: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
          //color: Theme.of(context).navigationRailTheme.indicatorColor,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: onTap,
            overlayColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Icon(icon),
                  const SizedBox(
                    width: 15,
                  ),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodyLarge,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
