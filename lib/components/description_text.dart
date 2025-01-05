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

  bool showMoreState = false;

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
  @override
  Widget build(BuildContext context) {
    JfxLayout layout = JfxLayout.scalingLayout(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final textSpan = TextSpan(
          text: widget.text,
          style: layout.text.bodyLarge,
        );

        final textPainter = TextPainter(
          text: textSpan,
          maxLines: 4, // Set your max lines here
          textDirection: TextDirection.ltr,
        );

        textPainter.layout(maxWidth: constraints.maxWidth);

        final exceeded = textPainter.didExceedMaxLines;

        return Column(
          children: <Widget>[
            Text(
              widget.text,
              style: layout.text.bodyLarge,
              maxLines: showMoreState ? null : 4,
              overflow: exceeded
                  ? showMoreState
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis
                  : null,
            ),
            if (exceeded)
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  InkWell(
                    onTap: () {
                      setState(() {
                        showMoreState = !showMoreState;
                      });
                    },
                    child: Text(
                      showMoreState
                          ? AppLocalizations.of(context)!.showLess
                          : AppLocalizations.of(context)!.showMore,
                      style: layout.text.bodyLarge!.copyWith(
                        color: layout.color.primary,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}
