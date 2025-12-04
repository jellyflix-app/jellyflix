import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/l10n/generated/app_localizations.dart';

class MpvConfigDialog extends HookConsumerWidget {
  const MpvConfigDialog({
    super.key,
    required String mpvConfig,
  }) : _mpvConfig = mpvConfig;

  final String _mpvConfig;

  static String getDefaultConfig() {
    return "# MPV Configuration File\n";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mpvConfig = useState(_mpvConfig);
    final textController = useTextEditingController(text: _mpvConfig);

    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.mpvConfigTitle),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.customMpvConfigDescription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              maxLines: 10,
              minLines: 5,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'hwdec=auto\ncache=yes\ncache-secs=120',
                contentPadding: const EdgeInsets.all(12),
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              onChanged: (value) {
                mpvConfig.value = value;
              },
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(
                      AppLocalizations.of(context)!.mpvConfigResetConfirm,
                    ),
                    content: Text(
                      AppLocalizations.of(context)!.mpvConfigResetDescription,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        child: Text(AppLocalizations.of(context)!.cancel),
                      ),
                      TextButton(
                        onPressed: () {
                          final defaultConfig = getDefaultConfig();
                          textController.text = defaultConfig;
                          mpvConfig.value = defaultConfig;
                          Navigator.pop(dialogContext);
                        },
                        child: Text(AppLocalizations.of(context)!.reset),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)!.resetToDefault),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, null);
          },
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, mpvConfig.value);
          },
          child: Text(AppLocalizations.of(context)!.save),
        ),
      ],
    );
  }
}
