import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Blocking progress dialog for short on-device work (transcription, ebook
/// matching). Spinner and label hug together centered in the dialog; the
/// caller pops it when the work completes.
void showProgressDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      content: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
              width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
          const SizedBox(width: 16),
          Flexible(child: Text(message)),
        ],
      ),
    ),
  );
}

/// Same dialog, but the label follows [message], so long-running work can
/// change what it says while the spinner keeps turning.
void showProgressDialogListenable(
    BuildContext context, ValueListenable<String> message) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      content: ValueListenableBuilder<String>(
        valueListenable: message,
        builder: (_, text, __) => Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
                width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
            const SizedBox(width: 16),
            Flexible(child: Text(text)),
          ],
        ),
      ),
    ),
  );
}
