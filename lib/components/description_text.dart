import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:jellyflix/components/jfx_layout.dart';

class DescriptionText extends StatefulWidget {
  final String text;
  final int firstHalfLength;

  const DescriptionText(
      {super.key, required this.text, this.firstHalfLength = 200});

  @override
  DescriptionTextState createState() => DescriptionTextState();
}

class DescriptionTextState extends State<DescriptionText> {
  late String firstHalf;
  late String secondHalf;

  bool showMore = true;

  @override
  void initState() {
    super.initState();

    if (widget.text.length > widget.firstHalfLength) {
      firstHalf = widget.text.substring(0, widget.firstHalfLength);
      secondHalf =
          widget.text.substring(widget.firstHalfLength, widget.text.length);
    } else {
      firstHalf = widget.text;
      secondHalf = "";
    }
  }

  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = JfxTextTheme.scalingTheme(context);
    return secondHalf.isEmpty
        ? Text(style: textTheme.bodyLarge, firstHalf)
        : Column(
            children: <Widget>[
              showMore
                  ? Text(
                      style: textTheme.bodyLarge,
                      widget.text,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    )
                  : Text(style: textTheme.bodyLarge, widget.text),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  InkWell(
                    onTap: () {
                      setState(() {
                        showMore = !showMore;
                      });
                    },
                    child: Text(
                      showMore
                          ? AppLocalizations.of(context)!.showMore
                          : AppLocalizations.of(context)!.showLess,
                      style: textTheme.bodyLarge!.copyWith(
                          color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ],
          );
  }
}
