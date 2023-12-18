import 'package:flutter/material.dart';
import 'package:filter_list/filter_list.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/models/sort_type.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:jellyflix/screens/detail_screen.dart';
import 'package:jellyflix/screens/filter_type.dart';
import 'package:openapi/openapi.dart';

class LibraryScreen extends HookConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genreFilter = useState<List<BaseItemDto>?>([]);
    final order = useState<String>("Ascending");
    final filterType = useState<List<FilterType>>([]);
    final sortType = useState<SortType>(SortType.name);
    return Scaffold(
      appBar: AppBar(
          leading: BackButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: const Text("Library"),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                ),
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
                      "Genre: ${genreFilter.value!.map(
                            (e) => e.name,
                          ).isEmpty ? "All" : genreFilter.value!.map(
                            (e) => e.name,
                          ).join(", ")}",
                      maxLines: 1,
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
                        "Filter: ${filterType.value.map((e) => e.toString().split(".").last).isEmpty ? "None" : filterType.value.map((e) => e.toString().split(".").last).join(", ")}"),
                  ),
                ),
                Expanded(
                    child: TextButton(
                  onPressed: () {
                    if (order.value == "Ascending") {
                      order.value = "Descending";
                    } else {
                      order.value = "Ascending";
                    }
                  },
                  child: Text("Order: ${order.value}"),
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
                    child: Text("Sort: ${sortType.value.name}"),
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
              ],
            ),
          )),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: FutureBuilder(
          future:
              ref.read(apiProvider).getFilterItems(genreIds: genreFilter.value),
          builder: (context, AsyncSnapshot<List<BaseItemDto>> snapshot) {
            if (snapshot.hasData) {
              List<BaseItemDto> itemsList = snapshot.data!;

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
                  return a.premiereDate!.compareTo(b.premiereDate!);
                } else {
                  return 0;
                }
              });
              if (sortType.value == SortType.random) {
                itemsList.shuffle();
              }
              if (order.value == "Descending") {
                itemsList = itemsList.reversed.toList();
              }

              if (itemsList.isEmpty) {
                return const Center(
                  child: Text("No items found"),
                );
              }
              return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 150,
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
                        SizedBox(
                          width: 150,
                          height: 200,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.0),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.5),
                                        spreadRadius: 2,
                                        blurRadius: 5,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                    image: DecorationImage(
                                      fit: BoxFit.cover,
                                      image: ref.read(apiProvider).getImage(
                                          itemsList[index].id!,
                                          ImageType.primary),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => DetailScreen(
                                            itemId: itemsList[index].id!,
                                          ),
                                        ),
                                      );
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
                  });
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
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
}
