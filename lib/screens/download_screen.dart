import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:jellyflix/components/download_item_tile.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/providers/download_provider.dart';

class DownloadScreen extends HookConsumerWidget {
  const DownloadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.downloads),
      ),
      body: FutureBuilder(
        future: ref.read(getDownloadsProvider),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return DownloadItemTile(index: snapshot.data![index]);
              },
            );
          } else {
            return Center(
              child: Text(AppLocalizations.of(context)!.noDownloads),
            );
          }
        },
      ),
    );
  }
}
