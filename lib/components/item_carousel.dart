import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:jellyflix/components/item_carousel_label.dart';
import 'package:jellyflix/components/jfx_tile.dart';
import 'package:jellyflix/components/jfx_layout.dart';
import 'package:jellyflix/models/poster_type.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ItemCarousel extends StatefulHookConsumerWidget {
  final String? title;
  final List titleList;
  final List imageList;
  final List subtitleList;
  final List? blurHashList;
  final List<Widget>? overlay;
  final PosterType posterType;
  final Function(int)? onTap;
  final Function? onEnd;
  final ScrollController? scrollController;

  ItemCarousel(
      {this.onTap,
      required this.imageList,
      required this.titleList,
      this.blurHashList,
      this.title,
      this.overlay,
      subtitleList,
      this.onEnd,
      this.posterType = PosterType.vertical,
      this.scrollController,
      super.key})
      : subtitleList = subtitleList ?? [];

  @override
  ConsumerState<ItemCarousel> createState() => _ItemCarouselState();
}

class _ItemCarouselState extends ConsumerState<ItemCarousel> {
  late final ScrollController scrollController;

  var hasClients = false;
  var isLoading = false;
  ValueNotifier<bool> showArrows = ValueNotifier(false);
  @override
  void initState() {
    super.initState();
    scrollController = widget.scrollController ?? ScrollController();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients != hasClients) {
        setState(() {
          hasClients = scrollController.hasClients;
        });
      }
    });

    scrollController.addListener(() {
      if (scrollController.position.maxScrollExtent * 0.7 <=
          scrollController.position.pixels) {
        if (widget.onEnd != null) {
          widget.onEnd!();
        }
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var layout = JfxLayout.scalingLayout(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: ItemCarouselLabel(
              title: widget.title,
              scrollController: scrollController,
              offsetWidth: (450)),
        ),
        const SizedBox(height: 5.0),
        SizedBox(
          height: layout.tileHeight,
          child: ListView.builder(
            controller: scrollController,
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            itemCount: widget.titleList.length,
            itemBuilder: (context, index) {
              return JfxTile(
                  id: widget.imageList[index],
                  tileHeight: layout.tileHeight,
                  tileWidth: layout.tileWidth,
                  blurHash: widget.blurHashList == null
                      ? null
                      : widget.blurHashList![index],
                  onTap: () {
                    if (widget.onTap != null) {
                      widget.onTap!(index);
                    }
                  });
            },
          ),
        ),
      ],
    );
  }
}
