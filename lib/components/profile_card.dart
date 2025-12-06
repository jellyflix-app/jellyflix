import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/providers/auth_provider.dart';
import 'package:jellyflix/components/focus_border.dart';

class ProfileCard extends ConsumerStatefulWidget {
  final String title;
  final String subtitle;
  final Widget image;
  final VoidCallback? onTap;
  final bool showDelButton;
  final String id;
  final FocusNode? focusNode;

  const ProfileCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.image,
    this.showDelButton = false,
    this.id = '',
    this.onTap,
    this.focusNode,
  });

  @override
  ConsumerState<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends ConsumerState<ProfileCard> {
  late FocusNode _internalFocusNode;
  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      child: FocusBorder(
        focusNode: _focusNode,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 150,
          height: 220,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: InkWell(
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    widget.image,
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      widget.subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    if (widget.showDelButton)
                      IconButton(
                        icon: const Icon(Icons.delete),
                        tooltip: 'Delete profile',
                        onPressed: widget.id.isEmpty
                            ? null
                            : () async {
                                await ref
                                    .read(authProvider)
                                    .logoutAndDeleteProfile(
                                        profileId:
                                            '${widget.id}${widget.subtitle}');

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
        ),
      ),
    );
  }
}
