import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class QuickConnectDialog extends HookConsumerWidget {
  const QuickConnectDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codeController = useTextEditingController();
    final errorText = useState<String?>(null);

    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.background,
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.quickConnect,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Text(AppLocalizations.of(context)!.quickConnectDescription),
            const SizedBox(height: 20),
            SizedBox(
              width: 250,
              child: TextField(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.code,
                  hintText: "123456",
                  border: const OutlineInputBorder(),
                  errorText: errorText.value,
                ),
                controller: codeController,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                int isSuccess = await ref
                    .read(apiProvider)
                    .authorizeQuickConnect(codeController.text);
                switch (isSuccess) {
                  case 200:
                    if (context.mounted) {
                      context.pop();
                    }
                    break;
                  case 401:
                    if (context.mounted) {
                      errorText.value =
                          AppLocalizations.of(context)!.quickConnectError401;
                    }
                    break;
                  case 404:
                    if (context.mounted) {
                      errorText.value =
                          AppLocalizations.of(context)!.quickConnectError404;
                    }
                    break;
                  default:
                    if (context.mounted) {
                      errorText.value = AppLocalizations.of(context)!
                          .quickConnectErrorUnknown;
                    }
                    break;
                }
              },
              child: Text(AppLocalizations.of(context)!.connect),
            ),
          ],
        ),
      ),
    );
  }
}
