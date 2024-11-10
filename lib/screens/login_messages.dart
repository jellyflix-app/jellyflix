import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Future<void> showErrorDialog(
  BuildContext context,
  Object e,
) {
  return showInfoDialog(
    context,
    Text(
      AppLocalizations.of(context)!.errorConnectingToServer,
    ),
    content: Text(e.toString())
  );
}

Future<void> showHttpErrorDialog(
  BuildContext context,
  DioException e,
) {
  return showInfoDialog(
    context,
    Text(
      AppLocalizations.of(context)!.errorConnectingToServer,
    ),
    content: e.response?.statusCode == null
        ? Text(e.toString())
        : Text(_formatHttpErrorCode(e.response)),
  );
}

Future<void> showInfoDialog(
  BuildContext context,
  Widget title, {
  Widget? content,
}) async {
  await showDialog(
    context: context,
    builder: (context) => CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.enter): () {
          Navigator.pop(context);
        }
      },
      child: FocusScope(
        autofocus: true,
        child: AlertDialog(
          title: title,
          content: content,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Ok'),
            )
          ],
        ),
      ),
    ),
  );
}

String _formatHttpErrorCode(Response? resp) {
  // todo PLACEHOLDER MESSAGES NOT FINAL
  var message = '';
  switch (resp!.statusCode) {
    case 400:
      message =
          'The server could not understand the request, if you are using proxies check the configuration, if the issue still persists let us know';
    case 401:
      message = 'Your username or password may be incorrect';
    case 403:
      message =
          'The server is blocking request from this device, this probably means the device has been banned, please contact your admin to resolve this issue';
    default:
      message = '';
  }

  return '$message\n\n'
          'Http Code: ${resp.statusCode ?? 'Unknown'}\n\n'
          'Http Response: ${resp.statusMessage ?? 'Unknown'}\n\n'
      .trim();
}
