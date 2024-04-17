import 'package:flutter/material.dart';
import 'package:openapi/openapi.dart';
import 'package:jellyflix/components/jellyfin_image.dart';

class JfxTile extends StatelessWidget {
  final String id;
  final String? title;
  final String? subtitle;
  final String? blurHash;
  final double tileWidth;
  final double tileHeight;
  final VoidCallback onTap;

  const JfxTile({
    super.key,
    required this.id,
    this.title,
    this.subtitle,
    required this.tileWidth,
    required this.tileHeight,
    required this.onTap,
    this.blurHash,
  });

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable(
      data: id, // Pass whatever data you need
      feedback: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: tileWidth,
            height: tileHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
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
              ],
            ),
          )
        ],
      ),
      child: SizedBox(
        width: tileWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: tileWidth,
              height: tileHeight, // Set height in relation to width,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
