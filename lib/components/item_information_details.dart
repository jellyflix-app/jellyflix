import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tentacle/tentacle.dart';

class ItemInformationDetails extends StatelessWidget {
  const ItemInformationDetails({
    super.key,
    required this.item,
  });

  final BaseItemDto item;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                AppLocalizations.of(context)!.writers,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text(item.people!
                      .where((element) => element.type == 'Writer')
                      .isEmpty
                  ? 'N/A'
                  : item.people!
                      .where((element) => element.type == 'Writer')
                      .map((e) => e.name!)
                      .join(", ")),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                AppLocalizations.of(context)!.directors,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text(item.people!
                      .where((element) => element.type == 'Director')
                      .isEmpty
                  ? AppLocalizations.of(context)!.na
                  : item.people!
                      .where((element) => element.type == 'Director')
                      .map((e) => e.name!)
                      .join(", ")),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                AppLocalizations.of(context)!.genres,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text(
                item.genres!.isEmpty
                    ? AppLocalizations.of(context)!.na
                    : item.genres!.join(", "),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
