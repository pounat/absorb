/// Flutter Chrome Cast Plugin
///
/// A comprehensive library for integrating Google Cast functionality into Flutter apps.
///
/// ## Main Import
/// ```dart
/// import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
/// ```
///
/// ## Selective Imports
/// For better performance and cleaner code, you can import only what you need:
///
/// ```dart
/// // Core casting functionality
/// import 'package:flutter_chrome_cast/cast_context.dart';
/// import 'package:flutter_chrome_cast/discovery.dart';
/// import 'package:flutter_chrome_cast/session.dart';
/// import 'package:flutter_chrome_cast/media.dart';
///
/// // UI Widgets
/// import 'package:flutter_chrome_cast/widgets.dart';
///
/// // Models and Entities
/// import 'package:flutter_chrome_cast/models.dart';
/// import 'package:flutter_chrome_cast/entities.dart';
///
/// // Enums and Constants
/// import 'package:flutter_chrome_cast/enums.dart';
/// ```
library flutter_chrome_cast;

// Core functionality
export 'cast_context.dart';
export 'discovery.dart';
export 'session.dart';
export 'media.dart';

// UI Components
export 'widgets.dart';

// Data structures
export 'models.dart';
export 'entities.dart';
export 'enums.dart';

// Utilities
export 'utils.dart';

// Common types
export 'common.dart';

export 'themes.dart';
