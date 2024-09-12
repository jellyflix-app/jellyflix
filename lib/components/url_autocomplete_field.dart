import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/custom_autocomplete_options.dart';
import 'package:jellyflix/providers/auth_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class UrlFieldInput extends ConsumerWidget {
  const UrlFieldInput({super.key, required this.serverAddress});

  final TextEditingController serverAddress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAddress = ref.watch(allProfilesProvider);

    // needed to get width of the url text filed
    // so we can assign that to the autocomplete width
    final urlTextFieldKey = GlobalKey();

    return RawAutocomplete<String>(
      focusNode: FocusNode(),
      textEditingController: serverAddress,
      optionsBuilder: (TextEditingValue textEditingValue) {
        final result = savedAddress.valueOrNull
            ?.where((element) => element.serverAdress!
                .toLowerCase()
                .contains(textEditingValue.text.toLowerCase()))
            .map((e) => e.serverAdress!);
        return result == null || result.isEmpty
            ? ['http://', 'https://']
                .where((e) => e.contains(textEditingValue.text.toLowerCase()))
            : result;
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
          maxOptionsHeight: 100,
          maxOptionsWidth: renderBox?.size.width ?? 300,
        );
      },
    );
  }
}
