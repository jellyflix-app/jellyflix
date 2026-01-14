import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/home_screen_section_builder.dart';
import 'package:jellyflix/models/home_screen_config.dart';
import 'package:jellyflix/providers/database_provider.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  HomeScreenConfig _loadConfig(WidgetRef ref) {
    try {
      final configJson =
          ref.read(databaseProvider('settings')).get('homeScreenConfig');
      if (configJson == null) {
        return HomeScreenConfig.getDefault();
      }
      final json = jsonDecode(configJson as String);
      return HomeScreenConfig.fromJson(json);
    } catch (e) {
      print('Error loading home screen config: $e');
      return HomeScreenConfig.getDefault();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = _loadConfig(ref);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: config.sections
              .map((section) =>
                  HomeScreenSectionBuilder.build(section, context, ref))
              .where((widget) => widget != null)
              .map((widget) => widget!)
              .toList(),
        ),
      ),
    );
  }
}
