import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_carplay/constants/private_constants.dart';
import 'package:flutter_carplay/controllers/carplay_controller.dart';
import 'package:flutter_carplay/flutter_carplay.dart';

import 'models/template.dart';

/// An object in order to integrate Apple CarPlay in navigation and
/// manage all user interface elements appearing on your screens displayed on
/// the CarPlay screen.
///
/// Using CarPlay, you can display content from your app on a customized user interface
/// that is generated and hosted by the system itself. Control over UI elements, such as
/// touch target size, font size and color, highlights, and so on.
///
/// **Useful Links:**
/// - [What is CarPlay?](https://developer.apple.com/carplay/)
/// - [Request CarPlay Framework](https://developer.apple.com/contact/carplay/)
/// - [Learn more about MFi Program](https://mfi.apple.com)
class FlutterCarplay {
  /// A main Flutter CarPlay Controller to manage the system.
  static final FlutterCarPlayController _carPlayController =
      FlutterCarPlayController();

  /// CarPlay main bridge as a listener from CarPlay and native side.
  late final StreamSubscription<dynamic>? _eventBroadcast;

  /// Current CarPlay and mobile app connection status.
  static String _connectionStatus = EnumUtils.stringFromEnum(
    ConnectionStatusTypes.unknown.toString(),
  );

  /// A listener function, which will be triggered when CarPlay connection changes
  /// and will be transmitted to the main code, allowing the user to access
  /// the current connection status.
  Function(ConnectionStatusTypes status)? _onCarplayConnectionChange;

  /// Creates an [FlutterCarplay] and starts the connection.
  FlutterCarplay() {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;

    _eventBroadcast = _carPlayController.eventChannel
        .receiveBroadcastStream()
        .listen((event) {
      final FCPChannelTypes receivedChannelType =
          EnumUtils.enumFromString(FCPChannelTypes.values, event['type']);
      switch (receivedChannelType) {
        case FCPChannelTypes.onCarplayConnectionChange:
          final ConnectionStatusTypes connectionStatus =
              EnumUtils.enumFromString(
            ConnectionStatusTypes.values,
            event['data']['status'],
          );
          _connectionStatus = EnumUtils.stringFromEnum(
            connectionStatus.toString(),
          );
          if (_onCarplayConnectionChange != null) {
            _onCarplayConnectionChange!(connectionStatus);
          }
          break;
        case FCPChannelTypes.onFCPListItemSelected:
          _carPlayController.processFCPListItemSelectedChannel(
            event['data']['elementId'],
          );
          break;
        case FCPChannelTypes.onFCPAlertActionPressed:
          _carPlayController.processFCPAlertActionPressed(
            event['data']['elementId'],
          );
          break;
        case FCPChannelTypes.onPresentStateChanged:
          _carPlayController.processFCPAlertTemplateCompleted(
            event['data']['completed'],
          );
          break;
        case FCPChannelTypes.onGridButtonPressed:
          _carPlayController.processFCPGridButtonPressed(
            event['data']['elementId'],
          );
          break;
        case FCPChannelTypes.onBarButtonPressed:
          _carPlayController.processFCPBarButtonPressed(
            event['data']['elementId'],
          );
          break;
        case FCPChannelTypes.onTextButtonPressed:
          _carPlayController.processFCPTextButtonPressed(
            event['data']['elementId'],
          );
          break;
        case FCPChannelTypes.onScreenBackButtonPressed:
          FlutterCarPlayController.templateHistory.removeWhere(
            (CPTemplate item) => item.uniqueId == event['data']['elementId'],
          );
          break;
        default:
          break;
      }
    });
  }

  /// A function that will disconnect all event listeners from CarPlay. The action
  /// will be irrevocable, and a new [FlutterCarplay] controller must be created after this,
  /// otherwise CarPlay will be unusable.
  ///
  /// [!] It is not recommended to use this function if you do not know what you are doing.
  void closeConnection() {
    _eventBroadcast!.cancel();
  }

  /// A function that will resume the paused all event listeners from CarPlay.
  void resumeConnection() {
    _eventBroadcast!.resume();
  }

  /// A function that will pause the all active event listeners from CarPlay.
  void pauseConnection() {
    _eventBroadcast!.pause();
  }

  /// Callback function will be fired when CarPlay connection status is changed.
  /// For example, when CarPlay is connected to the device, in the background state,
  /// or completely disconnected.
  ///
  /// See also: [ConnectionStatusTypes]
  void addListenerOnConnectionChange(
    Function(ConnectionStatusTypes status) onCarplayConnectionChange,
  ) {
    _onCarplayConnectionChange = onCarplayConnectionChange;
  }

