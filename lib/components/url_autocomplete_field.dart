import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/custom_autocomplete_options.dart';
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
        serverAddress.text = ref.read(selectedOptionProvider);
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
                      .contains(textEditingValue.text.toLowerCase()) &&
                  // ensure that the option is not already filled
                  element.serverAdress! != textEditingValue.text.toLowerCase(),
            )
            .map((e) => e.serverAdress!)
            .toSet(); // remove duplicates

        final options = result == null || result.isEmpty
            ? ['http://', 'https://'].where((e) =>
                e.contains(textEditingValue.text.toLowerCase()) &&
                // ensure that the option is not already filled
                e != textEditingValue.text.toLowerCase())
            : result;

        // clear options on change
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
}
