import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/models/bitrates.dart';

class SetDownloadBitrateDialog extends HookConsumerWidget {
  const SetDownloadBitrateDialog({
    super.key,
    required int downloadBitrate,
  }) : _downloadBitrate = downloadBitrate;

  final int _downloadBitrate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadBitrate = useState(_downloadBitrate);

    return AlertDialog(
      title: Text("Set local download bitrate"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Set the maximum download bitrate for local downloads."),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            width: 350,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: BitRates().map.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Radio<int>(
                      value: BitRates().map.keys.toList()[index],
                      groupValue: downloadBitrate.value,
                      onChanged: (value) {
                        downloadBitrate.value = value!;
                      }),
                  title: Text(BitRates().map.values.toList()[index]),
                  onTap: () {
                    downloadBitrate.value = BitRates().map.keys.toList()[index];
                  },
                );
              },
            ),
          ),
          Text("1h of playback equals approx. " +
              (downloadBitrate.value * 360 / 1000000000).toStringAsFixed(2) +
              "GB")
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, downloadBitrate.value);
          },
          child: Text("Save"),
        ),
      ],
    );
  }
}
