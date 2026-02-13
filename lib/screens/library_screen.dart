import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/jfx_filter_list_dialog.dart';
import 'package:jellyflix/components/jfx_layout.dart';
import 'package:jellyflix/components/jfx_tile.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/models/skeleton_item.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:jellyflix/components/filter_button.dart';
import 'package:tentacle/tentacle.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:jellyflix/l10n/generated/app_localizations.dart';

class LibraryScreen extends HookConsumerWidget {
  final String? genreFilterParam;
  final String? filterTypeParam;
  final String? sortTypeParam;
  final String? sortOrderParam;
  final String? pageNumberParam;
  final String? libraryParam;
  const LibraryScreen(
      {super.key,
      this.genreFilterParam,
      this.filterTypeParam,
      this.sortTypeParam,
      this.sortOrderParam,
      this.pageNumberParam,
      this.libraryParam});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genreFilter = useState<List<BaseItemDto>?>(genreFilterParam == ""
        ? null
        : genreFilterParam?.split(",").map((e) {
            return BaseItemDto(
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
    final allLibraries = useState<List<BaseItemDto>?>(null);
    final selectedLibrary = useState<BaseItemDto?>(null);
    int page = int.parse(pageNumberParam ?? "0");

    final layout = JfxLayout.scalingLayout(context);

    useEffect(() {
      ref.read(apiProvider).getMediaFolders().then((value) {
        if (value.isNotEmpty) {
          allLibraries.value = value;
          if (libraryParam != null) {
            var libraryIds = libraryParam!.split(",").map((e) {
              return e;
            }).toList();
            selectedLibrary.value =
                value.firstWhere((element) => libraryIds.contains(element.id));
          }
        }
      });
      return null;
    }, []);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Text(AppLocalizations.of(context)!.library),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(42),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10.0, left: 15),
            child: Align(
              alignment: Alignment.topLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!((genreFilter.value == null ||
                            genreFilter.value!.isEmpty) &&
                        filterType.value.isEmpty &&
                        sortOrder.value == SortOrder.ascending &&
                        sortType.value == ItemSortBy.sortName &&
                        selectedLibrary.value == null))
                      TextButton(
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.resolveWith(
                                (states) =>
                                    Theme.of(context).secondaryHeaderColor),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.filter_list),
                              Icon(Icons.close_outlined),
                            ],
                          ),
                          onPressed: () {
                            genreFilter.value = null;
                            filterType.value = [];
                            sortType.value = ItemSortBy.sortName;
                            sortOrder.value = SortOrder.ascending;
                            order.value =
                                AppLocalizations.of(context)!.ascending;
                            selectedLibrary.value = null;
                          }),
                    if (!((genreFilter.value == null ||
                            genreFilter.value!.isEmpty) &&
                        filterType.value.isEmpty &&
                        sortOrder.value == SortOrder.ascending &&
                        sortType.value == ItemSortBy.sortName &&
                        selectedLibrary.value == null))
                      const SizedBox(
                        width: 10,
                      ),
                    FilterButton(
                      text:
                          "${AppLocalizations.of(context)!.library}: ${selectedLibrary.value == null ? AppLocalizations.of(context)!.all : selectedLibrary.value!.name}",
                      length: 1,
                      onPressed: () async {
                        await JfxFilterListDialog.show<BaseItemDto>(
                          context,
                          enableOnlySingleSelection: true,
                          listData: allLibraries.value!,
                          selectedListData: selectedLibrary.value == null
                              ? List<BaseItemDto>.empty()
                              : [selectedLibrary.value!],
                          onApplyButtonClick: (list) {
                            if (list != null && list.isNotEmpty) {
                              selectedLibrary.value = list.first;
                            } else {
                              selectedLibrary.value = null;
                            }
                            context.pop();
                          },
                        );
                      },
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    FilterButton(
                      text:
                          "${AppLocalizations.of(context)!.genre}: ${genreFilter.value == null || genreFilter.value!.map((e) => e.name).isEmpty ? AppLocalizations.of(context)!.all : genreFilter.value!.length <= 1 ? genreFilter.value!.map((e) => e.name).join() : ""}",
                      length: genreFilter.value?.length ?? 0,
                      onPressed: () async {
                        final listData = await ref.read(apiProvider).getGenres(
                            includeItemTypes: [
                              BaseItemKind.movie,
                              BaseItemKind.series,
                              BaseItemKind.boxSet
                            ]);
                        if (!context.mounted) return;
                        await JfxFilterListDialog.show<BaseItemDto>(context,
                            listData: listData,
                            selectedListData: genreFilter.value ?? [],
                            onApplyButtonClick: (list) {
                          genreFilter.value = list;
                          context.pop(list);
                        });
                      },
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    FilterButton(
                      text:
                          "${AppLocalizations.of(context)!.filter}: ${filterType.value.map((e) => e.toString().split(".").last).isEmpty ? AppLocalizations.of(context)!.none : filterType.value.map((e) => e.toString().split(".")).length <= 1 ? filterType.value.map((e) => e.toString().split(".").last).join() : ""}",
                      length: filterType.value
                          .map((e) => e.toString().split("."))
                          .length,
                      onPressed: () async {
                        await JfxFilterListDialog.show<ItemFilter>(context,
                            selectedListData: filterType.value,
                            listData: ItemFilter.values.where((e) {
                              return e != ItemFilter.isFolder &&
                                  e != ItemFilter.isNotFolder;
                            }).toList(), onApplyButtonClick: (list) {
                          filterType.value = list ?? [];
                          context.pop();
                        });
                      },
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    FilterButton(
                      text:
                          "${AppLocalizations.of(context)!.sort}: ${localizeSortType(context, sortType.value)}",
                      length: 1,
                      onPressed: () {
                        if (sortType.value == ItemSortBy.sortName) {
                          sortType.value = ItemSortBy.premiereDate;
                        } else if (sortType.value == ItemSortBy.premiereDate) {
                          sortType.value = ItemSortBy.random;
                        } else if (sortType.value == ItemSortBy.random) {
                          sortType.value = ItemSortBy.sortName;
                        }
                      },
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    FilterButton(
                      text: order.value,
                      length: 1,
                      onPressed: () {
                        if (sortOrder.value == SortOrder.ascending) {
                          sortOrder.value = SortOrder.descending;
                          order.value =
                              AppLocalizations.of(context)!.descending;
                        } else {
                          sortOrder.value = SortOrder.ascending;
                          order.value = AppLocalizations.of(context)!.ascending;
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.only(top: 0.0),
              child: FutureBuilder(
                future: ref.read(apiProvider).getFilterItems(
                    parentId: selectedLibrary.value?.id,
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
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(AppLocalizations.of(context)!.errorMessageUnknown),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  List<BaseItemDto> itemsList =
                      List.filled(20, SkeletonItem.baseItemDto);
                  if (snapshot.hasData) {
                    // Remove duplicates by ID
                    final seenIds = <String>{};
                    itemsList = snapshot.data!.where((item) {
                      if (item.id == null) return true;
                      if (seenIds.contains(item.id)) return false;
                      seenIds.add(item.id!);
                      return true;
                    }).toList();

                    if (itemsList.isEmpty) {
                      return Center(
                        child: Text(AppLocalizations.of(context)!.noItemsFound),
                      );
                    }
                  }
                  return Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                        child: Skeletonizer(
                          effect: ShimmerEffect(
                            baseColor: Colors.grey.withValues(alpha: 0.5),
                            highlightColor: Colors.white.withValues(alpha: 0.5),
                          ),
                          enabled: !snapshot.hasData,
                          child: GridView.builder(
                            padding:
                                const EdgeInsets.only(bottom: 70.0, top: 110.0),
                            gridDelegate:
                                SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent:
                                        layout.tileWidth + (layout.tilePadding),
                                    mainAxisExtent: layout.tileHeight +
                                        (layout.text.headlineMedium!.fontSize! *
                                            2),
                                    crossAxisSpacing: layout.tilePadding,
                                    mainAxisSpacing: layout.tilePadding),
                            itemCount: itemsList.length,
                            itemBuilder: (context, index) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  JfxTile(
                                      id: itemsList[index].id!,
                                      onTap: () {
                                        context.pushNamed(
                                            ScreenPaths.library +
                                                ScreenPaths.detail,
                                            queryParameters: {
                                              "id": itemsList[index].id!,
                                            });
                                      },
                                      blurHash: itemsList[index]
                                          .imageBlurHashes
                                          ?.primary
                                          ?.values
                                          .first),
                                  const SizedBox(height: 5.0),
                                  Flexible(
                                    child: Text(
                                      itemsList[index].name!,
                                      style: layout.text.bodyMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      itemsList[index]
                                          .productionYear
                                          .toString(),
                                      style: layout.text.bodyMedium,
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
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(15.0),
                            topRight: Radius.circular(15.0),
                          ),
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
                                        .withValues(alpha: 0.2),
                                    Theme.of(context).scaffoldBackgroundColor,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.5),
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
                                        final uri = Uri(
                                          path: ScreenPaths.library,
                                          queryParameters: {
                                            if (genreFilter.value != null &&
                                                genreFilter.value!.isNotEmpty)
                                              "genreFilter": genreFilter.value!
                                                  .map((e) => e.id)
                                                  .join(","),
                                            if (filterType.value.isNotEmpty)
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
                                            if (selectedLibrary.value?.id != null)
                                              "library": selectedLibrary.value!.id!,
                                            "pageNumber": (page - 1).toString(),
                                          },
                                        );
                                        context.push(uri.toString());
                                      },
                                      icon: const Icon(Icons.arrow_back_ios),
                                    ),
                                  const SizedBox(
                                    width: 20,
                                  ),
                                  if (itemsList.length == 100)
                                    IconButton(
                                      onPressed: () {
                                        final uri = Uri(
                                          path: ScreenPaths.library,
                                          queryParameters: {
                                            if (genreFilter.value != null &&
                                                genreFilter.value!.isNotEmpty)
                                              "genreFilter": genreFilter.value!
                                                  .map((e) => e.id)
                                                  .join(","),
                                            if (filterType.value.isNotEmpty)
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
                                            if (selectedLibrary.value?.id != null)
                                              "library": selectedLibrary.value!.id!,
                                            "pageNumber": (page + 1).toString(),
                                          },
                                        );
                                        context.push(uri.toString());
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
          ),
        ],
      ),
    );
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
