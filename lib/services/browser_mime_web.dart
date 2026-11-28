// Browser capability detection; never claim native codec support on web.
// This conditional implementation is intentionally browser-only.
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
String browserCanPlayType(String mime) => html.AudioElement().canPlayType(mime);
