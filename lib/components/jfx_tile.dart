import 'package:flutter/material.dart';
import 'package:tentacle/tentacle.dart';
import 'package:jellyflix/components/jellyfin_image.dart';

class JfxTile extends StatelessWidget {
  final String id;
  final Widget? overlay;
  final String? blurHash;
  final VoidCallback onTap;

  const JfxTile({
    super.key,
    required this.id,
    required this.onTap,
    this.overlay,
    this.blurHash,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
        aspectRatio: 2 / 3,
        child: LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          double dragFeedbackSizeFactor = 1;
          // width < 200 ? 1.1 : .9;
          return LongPressDraggable(
            data: id,
            dragAnchorStrategy:
                (Draggable<Object> _, BuildContext __, Offset position) {
              final RenderBox renderObject =
                  context.findRenderObject()! as RenderBox;
              final pos = renderObject.globalToLocal(position);
              return Offset(
                  pos.dx - (width * ((1 - dragFeedbackSizeFactor) / 2)),
                  pos.dy - (width * ((1 - dragFeedbackSizeFactor) / 2)));
            }, // Pass whatever data you need
            feedback: SizedBox(
              width: width * dragFeedbackSizeFactor,
              height: height * dragFeedbackSizeFactor,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: JellyfinImage(
                      id: id,
                      type: ImageType.primary,
                      blurHash: blurHash,
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10.0),
                      onTap: onTap,
                    ),
                  ),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: JellyfinImage(
                      id: id,
                      type: ImageType.primary,
                      blurHash: blurHash,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10.0),
                      onTap: onTap,
                    ),
                  ),
                ),
                overlay != null ? overlay! : const SizedBox.shrink(),
              ],
            ),
          );
        }));
  }
}
