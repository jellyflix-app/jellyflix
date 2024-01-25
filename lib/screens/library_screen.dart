import 'package:flutter/material.dart';
import 'package:filter_list/filter_list.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/models/skeleton_item.dart';
import 'package:jellyflix/models/sort_type.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:jellyflix/models/filter_type.dart';
import 'package:openapi/openapi.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LibraryScreen extends HookConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genreFilter = useState<List<BaseItemDto>?>([]);
    final order = useState<String>(AppLocalizations.of(context)!.ascending);
    final filterType = useState<List<FilterType>>([]);
    final sortType = useState<SortType>(SortType.name);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        genreFilter.value = await openGenreDialog(
                          context,
                          ref,
                          selectedItemList: genreFilter.value ?? [],
                          listData: await ref.read(apiProvider).getGenres(),
                        );
                      },
                      child: Text(
                        "${AppLocalizations.of(context)!.genre}: ${genreFilter.value == null ? AppLocalizations.of(context)!.all : genreFilter.value!.map(
                              (e) => e.name,
                            ).isEmpty ? AppLocalizations.of(context)!.all : genreFilter.value!.map(
                              (e) => e.name,
                            ).join(", ")}",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        filterType.value = await openFilterDialog(context, ref,
                                selectedItemList: filterType.value,
                                listData: FilterType.values) ??
                            [];
                      },
                      child: Text(
                        "${AppLocalizations.of(context)!.filter}: ${filterType.value.map((e) => e.toString().split(".").last).isEmpty ? AppLocalizations.of(context)!.none : filterType.value.map((e) => e.toString().split(".").last).join(", ")}",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  Expanded(
                      child: TextButton(
                    onPressed: () {
                      if (order.value ==
                          AppLocalizations.of(context)!.ascending) {
                        order.value = AppLocalizations.of(context)!.descending;
                      } else {
                        order.value = AppLocalizations.of(context)!.ascending;
                      }
                    },
                    child: Text(
                      "${AppLocalizations.of(context)!.order}: ${order.value}",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
                  const SizedBox(
                    width: 20,
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        if (sortType.value == SortType.name) {
                          sortType.value = SortType.premiereDate;
                        } else if (sortType.value == SortType.premiereDate) {
                          sortType.value = SortType.random;
                        } else if (sortType.value == SortType.random) {
                          sortType.value = SortType.name;
                        }
                      },
                      child: Text(
                        "${AppLocalizations.of(context)!.sort}: ${localizeSortType(context, sortType.value)}",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.only(left: 20.0, right: 20.0, top: 10),
                child: FutureBuilder(
                  future: ref
                      .read(apiProvider)
                      .getFilterItems(genreIds: genreFilter.value),
                  builder:
                      (context, AsyncSnapshot<List<BaseItemDto>> snapshot) {
                    List<BaseItemDto> itemsList =
                        List.filled(20, SkeletonItem.baseItemDto);
                    if (snapshot.hasData) {
                      itemsList = snapshot.data!;

                      // only filter if filters are set
                      if (filterType.value.isNotEmpty) {
                        // return only items that matches every filter type
                        itemsList = itemsList.where((element) {
                          return filterType.value.every((filter) {
                            if (filter == FilterType.unplayed) {
                              return !(element.userData!.played ?? false);
                            } else if (filter == FilterType.played) {
                              return element.userData!.played ?? false;
                            } else if (filter == FilterType.favorites) {
                              return element.userData!.isFavorite == true;
                            } else if (filter == FilterType.liked) {
                              return element.userData!.likes == true;
                            } else {
                              return false;
                            }
                          });
                        }).toList();
                      }

                      // first sort by sort type then by order
                      itemsList.sort((a, b) {
                        if (sortType.value == SortType.name) {
                          return a.name!.compareTo(b.name!);
                        } else if (sortType.value == SortType.premiereDate) {
                          return a.premiereDate == null
                              ? 1
                              : b.premiereDate == null
                                  ? -1
                                  : a.premiereDate!.compareTo(b.premiereDate!);
                        } else {
                          return 0;
                        }
                      });
                      if (sortType.value == SortType.random) {
                        itemsList.shuffle();
                      }
                      if (order.value ==
                          AppLocalizations.of(context)!.descending) {
                        itemsList = itemsList.reversed.toList();
                      }

                      if (itemsList.isEmpty) {
                        return Center(
                          child:
                              Text(AppLocalizations.of(context)!.noItemsFound),
                        );
                      }
                    }
                    return Skeletonizer(
                      effect: ShimmerEffect(
                        baseColor: Colors.grey.withOpacity(0.5),
                        highlightColor: Colors.white.withOpacity(0.5),
                      ),
                      enabled: !snapshot.hasData,
                      child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 125,
                                  mainAxisExtent: 250,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10),
                          itemCount: itemsList.length,
                          itemBuilder: (context, index) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AspectRatio(
                                  aspectRatio: 2 / 3,
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.5),
                                                spreadRadius: 2,
                                                blurRadius: 5,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: ref.read(apiProvider).getImage(
                                              id: itemsList[index].id!,
                                              type: ImageType.primary,
                                              blurHash: itemsList[index]
                                                  .imageBlurHashes
                                                  ?.primary
                                                  ?.values
                                                  .first),
                                        ),
                                      ),
                                      Positioned.fill(
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                            onTap: () {
                                              context.push(Uri(
                                                  path: ScreenPaths.detail,
                                                  queryParameters: {
                                                    "id": itemsList[index].id!,
                                                    "selectedIndex": "2",
                                                  }).toString());
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 5.0),
                                Flexible(
                                  child: Text(
                                    itemsList[index].name!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    itemsList[index].productionYear.toString(),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ),
                              ],
                            );
                          }),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<BaseItemDto>?> openGenreDialog(
    BuildContext context,
    WidgetRef ref, {
    required List<BaseItemDto> selectedItemList,
    required List<BaseItemDto> listData,
  }) async {
    List<BaseItemDto>? resultList;
    if (context.mounted) {
      await FilterListDialog.display<BaseItemDto>(
        context,
        listData: listData,
        height: MediaQuery.of(context).size.height * 0.8 > 600
            ? 600
            : MediaQuery.of(context).size.height * 0.8,
        width: MediaQuery.of(context).size.width * 0.8 > 500
            ? 500
            : MediaQuery.of(context).size.width * 0.8,
        selectedListData: selectedItemList,
        choiceChipLabel: (item) => item!.name,
        validateSelectedItem: (list, val) => list!.contains(val),
        onItemSearch: (item, query) {
          return item.name!.toLowerCase().contains(query.toLowerCase());
        },
        onApplyButtonClick: (list) {
          resultList = list;
          Navigator.pop(context, list);
        },
        choiceChipBuilder: (context, item, isSelected) => Padding(
          padding: const EdgeInsets.all(5.0),
          child: ChoiceChip(
              color: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return Theme.of(context).buttonTheme.colorScheme!.primary;
                }
                return Theme.of(context).focusColor;
              }),
              label: Text(
                item!.name,
                style: const TextStyle(color: Colors.white),
              ),
              selected: isSelected ?? false),
        ),
        themeData: FilterListThemeData(
          context,
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          headerTheme: HeaderThemeData(
            backgroundColor: Theme.of(context).dialogBackgroundColor,
            searchFieldBackgroundColor: Theme.of(context).focusColor,
            searchFieldIconColor: Theme.of(context).iconTheme.color,
            closeIconColor: Theme.of(context).iconTheme.color!,
          ),
          controlButtonBarTheme: ControlButtonBarThemeData(
            context,
            backgroundColor: Theme.of(context).focusColor,
            padding: EdgeInsets.zero,
            controlButtonTheme: ControlButtonThemeData(
              textStyle: TextStyle(
                color: Theme.of(context).buttonTheme.colorScheme!.onSurface,
              ),
              primaryButtonBackgroundColor:
                  Theme.of(context).buttonTheme.colorScheme!.primary,
            ),
          ),
          wrapAlignment: WrapAlignment.center,
        ),
      );
      return resultList;
    }
    return null;
  }

  Future<List<FilterType>?> openFilterDialog(
    BuildContext context,
    WidgetRef ref, {
    required List<FilterType> selectedItemList,
    required List<FilterType> listData,
  }) async {
    List<FilterType>? resultList;
    if (context.mounted) {
      await FilterListDialog.display<FilterType>(
        context,
        listData: listData,
        height: MediaQuery.of(context).size.height * 0.8 > 600
            ? 600
            : MediaQuery.of(context).size.height * 0.8,
        width: MediaQuery.of(context).size.width * 0.8 > 500
            ? 500
            : MediaQuery.of(context).size.width * 0.8,
        selectedListData: selectedItemList,
        choiceChipLabel: (item) => item!.name,
        validateSelectedItem: (list, val) => list!.contains(val),
        onItemSearch: (item, query) {
          return item.name.toLowerCase().contains(query.toLowerCase());
        },
        onApplyButtonClick: (list) {
          resultList = list;
          Navigator.pop(context, list);
        },
        choiceChipBuilder: (context, item, isSelected) => Padding(
          padding: const EdgeInsets.all(5.0),
          child: ChoiceChip(
              color: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return Theme.of(context).buttonTheme.colorScheme!.primary;
                }
                return Theme.of(context).focusColor;
              }),
              label: Text(
                item.toString().split(".").last,
                style: const TextStyle(color: Colors.white),
              ),
              selected: isSelected ?? false),
        ),
        themeData: FilterListThemeData(
          context,
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          headerTheme: HeaderThemeData(
            backgroundColor: Theme.of(context).dialogBackgroundColor,
            searchFieldBackgroundColor: Theme.of(context).focusColor,
            searchFieldIconColor: Theme.of(context).iconTheme.color,
            closeIconColor: Theme.of(context).iconTheme.color!,
          ),
          controlButtonBarTheme: ControlButtonBarThemeData(
            context,
            backgroundColor: Theme.of(context).focusColor,
            padding: EdgeInsets.zero,
            controlButtonTheme: ControlButtonThemeData(
              textStyle: TextStyle(
                color: Theme.of(context).buttonTheme.colorScheme!.onSurface,
              ),
              primaryButtonBackgroundColor:
                  Theme.of(context).buttonTheme.colorScheme!.primary,
            ),
          ),
          wrapAlignment: WrapAlignment.center,
        ),
      );
      return resultList;
    }
    return null;
  }

  String localizeSortType(BuildContext context, SortType sortType) {
    switch (sortType) {
      case SortType.name:
        return AppLocalizations.of(context)!.name;
      case SortType.premiereDate:
        return AppLocalizations.of(context)!.premiereDate;
      case SortType.random:
        return AppLocalizations.of(context)!.random;
    }
  }
}
