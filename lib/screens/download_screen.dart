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
        title: Row(
          children: [
            Text(AppLocalizations.of(context)!.downloads),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).buttonTheme.colorScheme!.onSecondary,
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Text(
                'Beta',
                style: TextStyle(
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder(
        future: ref.read(getDownloadsProvider),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return DownloadItemTile(itemId: snapshot.data![index]);
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