  /// Removes the callback function that has been set before in order to listen
  /// on CarPlay connection status changed.
  void removeListenerOnConnectionChange() {
    _onCarplayConnectionChange = null;
  }

  /// Current CarPlay connection status. It will return one of [ConnectionStatusTypes] as String.
  static String get connectionStatus {
    return _connectionStatus;
  }

  /// Whether CarPlay currently has an active interface controller.
  static Future<bool> get isConnected async {
    return await _carPlayController.flutterToNativeModule(
          FCPChannelTypes.isConnected,
          null,
        ) ??
        false;
  }

  /// Sets the root template of the navigation hierarchy. If a navigation
  /// hierarchy already exists, CarPlay replaces the entire hierarchy.
  ///
  /// - rootTemplate is a template to use as the root of a new navigation hierarchy. If one exists,
  /// it will replace the current rootTemplate. **Must be one of the type:**
  /// [CPTabBarTemplate], [CPGridTemplate], [CPListTemplate] If not, it will throw an [TypeError]
  ///
  /// - If animated is true, CarPlay animates the presentation of the template, but will be ignored
  /// this flag when there isn’t an existing navigation hierarchy to replace.
  ///
  /// [!] CarPlay cannot have more than 5 templates on one screen.
  static Future<void> setRootTemplate({
    required CPTemplate rootTemplate,
    bool animated = true,
  }) async {
    if (rootTemplate is CPTabBarTemplate ||
        rootTemplate is CPGridTemplate ||
        rootTemplate is CPListTemplate ||
        rootTemplate is CPInformationTemplate ||
        rootTemplate is CPPointOfInterestTemplate) {
      return _carPlayController.methodChannel
          .invokeMethod('setRootTemplate', <String, dynamic>{
        'rootTemplate': rootTemplate.toJson(),
        'animated': animated,
        'runtimeType': _getCPRuntimeTypeString(rootTemplate),
      }).then((value) {
        if (value) {
          if (FlutterCarPlayController.templateHistory.isEmpty) {
            FlutterCarPlayController.templateHistory.add(rootTemplate);
          } else {
            FlutterCarPlayController.templateHistory[0] = rootTemplate;
          }
        }
      });
    }
  }

  /// It will set the current root template again.
  Future<void> forceUpdateRootTemplate() {
    return _carPlayController.methodChannel
        .invokeMethod('forceUpdateRootTemplate');
  }

  /// It will update the sections of the [CPListTemplate] which has the given [elementId].
  Future<void> updateListTemplateSections({
    required String elementId,
    required List<CPListSection> sections,
  }) async {
    final bool? isCompleted = await _carPlayController.methodChannel
        .invokeMethod('updateListTemplateSections', <String, dynamic>{
      'elementId': elementId,
      'sections':
          sections.map((CPListSection section) => section.toJson()).toList(),
    });

    if (isCompleted == true) {
      final template =
          FlutterCarPlayController.getTemplateFromHistory<CPListTemplate>(
              elementId);
      template?.updateSections(sections);
    }
    return;
  }

  /// It will update the templates of the [CPTabBarTemplate] which has the given [elementId].
  /// Supported template types: [CPListTemplate], [CPPointOfInterestTemplate],
  /// [CPGridTemplate], [CPInformationTemplate]
  Future<void> updateTabBarTemplates({
    required String elementId,
    required List<CPTemplate> templates,
  }) async {
    final bool? isCompleted = await _carPlayController.methodChannel
        .invokeMethod('updateTabBarTemplates', <String, dynamic>{
      'elementId': elementId,
      'templates': templates.map((CPTemplate template) {
        final json = template.toJson();
        if (template is CPListTemplate) {
          json['runtimeType'] = 'FCPListTemplate';
        } else if (template is CPPointOfInterestTemplate) {
          json['runtimeType'] = 'FCPPointOfInterestTemplate';
        } else if (template is CPGridTemplate) {
          json['runtimeType'] = 'FCPGridTemplate';
        } else if (template is CPInformationTemplate) {
          json['runtimeType'] = 'FCPInformationTemplate';
        }
        return json;
      }).toList(),
    });

    if (isCompleted == true) {
      final template =
          FlutterCarPlayController.getTemplateFromHistory<CPTabBarTemplate>(
              elementId);
      template?.updateTemplates(templates);
    }
    return;
  }

  /// Getter for current root template.
  /// Return one of type [CPTabBarTemplate], [CPGridTemplate], [CPListTemplate]
  static dynamic get rootTemplate {
    return FlutterCarPlayController.currentRootTemplate;
  }

