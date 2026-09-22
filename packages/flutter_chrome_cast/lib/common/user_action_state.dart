import 'dart:convert';

import 'package:flutter_chrome_cast/common/user_action.dart';

/// Represents the state of a user action in a cast session.
class UserActionState {
  ///User actions custom data.
  final Map<String, dynamic>? customData;

  /// The user action associated with this state.
  final UserAction? userAction;

  /// Creates a new [UserActionState] instance.
  ///
  /// [customData] - Custom data associated with the user action.
  /// [userAction] - The user action.
  UserActionState({
    this.customData,
    this.userAction,
  });

  /// Converts the [UserActionState] to a map.
  ///
  /// Returns a [Map] representation of this object.
  Map<String, dynamic> toMap() {
    return {
      'customData': customData,
      'userAction': userAction?.name,
    };
  }

  /// Creates a [UserActionState] from a map.
  ///
  /// [map] - The map to create the instance from.
  factory UserActionState.fromMap(Map<String, dynamic> map) {
    return UserActionState(
      customData: map['customData'] != null
          ? Map<String, dynamic>.from(map['customData'])
          : null,
      userAction: map['userAction'] != null
          ? UserAction.fromMap(map['userAction'])
          : null,
    );
  }

  /// Converts the [UserActionState] to a JSON string.
  ///
  /// Returns a JSON string representation of this object.
  String toJson() => json.encode(toMap());

  /// Creates a [UserActionState] from a JSON string.
  ///
  /// [source] - The JSON string to create the instance from.
  factory UserActionState.fromJson(String source) =>
      UserActionState.fromMap(json.decode(source));
}
