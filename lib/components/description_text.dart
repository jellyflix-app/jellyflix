import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    return secondHalf.isEmpty
        ? Text(firstHalf)
        : Column(
            children: <Widget>[
              showMore
                  ? Text(
                      widget.text,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    )
                  : Text(widget.text),
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
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ],
          );
  }
}
