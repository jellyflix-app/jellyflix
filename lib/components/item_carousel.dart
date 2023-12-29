import 'package:jellyflix/models/poster_type.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openapi/openapi.dart';

class ItemCarousel extends HookConsumerWidget {
  final String? title;
  final List titleList;
  final List imageList;
  final List subtitleList;
  final List? blurHashList;
  final PosterType posterType;
  final Function(int)? onTap;
  late final double width;
  late final double height;

  ItemCarousel(
      {this.onTap,
      required this.imageList,
      required this.titleList,
      this.blurHashList,
      this.title,
      subtitleList,
      this.posterType = PosterType.vertical,
      super.key})
      : subtitleList = subtitleList ?? [];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ScrollController scrollController = useScrollController();
    switch (posterType) {
      case PosterType.horizontal:
        width = 250;
        height = 150;
        break;
      case PosterType.square:
        width = 150;
        height = 150;
        break;
      default:
        width = 150;
        height = 200;
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title == null
            ? const SizedBox()
            : Text(
                title!,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
        const SizedBox(height: 5.0),
        SizedBox(
          height: 250,
          child: ListView.builder(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemCount: titleList.length,
            itemBuilder: (context, index) {
              return SizedBox(
                width: width,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: width,
                        height: height,
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
                                  child: ref.read(apiProvider).newgetImage(
                                      id: imageList[index],
                                      type: ImageType.primary,
                                      blurHash: blurHashList == null
                                          ? null
                                          : blurHashList![index])),
                            ),
                            Positioned.fill(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    if (onTap != null) {
                                      onTap!(index);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5.0),
                      Flexible(
                        child: Text(
                          titleList[index],
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      subtitleList.isNotEmpty
                          ? Text(
                              subtitleList[index],
                              style: const TextStyle(fontSize: 10),
                              overflow: TextOverflow.fade,
                              maxLines: 1,
                            )
                          : const SizedBox(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
