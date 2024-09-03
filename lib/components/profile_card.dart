import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/providers/auth_provider.dart';

class ProfileCard extends ConsumerWidget {
  final String title;
  final String subtitle;
  final Widget image;
  final VoidCallback? onTap;
  final bool showDelButton;
  final String id;

  const ProfileCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.image,
    this.showDelButton = false,
    this.id = '',
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 150,
      height: 220,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                image,
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                if (showDelButton)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: 'Delete profile',
                    onPressed: id.isEmpty
                        ? null
                        : () async {
                            await ref.read(authProvider).logoutAndDeleteProfile(
                                profileId: '$id$subtitle');

                            if (context.mounted) {
                              ref.invalidate(allProfilesProvider);
                            }
                          },
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
