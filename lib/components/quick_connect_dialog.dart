import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/providers/api_provider.dart';

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
              "Quick Connect",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            const Text("Enter the code displayed on your device"),
            const SizedBox(height: 20),
            SizedBox(
              width: 250,
              child: TextField(
                decoration: InputDecoration(
                  labelText: "Code",
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
                  if (isSuccess == 200) {
                  } else {
                    errorText.value = "Invalid code";
                  }
                  switch (isSuccess) {
                    case 200:
                      if (context.mounted) {
                        context.pop();
                      }
                      break;
                    case 401:
                      errorText.value = "Are you accessing the right server?";
                      break;
                    case 404:
                      errorText.value = "Invalid code";
                      break;
                    default:
                      errorText.value = "Something went wrong";
                      break;
                  }
                },
                child: const Text("Connect"))
          ],
        ),
      ),
    );
  }
}
