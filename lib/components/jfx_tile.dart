import 'package:flutter/material.dart';
import 'package:tentacle/tentacle.dart';
import 'package:jellyflix/components/jellyfin_image.dart';

class JfxTile extends StatefulWidget {
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
  State<JfxTile> createState() => _JfxTileState();
}

class _JfxTileState extends State<JfxTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
        aspectRatio: 2 / 3,
        child: LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          double dragFeedbackSizeFactor = 1;
          // width < 200 ? 1.1 : .9;
          return MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: AnimatedScale(
              scale: _isHovered ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: LongPressDraggable(
                data: widget.id,
                dragAnchorStrategy:
                    (Draggable<Object> _, BuildContext __, Offset position) {
                  final RenderBox renderObject =
                      context.findRenderObject()! as RenderBox;
                  final pos = renderObject.globalToLocal(position);
                  return Offset(
                      pos.dx - (width * ((1 - dragFeedbackSizeFactor) / 2)),
                      pos.dy - (width * ((1 - dragFeedbackSizeFactor) / 2)));
                },
                feedback: SizedBox(
                  width: width * dragFeedbackSizeFactor,
                  height: height * dragFeedbackSizeFactor,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              spreadRadius: 0,
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: JellyfinImage(
                          id: widget.id,
                          type: ImageType.primary,
                          blurHash: widget.blurHash,
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12.0),
                          onTap: widget.onTap,
                        ),
                      ),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: _isHovered ? 0.5 : 0.3),
                              spreadRadius: 0,
                              blurRadius: _isHovered ? 25 : 15,
                              offset: Offset(0, _isHovered ? 10 : 6),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              spreadRadius: 0,
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: JellyfinImage(
                          id: widget.id,
                          type: ImageType.primary,
                          blurHash: widget.blurHash,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12.0),
                          onTap: widget.onTap,
                        ),
                      ),
                    ),
                    widget.overlay != null ? widget.overlay! : const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
          );
        }));
  }
}
