import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/mpv_config_dialog.dart';
import 'package:jellyflix/components/profile_image.dart';
import 'package:jellyflix/components/quick_connect_dialog.dart';
import 'package:jellyflix/components/set_download_bitrate_dialog.dart';
import 'package:jellyflix/components/switch_settings_tile.dart';
import 'package:jellyflix/models/bitrates.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:jellyflix/providers/auth_provider.dart';
import 'package:jellyflix/l10n/generated/app_localizations.dart';
import 'package:jellyflix/providers/database_provider.dart';
import 'package:jellyflix/providers/device_info_provider.dart';
import 'package:jellyflix/providers/download_provider.dart';
import 'package:jellyflix/providers/logger_provider.dart';

class ProfileScreen extends HookConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadBitrate = useState(
        ref.read(databaseProvider("settings")).get("downloadBitrate") ??
            BitRates.defaultBitrate());
    final disableImageCaching = useState(
        ref.read(databaseProvider("settings")).get("disableImageCaching") ??
            false);
    final disableWatchlist = useState(
        ref.read(databaseProvider("settings")).get("disableWatchlist") ??
            false);

    final showPrimaryForEpisodes = useState(
        ref.read(databaseProvider("settings")).get("showPrimaryForEpisodes") ??
            false);

    final loggingEnabled = useState(
        ref.read(databaseProvider("settings")).get("loggingEnabled") ?? false);

    final mpvConfig = useState(
        ref.read(databaseProvider("settings")).get("mpvConfig") ??
            MpvConfigDialog.getDefaultConfig());

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 750),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(100),
                                    child: const ProfileImage(),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ref
                                              .read(authProvider)
                                              .currentProfile
                                              ?.name ??
                                          AppLocalizations.of(context)!
                                              .offlineNotice,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall,
                                    ),
                                    Text(
                                      ref
                                              .read(authProvider)
                                              .currentProfile
                                              ?.serverAdress ??
                                          AppLocalizations.of(context)!.na,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          ListTile(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            leading: const Icon(Icons.group_rounded),
                            title: Text(
                                AppLocalizations.of(context)!.changeProfile),
                            onTap: () {
                              ref
                                  .read(authProvider)
                                  .updateCurrentProfileId(null);
                              context.go(ScreenPaths.login);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            leading: const Icon(Icons.connected_tv_rounded),
                            title: Text(
                                AppLocalizations.of(context)!.quickConnect),
                            onTap: () {
                              showDialog(
                                  context: context,
                                  builder: (context) =>
                                      const QuickConnectDialog());
                            },
                          ),
                          ListTile(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            leading: const Icon(Icons.qr_code_rounded),
                            title:
                                Text(AppLocalizations.of(context)!.scanLibrary),
                            onTap: () async {
                              await ref.read(apiProvider).startLibraryScan();
                              // show snack bar
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(AppLocalizations.of(context)!
                                        .scanStarted),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            leading: const Icon(Icons.video_file_outlined),
                            title: Text(AppLocalizations.of(context)!
                                .setLocalDownloadBitrate),
                            trailing: Text(
                                BitRates().map[downloadBitrate.value] ?? ""),
                            onTap: () async {
                              // show dialog
                              var result = await showDialog(
                                  context: context,
                                  builder: (context) {
                                    return SetDownloadBitrateDialog(
                                        downloadBitrate: downloadBitrate.value);
                                  });
                              if (result != null) {
                                downloadBitrate.value = result;
                                await ref
                                    .read(databaseProvider("settings"))
                                    .put("downloadBitrate",
                                        downloadBitrate.value);
                              }
                            },
                          ),
                          ListTile(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            leading: const Icon(Icons.delete_outline_rounded),
                            title: Text(AppLocalizations.of(context)!
                                .cancelAndRemoveAllDownloads),
                            onTap: () async {
                              await ref.read(cancelAndDeleteDownloadProvider);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                      ),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        leading: const Icon(Icons.video_settings_rounded),
                        title:
                            Text(AppLocalizations.of(context)!.customMpvConfig),
                        onTap: () async {
                          final result = await showDialog<String>(
                            context: context,
                            builder: (context) => MpvConfigDialog(
                              mpvConfig: mpvConfig.value,
                            ),
                          );
                          if (result != null) {
                            mpvConfig.value = result;
                            ref
                                .read(databaseProvider("settings"))
                                .put("mpvConfig", result);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            leading: const Icon(Icons.dashboard_customize_rounded),
                            title: Text(AppLocalizations.of(context)!.homeScreenSettings),
                            onTap: () {
                              context.pushNamed(ScreenPaths.profile + ScreenPaths.homeScreenConfig);
                            },
                          ),
                          SwitchSettingsTile(
                            leading: const Icon(Icons.image_outlined),
                            title: Text(AppLocalizations.of(context)!
                                .disableImageCaching),
                            value: disableImageCaching.value,
                            onChanged: (value) {
                              disableImageCaching.value = value;
                              ref
                                  .read(databaseProvider("settings"))
                                  .put("disableImageCaching", value);

                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text(AppLocalizations.of(context)!
                                        .restartApp),
                                    content: Text(AppLocalizations.of(context)!
                                        .restartAppDescription),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text(
                                            AppLocalizations.of(context)!.ok),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                          SwitchSettingsTile(
                            leading: const Icon(Icons.remove_red_eye_outlined),
                            title: Text(
                                AppLocalizations.of(context)!.disableWatchlist),
                            value: disableWatchlist.value,
                            onChanged: (value) {
                              disableWatchlist.value = value;
                              ref
                                  .read(databaseProvider("settings"))
                                  .put("disableWatchlist", value);

                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text(
                                      AppLocalizations.of(context)!.info,
                                    ),
                                    content: Text(AppLocalizations.of(context)!
                                        .deletePlaylistNotice),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text(
                                            AppLocalizations.of(context)!.ok),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                          SwitchSettingsTile(
                            leading: const Icon(Icons.amp_stories_rounded),
                            title: Text(AppLocalizations.of(context)!
                                .showPrimaryForEpisodes),
                            value: showPrimaryForEpisodes.value,
                            onChanged: (value) {
                              showPrimaryForEpisodes.value = value;
                              ref
                                  .read(databaseProvider("settings"))
                                  .put("showPrimaryForEpisodes", value);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                      ),
                      child: Column(
                        children: [
                          SwitchSettingsTile(
                            leading: const Icon(Icons.file_open_outlined),
                            title: Text(
                                AppLocalizations.of(context)!.enableLogging),
                            value: loggingEnabled.value,
                            onChanged: (value) async {
                              loggingEnabled.value = value;
                              ref
                                  .read(databaseProvider("settings"))
                                  .put("loggingEnabled", value);
                              if (loggingEnabled.value) {
                                ref.read(loggerProvider).alwaysLog();
                              } else {
                                ref.read(loggerProvider).resetLogger();
                                await ref.read(loggerProvider).exportLog();
                                // show snack bar
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          AppLocalizations.of(context)!
                                              .logExported),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          ListTile(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            leading: const Icon(Icons.info_rounded),
                            title: Text(AppLocalizations.of(context)!.about),
                            onTap: () async {
                              ref.read(appVersionProvider).whenData(
                                  (versionNumber) => showLicensePage(
                                      context: context,
                                      applicationVersion: versionNumber));
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                      ),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        leading: Icon(Icons.logout,
                            color: Theme.of(context).colorScheme.error),
                        title: Text(AppLocalizations.of(context)!.logout),
                        onTap: () async {
                          await ref.read(authProvider).logoutAndDeleteProfile();

                          if (context.mounted) {
                            context.go(ScreenPaths.login);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
