import 'package:flutter/material.dart';

class ProfilePlaceholderImage extends StatelessWidget {
  const ProfilePlaceholderImage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      width: 100,
      height: 100,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: const Icon(
          Icons.person,
          size: 50,
        ),
      ),
    );
  }
}
