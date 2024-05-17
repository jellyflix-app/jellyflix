import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:filter_list/filter_list.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/jellyfin_image.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/models/skeleton_item.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:tentacle/tentacle.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LibraryScreen extends HookConsumerWidget {
  final String? genreFilterParam;
  final String? filterTypeParam;
  final String? sortTypeParam;
  final String? sortOrderParam;
  final String? pageNumberParam;
  const LibraryScreen(
      {super.key,
      this.genreFilterParam,
      this.filterTypeParam,
      this.sortTypeParam,
      this.sortOrderParam,
      this.pageNumberParam});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genreFilter = useState<List<BaseItemDto>?>(genreFilterParam == ""
        ? null
        : genreFilterParam?.split(",").map((e) {
            return $BaseItemDto(
              (p0) {
                p0.id = e;
              },
            );
          }).toList());
    final order = useState<String>(
        sortOrderParam ?? AppLocalizations.of(context)!.ascending);
    final filterType = useState<List<ItemFilter>>(
        filterTypeParam == null || filterTypeParam == ""
            ? []
            : filterTypeParam!.split(",").map((e) {
                return ItemFilter.values.firstWhere((element) =>
                    element.toString().split(".").last.toLowerCase() ==
                    e.toLowerCase());
              }).toList());
    final sortType = useState<ItemSortBy>(sortTypeParam == null
        ? ItemSortBy.sortName
        : ItemSortBy.values
            .where((element) =>
                element.toString().split(".").last.toLowerCase() ==
                sortTypeParam?.toLowerCase())
            .first);
    final sortOrder = useState<SortOrder>(sortOrderParam == null
        ? SortOrder.ascending
        : SortOrder.values.firstWhere((element) =>
            element.toString().split(".").last.toLowerCase() ==
            sortOrderParam!.toLowerCase()));
    int page = int.parse(pageNumberParam ?? "0");
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.library),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final listData = await ref.read(apiProvider).getGenres(
                            includeItemTypes: [
                              BaseItemKind.movie,
                              BaseItemKind.series,
                              BaseItemKind.boxSet
                            ]);
                        if (!context.mounted) return;
                        genreFilter.value = await openGenreDialog(
                          context,
                          ref,
                          selectedItemList: genreFilter.value ?? [],
                          listData: listData,
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
                                listData: ItemFilter.values.toList()) ??
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
                      if (sortOrder.value == SortOrder.ascending) {
                        sortOrder.value = SortOrder.descending;
                        order.value = AppLocalizations.of(context)!.descending;
                      } else {
                        sortOrder.value = SortOrder.ascending;
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
                        if (sortType.value == ItemSortBy.sortName) {
                          sortType.value = ItemSortBy.premiereDate;
                        } else if (sortType.value == ItemSortBy.premiereDate) {
                          sortType.value = ItemSortBy.random;
                        } else if (sortType.value == ItemSortBy.random) {
                          sortType.value = ItemSortBy.sortName;
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
              child: FutureBuilder(
                future: ref.read(apiProvider).getFilterItems(
                    genreIds: genreFilter.value,
                    startIndex: page * 100,
                    limit: 100,
                    sortOrder: [sortOrder.value],
                    sortBy: [sortType.value],
                    filters: filterType.value,
                    includeItemTypes: [
                      BaseItemKind.movie,
                      BaseItemKind.series,
                      BaseItemKind.boxSet
                    ]),
                builder: (context, AsyncSnapshot<List<BaseItemDto>> snapshot) {
                  List<BaseItemDto> itemsList =
                      List.filled(20, SkeletonItem.baseItemDto);
                  if (snapshot.hasData) {
                    itemsList = snapshot.data!;

                    if (itemsList.isEmpty) {
                      return Center(
                        child: Text(AppLocalizations.of(context)!.noItemsFound),
                      );
                    }
                  }
                  return Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 10.0, right: 10.0, top: 10),
                        child: Skeletonizer(
                          effect: ShimmerEffect(
                            baseColor: Colors.grey.withOpacity(0.5),
                            highlightColor: Colors.white.withOpacity(0.5),
                          ),
                          enabled: !snapshot.hasData,
                          child: GridView.builder(
                            padding: const EdgeInsets.only(bottom: 50.0),
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
                                            child: JellyfinImage(
                                              id: itemsList[index].id!,
                                              type: ImageType.primary,
                                              blurHash: itemsList[index]
                                                  .imageBlurHashes
                                                  ?.primary
                                                  ?.values
                                                  .first,
                                              cacheHeight: 300,
                                            ),
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
                                                      "id":
                                                          itemsList[index].id!,
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
                                      itemsList[index]
                                          .productionYear
                                          .toString(),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: ClipRRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Theme.of(context)
                                        .scaffoldBackgroundColor
                                        .withOpacity(0.2),
                                    Theme.of(context).scaffoldBackgroundColor,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (page > 0)
                                    IconButton(
                                      onPressed: () {
                                        context.push(Uri(
                                            path: ScreenPaths.library,
                                            queryParameters: {
                                              "genreFilter": genreFilter.value
                                                  ?.map((e) => e.id)
                                                  .join(","),
                                              "filterType": filterType.value
                                                  .map((e) => e
                                                      .toString()
                                                      .split(".")
                                                      .last)
                                                  .join(","),
                                              "sortType": sortType.value
                                                  .toString()
                                                  .split(".")
                                                  .last,
                                              "sortOrder": sortOrder.value
                                                  .toString()
                                                  .split(".")
                                                  .last,
                                              "pageNumber":
                                                  (page - 1).toString(),
                                            }).toString());
                                      },
                                      icon: const Icon(Icons.arrow_back_ios),
                                    ),
                                  const SizedBox(
                                    width: 20,
                                  ),
                                  if (itemsList.length == 100)
                                    IconButton(
                                      onPressed: () {
                                        context.push(Uri(
                                            path: ScreenPaths.library,
                                            queryParameters: {
                                              "genreFilter": genreFilter.value
                                                  ?.map((e) => e.id)
                                                  .join(","),
                                              "filterType": filterType.value
                                                  .map((e) => e
                                                      .toString()
                                                      .split(".")
                                                      .last)
                                                  .join(","),
                                              "sortType": sortType.value
                                                  .toString()
                                                  .split(".")
                                                  .last,
                                              "sortOrder": sortOrder.value
                                                  .toString()
                                                  .split(".")
                                                  .last,
                                              "pageNumber":
                                                  (page + 1).toString(),
                                            }).toString());
                                      },
                                      icon: const Icon(Icons.arrow_forward_ios),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
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
      await showDialog(
        context: context,
        builder: (context) {
          return FilterListWidget<BaseItemDto>(
            listData: listData,
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
        },
      );
      return resultList;
    }
    return null;
  }

  Future<List<ItemFilter>?> openFilterDialog(
      BuildContext context, WidgetRef ref,
      {required List<ItemFilter> selectedItemList,
      required List<ItemFilter> listData}) async {
    List<ItemFilter>? resultList;
    if (context.mounted) {
      await showDialog(
          context: context,
          builder: (context) {
            return FilterListWidget<ItemFilter>(
              listData: listData,
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
                        return Theme.of(context)
                            .buttonTheme
                            .colorScheme!
                            .primary;
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
                      color:
                          Theme.of(context).buttonTheme.colorScheme!.onSurface,
                    ),
                    primaryButtonBackgroundColor:
                        Theme.of(context).buttonTheme.colorScheme!.primary,
                  ),
                ),
                wrapAlignment: WrapAlignment.center,
              ),
            );
          });
      return resultList;
    }
    return null;
  }

  String localizeSortType(BuildContext context, ItemSortBy sortType) {
    switch (sortType) {
      case ItemSortBy.sortName:
        return AppLocalizations.of(context)!.name;
      case ItemSortBy.premiereDate:
        return AppLocalizations.of(context)!.premiereDate;
      case ItemSortBy.random:
        return AppLocalizations.of(context)!.random;
      default:
        return sortType.toString().split(".").last;
    }
  }
}
