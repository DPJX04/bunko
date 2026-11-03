import 'package:flutter/widgets.dart';

import '../utils/error_messages.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

/// The app's own words, in English or Chinese as picked in Settings. The
/// sentences live in app_en.arb and app_zh.arb next to this file.
extension AppWords on BuildContext {
  /// The words for this screen's language. English where no localizations
  /// are set up, as in a widget test that builds a bare app.
  AppLocalizations get l10n {
    return AppLocalizations.of(this) ??
        lookupAppLocalizations(const Locale('en'));
  }
}

/// Repositories describe a failure with one of the English sentences in
/// error_messages.dart; this gives that sentence in [l10n]'s language. A
/// sentence it does not know stays as it is.
String localizedError(AppLocalizations l10n, String message) {
  return switch (message) {
    pageDidNotLoad => l10n.errorPageDidNotLoad,
    noInternet => l10n.errorNoInternet,
    tooSlow => l10n.errorTooSlow,
    blocked => l10n.errorBlocked,
    tooManyRequests => l10n.errorTooManyRequests,
    notFound => l10n.errorNotFound,
    pageChanged => l10n.errorPageChanged,
    couldNotSave => l10n.errorCouldNotSave,
    fileMissing => l10n.errorFileMissing,
    noReader => l10n.errorNoReader,
    cancelled => l10n.errorCancelled,
    somethingWentWrong => l10n.errorSomethingWentWrong,
    _ => message,
  };
}

/// A day and month in the phone's own time zone, such as '3 NOV' or
/// '11月3日'.
String dayMonthOf(AppLocalizations l10n, DateTime when) {
  final local = when.toLocal();
  return l10n.dayMonth('${local.day}', '${local.month}');
}