  /// It will present [CPAlertTemplate] modally.
  ///
  /// - template is to present modally.
  /// - If animated is true, CarPlay animates the presentation of the template.
  ///
  /// [!] CarPlay can only present one modal template at a time.
  static Future<void> showAlert({
    required CPAlertTemplate template,
    bool animated = true,
  }) {
    return _carPlayController.methodChannel.invokeMethod(
      EnumUtils.stringFromEnum(FCPChannelTypes.setAlert.toString()),
      <String, dynamic>{
        'rootTemplate': template.toJson(),
        'animated': animated,
        'onPresent': template.onPresent != null ? true : false,
      },
    ).then((value) {
      if (value) {
        FlutterCarPlayController.currentPresentTemplate = template;
      }
    });
  }

  /// It will present [CPActionSheetTemplate] modally.
  ///
  /// - template is to present modally.
  /// - If animated is true, CarPlay animates the presentation of the template.
  ///
  /// [!] CarPlay can only present one modal template at a time.
  static Future<void> showActionSheet({
    required CPActionSheetTemplate template,
    bool animated = true,
  }) {
    return _carPlayController.methodChannel.invokeMethod(
      EnumUtils.stringFromEnum(FCPChannelTypes.setActionSheet.toString()),
      <String, dynamic>{
        'rootTemplate': template.toJson(),
        'animated': animated,
      },
    ).then((value) {
      if (value) {
        FlutterCarPlayController.currentPresentTemplate = template;
      }
    });
  }

  /// Removes the top-most template from the navigation hierarchy.
  ///
  /// - If animated is true, CarPlay animates the transition between templates.
  /// - count represents how many times this function will occur.
  static Future<bool> pop({bool animated = true, int count = 1}) async {
    final bool? isCompleted = await _carPlayController.flutterToNativeModule(
      FCPChannelTypes.popTemplate,
      <String, dynamic>{'count': count, 'animated': animated},
    );

    return isCompleted ?? false;
  }

  /// Removes all of the templates from the navigation hierarchy except the root template.
  /// If animated is true, CarPlay animates the presentation of the template.
  static Future<bool> popToRoot({bool animated = true}) async {
    final bool? isCompleted = await _carPlayController.flutterToNativeModule(
      FCPChannelTypes.popToRootTemplate,
      animated,
    );

    return isCompleted ?? false;
  }

  /// Removes a modal template. Since [CPAlertTemplate] and [CPActionSheetTemplate] are both
  /// modals, they can be removed. If animated is true, CarPlay animates the transition between templates.
  static Future<bool> popModal({bool animated = true}) async {
    FlutterCarPlayController.currentPresentTemplate = null;
    final bool? isCompleted = await _carPlayController.flutterToNativeModule(
      FCPChannelTypes.closePresent,
      animated,
    );

    return isCompleted ?? false;
  }

  /// Adds a template to the navigation hierarchy and displays it.
  ///
  /// - template is to add to the navigation hierarchy. **Must be one of the type:**
  /// [CPGridTemplate] or [CPListTemplate] [CPInformationTemplate] [CPPointOfInterestTemplate] If not, it will throw an [TypeError]
  ///
  /// - If animated is true, CarPlay animates the transition between templates.
  static Future<bool> push({
    required CPTemplate template,
    bool animated = true,
  }) async {
    if (template is CPGridTemplate ||
        template is CPListTemplate ||
        template is CPInformationTemplate ||
        template is CPPointOfInterestTemplate) {
      final bool? isCompleted = await _carPlayController.flutterToNativeModule(
          FCPChannelTypes.pushTemplate, <String, dynamic>{
        'template': template.toJson(),
        'animated': animated,
        'runtimeType': _getCPRuntimeTypeString(template),
      });
      if (isCompleted == true) {
        _carPlayController.addTemplateToHistory(template);
      }
      return isCompleted ?? false;
    } else {
      throw TypeError();
    }
  }

  /// Navigate to the shared instance of the NowPlaying Template
  ///
  /// - If animated is true, CarPlay animates the transition between templates.
  static Future<bool> showSharedNowPlaying({bool animated = true}) async {
    final bool? isCompleted = await _carPlayController.flutterToNativeModule(
      FCPChannelTypes.showNowPlaying,
      animated,
    );
    return isCompleted ?? false;
  }

  /// Returns the runtime type string for native communication.
  /// Uses explicit type checks to ensure compatibility with Dart obfuscation.
  static String _getCPRuntimeTypeString(CPTemplate template) {
    if (template is CPTabBarTemplate) return 'FCPTabBarTemplate';
    if (template is CPGridTemplate) return 'FCPGridTemplate';
    if (template is CPListTemplate) return 'FCPListTemplate';
    if (template is CPInformationTemplate) return 'FCPInformationTemplate';
    if (template is CPPointOfInterestTemplate) {
      return 'FCPPointOfInterestTemplate';
    }
    return 'FCP${template.runtimeType}';
  }
}
