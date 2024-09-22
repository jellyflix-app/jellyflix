import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/custom_autocomplete_options.dart';
import 'package:jellyflix/models/user.dart';
import 'package:jellyflix/providers/auth_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:jellyflix/providers/url_autocomplete_provider.dart';

// Courtesy of sevenrats for the shortcuts

class UrlFieldInput extends ConsumerWidget {
  const UrlFieldInput({super.key, required this.serverAddress});

  final TextEditingController serverAddress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAddress = ref.read(allProfilesProvider);

    // Needed to get width of the URL text field
    // so we can assign that to the autocomplete width
    final urlTextFieldKey = GlobalKey();

    // Create a custom FocusNode to listen for key events
    final focusNode = FocusNode();

    // Attach the key listener for Tab key press
    focusNode.onKeyEvent = (FocusNode node, KeyEvent event) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.enter) {
        _selectAutocompleteOption(focusNode, serverAddress, savedAddress, ref);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    };

    return RawAutocomplete<String>(
      focusNode: focusNode,
      textEditingController: serverAddress,
      optionsBuilder: (TextEditingValue textEditingValue) {
        final result = savedAddress.valueOrNull
            ?.where(
              (element) =>
                  element.serverAdress!
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase()) &&
                  element.serverAdress! != textEditingValue.text.toLowerCase(),
            )
            .map((e) => e.serverAdress!)
            .toSet(); // remove duplicates

        final options = result == null || result.isEmpty
            ? ['http://', 'https://'].where((e) =>
                e.contains(textEditingValue.text.toLowerCase()) &&
                e != textEditingValue.text.toLowerCase())
            : result;

        ref.watch(optionsListProvider.notifier).overwriteList(options);
        ref.invalidate(selectedOptionProvider);

        return options;
      },
      onSelected: (option) => serverAddress.text = option,
      optionsViewOpenDirection: OptionsViewOpenDirection.down,
      fieldViewBuilder: (context, controller, focusNode, _) {
        return TextField(
          key: urlTextFieldKey,
          focusNode: focusNode,
          controller: controller,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: AppLocalizations.of(context)!.serverAddress,
            hintText: 'http://',
          ),
        );
      },
      optionsViewBuilder: (
        BuildContext context,
        void Function(String) onSelected,
        Iterable<String> options,
      ) {
        RenderBox? renderBox;
        if (urlTextFieldKey.currentContext?.findRenderObject() != null) {
          renderBox =
              urlTextFieldKey.currentContext!.findRenderObject() as RenderBox;
        }

        return CustomAutocompleteOptions(
          displayStringForOption: RawAutocomplete.defaultStringForOption,
          onSelected: onSelected,
          options: options,
          openDirection: OptionsViewOpenDirection.down,
          maxOptionsHeight: 150,
          maxOptionsWidth: renderBox?.size.width ?? 300,
        );
      },
    );
  }

  void _selectAutocompleteOption(
    FocusNode focusNode,
    TextEditingController controller,
    AsyncValue<List<User>> savedAddress,
    WidgetRef ref,
  ) {
    final selectedInd = ref.read(selectedOptionProvider);
    // there is a potential race condition that happens occasionally essentially
    // sometimes the optionsListProvider remains empty even after options are built
    // I don't understand why it happens, cannot recreate it and is pretty much random,
    // so its wrapped in a try catch
    final currentOptions = ref.read(optionsListProvider);
    try {
      final option = currentOptions[selectedInd];

      controller.text = option;
      // Move the cursor to the end of the text
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Option list accessed a element out of bounds');
        print('The following are the available options');
        print(currentOptions);
        print('Index that was accessed');
        print(selectedInd);
        print(e);
      }
    }
  }
}
