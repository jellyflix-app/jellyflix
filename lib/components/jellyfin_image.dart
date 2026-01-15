import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:jellyflix/providers/database_provider.dart';
import 'package:tentacle/tentacle.dart';
import 'package:transparent_image/transparent_image.dart';

class JellyfinImage extends HookConsumerWidget {
  final String id;
  final ImageType type;
  final String? blurHash;
  final int? cacheHeight;
  final BorderRadius? borderRadius;

  const JellyfinImage(
      {super.key,
      required this.id,
      required this.type,
      this.blurHash,
      this.cacheHeight,
      this.borderRadius});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String url = ref.read(apiProvider).getImageUrl(id, type);
    bool disableImageCaching =
        ref.read(databaseProvider("settings")).get("disableImageCaching") ??
            false;
    if (disableImageCaching == true) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(12.0),
        // BlurHash has an issue the generates bad state in some cases
        // https://github.com/fluttercommunity/flutter_blurhash/issues/40
        child: BlurHash(
          hash: blurHash ?? "L5H2EC=PM+yV0g-mq.wG9GofR*of",
          imageFit: BoxFit.cover,
          httpHeaders: ref.read(apiProvider).headers,
          image: url,
          errorBuilder: (context, error, stackTrace) {
            return Image.memory(kTransparentImage, fit: BoxFit.cover);
          },
        ),
      );
    }

    return CachedNetworkImage(
      width: double.infinity,
      imageUrl: url,
      httpHeaders: ref.read(apiProvider).headers,
      fit: BoxFit.cover,
      memCacheHeight: cacheHeight,
      maxHeightDiskCache: cacheHeight,
      imageBuilder: (context, imageProvider) => Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? BorderRadius.circular(12.0),
          image: DecorationImage(
            image: imageProvider,
            fit: BoxFit.cover,
          ),
        ),
      ),
      placeholder: blurHash == null
          ? null
          : (context, url) {
              return ClipRRect(
                borderRadius: borderRadius ?? BorderRadius.circular(12.0),
                child: BlurHash(
                  hash: blurHash!,
                  imageFit: BoxFit.cover,
                ),
              );
            },
      errorWidget: (context, url, error) {
        return const SizedBox();
      },
      errorListener: (value) {
        //! Errors can't be caught right now
        //! There is a pr to fix this: https://github.com/Baseflow/flutter_cached_network_image/pull/777
      },
    );
  }
}
