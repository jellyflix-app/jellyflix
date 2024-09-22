import 'package:hooks_riverpod/hooks_riverpod.dart';

// helpful providers to run autocompleting urls

final optionsListProvider =
    NotifierProvider.autoDispose<OptionsListNotifier, List<String>>(() {
  return OptionsListNotifier();
});

class OptionsListNotifier extends AutoDisposeNotifier<List<String>> {
  @override
  List<String> build() {
    return [];
  }

  void overwriteList(Iterable<String> element) {
    state = [...element].toList();
  }
}

final selectedOptionProvider = StateProvider<int>((ref) {
  return 0;
});
