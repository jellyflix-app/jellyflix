import 'package:filter_list/filter_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tentacle/tentacle.dart';

class JfxFilterListDialog<T extends Object> {
  static show<T extends Object>(
    context, {
    required listData,
    required selectedListData,
    required onApplyButtonClick,
    enableOnlySingleSelection,
  }) async {
    for (var item in listData) {
      if (!(item is ItemFilter || item is BaseItemDto)) {
        throw ArgumentError(
            'All items must be of type FilterType or BaseItemDto');
      }
    }

    for (var item in selectedListData) {
      if (!(item is ItemFilter || item is BaseItemDto)) {
        throw ArgumentError(
            'All items must be of type FilterType or BaseItemDto');
      }
    }
    return showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
          clipBehavior: Clip.antiAlias,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 450,
              maxHeight: 400,
            ),
            child: FilterListWidget<T>(
              hideCloseIcon: false,
              enableOnlySingleSelection: enableOnlySingleSelection ?? false,
              listData: listData,
              selectedListData: selectedListData,
              choiceChipLabel: (item) {
                if (item is ItemFilter) {
                  return item.name;
                } else if (item is BaseItemDto) {
                  return item.name;
                } else {
                  throw ArgumentError(
                      'Item must be of type FilterType or BaseItemDto');
                }
              },
              validateSelectedItem: (list, val) => list!.contains(val),
              onItemSearch: (item, query) {
                if (item is ItemFilter) {
                  return item.name.toLowerCase().contains(query.toLowerCase());
                } else if (item is BaseItemDto) {
                  return item.name!.toLowerCase().contains(query.toLowerCase());
                } else {
                  throw ArgumentError(
                      'Item must be of type FilterType or BaseItemDto');
                }
              },
              onApplyButtonClick: onApplyButtonClick,
              headerCloseIcon: const Padding(
                padding: EdgeInsets.all(5.0),
                child: Icon(Icons.close_rounded),
              ),
              selectedItemsText: AppLocalizations.of(context)!.selectedItems,
              allButtonText: AppLocalizations.of(context)!.all,
              applyButtonText: AppLocalizations.of(context)!.apply,
              resetButtonText: AppLocalizations.of(context)!.reset,
              themeData: FilterListThemeData(
                context,
                backgroundColor: Theme.of(context).dialogBackgroundColor,
                headerTheme: HeaderThemeData(
                  backgroundColor: Theme.of(context).dialogBackgroundColor,
                  searchFieldBackgroundColor: Theme.of(context).focusColor,
                  searchFieldIconColor: Theme.of(context).iconTheme.color,
                  closeIconColor: Theme.of(context).iconTheme.color!,
                  searchFieldHintText: AppLocalizations.of(context)!.search,
                  searchFieldInputBorder: // empty border fixes layout issue
                      const OutlineInputBorder(borderSide: BorderSide.none),
                ),
                controlButtonBarTheme: ControlButtonBarThemeData(
                  context,
                  backgroundColor:
                      Theme.of(context).colorScheme.surface.withOpacity(0.8),
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  controlButtonTheme: ControlButtonThemeData(
                    primaryButtonTextStyle: TextStyle(
                      color:
                          Theme.of(context).buttonTheme.colorScheme!.onPrimary,
                    ),
                    textStyle: TextStyle(
                      color:
                          Theme.of(context).buttonTheme.colorScheme!.onSurface,
                    ),
                    primaryButtonBackgroundColor:
                        Theme.of(context).buttonTheme.colorScheme!.primary,
                  ),
                ),
                wrapAlignment: WrapAlignment.center,
                choiceChipTheme: ChoiceChipThemeData(
                  backgroundColor: Theme.of(context).focusColor,
                  selectedTextStyle: const TextStyle(color: Colors.white),
                  textStyle: const TextStyle(color: Colors.white),
                  margin: const EdgeInsets.symmetric(
                      horizontal: 5.0, vertical: 5.0),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
