import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/playback_progress_overlay.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:openapi/openapi.dart';

class ItemListTile<T1 extends BaseItemDto, T2> extends HookConsumerWidget {
  const ItemListTile({
    super.key,
    required this.item,
    this.onTap,
    this.onSelectedMenuItem,
    this.overlay,
    this.popupMenuEntries,
    this.title,
    this.subtitle,
    this.leading,
    this.height,
  });

  final T1 item;
  final GestureTapCallback? onTap;
  final Function(T2)? onSelectedMenuItem;
  final Widget? overlay;
  final List<PopupMenuItem<T2>>? popupMenuEntries;
  final Widget? title;
  final Widget? subtitle;
  final Widget? leading;
  final double? height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: height ?? 125,
      child: InkWell(
        borderRadius: BorderRadius.circular(10.0),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: leading,
                      ),
                      if (overlay != null) overlay!,
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20.0),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title ?? const SizedBox.shrink(),
                      subtitle ?? const SizedBox.shrink(),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              if (popupMenuEntries != null)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: PopupMenuButton<T2>(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0)),
                    itemBuilder: (BuildContext context) =>
                        popupMenuEntries ?? [],
                    onSelected: onSelectedMenuItem,
                    icon: const Icon(Icons.more_vert),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
