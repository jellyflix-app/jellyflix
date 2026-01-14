import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/l10n/generated/app_localizations.dart';
import 'package:jellyflix/models/home_screen_config.dart';
import 'package:jellyflix/providers/database_provider.dart';

class HomeScreenConfigScreen extends HookConsumerWidget {
  const HomeScreenConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final errorMessage = useState<String?>(null);
    final isSaved = useState(false);

    useEffect(() {
      final savedConfig =
          ref.read(databaseProvider('settings')).get('homeScreenConfig');
      if (savedConfig != null) {
        controller.text = savedConfig as String;
      } else {
        controller.text = HomeScreenConfig.getDefault().toJsonString();
      }
      return null;
    }, []);

    void validateConfig() {
      final result = HomeScreenConfig.validate(controller.text);
      if (result.isValid) {
        errorMessage.value = null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.configurationValid),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        errorMessage.value = result.error;
      }
    }

    void saveConfig() {
      final result = HomeScreenConfig.validate(controller.text);
      if (!result.isValid) {
        errorMessage.value = result.error;
        return;
      }

      ref
          .read(databaseProvider('settings'))
          .put('homeScreenConfig', controller.text);
      isSaved.value = true;
      errorMessage.value = null;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.configurationSaved),
          backgroundColor: Colors.green,
        ),
      );
    }

    void resetToDefault() {
      controller.text = HomeScreenConfig.getDefault().toJsonString();
      errorMessage.value = null;
      isSaved.value = false;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.homeScreenSettings),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: resetToDefault,
            tooltip: AppLocalizations.of(context)!.resetToDefault,
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: validateConfig,
            tooltip: AppLocalizations.of(context)!.validate,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: saveConfig,
            tooltip: AppLocalizations.of(context)!.save,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocalizations.of(context)!.homeScreenConfigDescription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (errorMessage.value != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage.value!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            if (errorMessage.value != null) const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: null,
                expands: true,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.pasteConfigHere,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.all(16),
                ),
                onChanged: (_) {
                  isSaved.value = false;
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: resetToDefault,
                    child: Text(AppLocalizations.of(context)!.resetToDefault),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: validateConfig,
                    child: Text(AppLocalizations.of(context)!.validate),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: saveConfig,
                    child: Text(AppLocalizations.of(context)!.save),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  if (isSaved.value) {
                    context.pop();
                  } else {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(AppLocalizations.of(context)!.unsavedChanges),
                        content: Text(AppLocalizations.of(context)!
                            .unsavedChangesWarning),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(AppLocalizations.of(context)!.cancel),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              context.pop();
                            },
                            child: Text(AppLocalizations.of(context)!.discard),
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: Text(AppLocalizations.of(context)!.back),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
