import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/jfx_layout.dart';
import 'package:markdown/markdown.dart' as markdown;

class DescriptionText extends HookConsumerWidget {
  final String text;
  final int firstHalfLength;

  const DescriptionText(
      {super.key, required this.text, this.firstHalfLength = 200});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    JfxLayout layout = JfxLayout.scalingLayout(context);

    final showMoreState = useState(false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final textSpan = TextSpan(
          text: text,
          style: layout.text.bodyLarge,
        );

        final textPainter = TextPainter(
          text: textSpan,
          maxLines: 4,
          textDirection: TextDirection.ltr,
          ellipsis: '...',
        );

        textPainter.layout(maxWidth: constraints.maxWidth);

        final exceeded = textPainter.didExceedMaxLines;
        final firstHalf =
            '${text.substring(0, textPainter.getPositionForOffset(Offset(constraints.maxWidth, textPainter.height)).offset)}...';
        return Column(
          children: <Widget>[
            HtmlWidget(
              showMoreState.value
                  ? markdown.markdownToHtml(text)
                  : markdown.markdownToHtml(firstHalf),
              textStyle: layout.text.bodyLarge,
            ),
            if (exceeded)
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  InkWell(
                    onTap: () {
                      showMoreState.value = !showMoreState.value;
                    },
                    child: Text(
                      showMoreState.value
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
