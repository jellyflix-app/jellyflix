import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jellyflix/l10n/generated/app_localizations.dart';

class LoginMessages {
  static Future<void> showErrorDialog(
    BuildContext context,
    Object e,
  ) {
    return showInfoDialog(
        context,
        Text(
          AppLocalizations.of(context)!.errorConnectingToServer,
        ),
        content: Text(e.toString()));
  }

  static Future<void> showHttpErrorDialog(
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
          : Text(_formatHttpErrorCode(e.response, context)),
    );
  }

  static Future<void> showInfoDialog(
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

  static String _formatHttpErrorCode(Response? response, BuildContext context) {
    var message = '';
    switch (response!.statusCode) {
      case 400:
        message = AppLocalizations.of(context)!.errorMessage400;
      case 401:
        message = AppLocalizations.of(context)!.errorMessage401;
      case 403:
        message = AppLocalizations.of(context)!.errorMessage403;
      default:
        message = AppLocalizations.of(context)!.errorMessageUnknown;
    }

    return '$message\n\n'
            'Status Code: ${response.statusCode ?? 'Unknown'}\n\n'
            'Response: ${response.statusMessage ?? 'Unknown'}\n\n'
        .trim();
  }
}
