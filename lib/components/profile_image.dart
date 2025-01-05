import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/profile_placeholder_image.dart';
import 'package:jellyflix/models/user.dart';
import 'package:jellyflix/providers/auth_provider.dart';

class ProfileImage extends ConsumerWidget {
  final User? user;
  const ProfileImage({super.key, this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    User? currentUser = user ?? ref.read(authProvider).currentProfile;
    return CachedNetworkImage(
      width: double.infinity,
      fit: BoxFit.cover,
      imageUrl:
          "${currentUser?.serverAdress}/Users/${currentUser?.id}/Images/Profile",
      placeholder: (context, url) {
        return const ProfilePlaceholderImage();
      },
      errorWidget: (context, url, error) {
        return const ProfilePlaceholderImage();
      },
      errorListener: (value) {
        //! Errors can't be caught right now
        //! There is a pr to fix this
      },
    );
  }
}
