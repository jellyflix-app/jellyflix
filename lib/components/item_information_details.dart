import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tentacle/tentacle.dart';
import 'package:jellyflix/components/jfx_layout.dart';

class ItemInformationDetails extends StatelessWidget {
  const ItemInformationDetails({
    super.key,
    required this.item,
  });

  final BaseItemDto item;

  @override
  Widget build(BuildContext context) {
    final JfxLayout layout = JfxLayout.scalingLayout(context);
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                AppLocalizations.of(context)!.writers,
                style: layout.text.bodyLarge!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text(
                  item.people!
                          .where((element) => element.type == PersonKind.writer)
                          .isEmpty
                      ? 'N/A'
                      : item.people!
                          .where((element) => element.type == PersonKind.writer)
                          .map((e) => e.name!)
                          .join(", "),
                  style: layout.text.bodyLarge),
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
                style: layout.text.bodyLarge!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text(
                  item.people!
                          .where(
                              (element) => element.type == PersonKind.director)
                          .isEmpty
                      ? AppLocalizations.of(context)!.na
                      : item.people!
                          .where(
                              (element) => element.type == PersonKind.director)
                          .map((e) => e.name!)
                          .join(", "),
                  style: layout.text.bodyLarge),
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
                style: layout.text.bodyLarge!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text(
                  item.genres!.isEmpty
                      ? AppLocalizations.of(context)!.na
                      : item.genres!.join(", "),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: layout.text.bodyLarge),
            ),
          ],
        ),
      ],
    );
  }
}
