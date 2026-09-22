/// Represents criteria for discovering Google Cast devices.
abstract class GoogleCastDiscoveryCriteria {
  /// Initializes discovery criteria with the provided configuration.
  static GoogleCastDiscoveryCriteriaInitialize initialize(
          GoogleCastDiscoveryCriteriaInitialize initializeWith) =>
      initializeWith;

  /// this command is useful to native execute a custom command

  /// Default application ID for Cast devices.
  static const String kDefaultApplicationId = 'CC1AD845';

  /// Set of application IDs to discover.
  Set<String>? get applicationIds;

  /// Whether application IDs are set.
  bool? get hasApplicationIds;

  /// Set of namespaces to discover.
  Set<String>? get namespaces;

  /// Whether namespaces are set.
  bool? get hasNamespaces;

  /// Set of all subtypes.
  Set<String>? get allSubtypes;
}

/// Provides initialization options for Google Cast discovery criteria.
class GoogleCastDiscoveryCriteriaInitialize {
  /// The data map containing discovery configuration.
  final Map<String, dynamic> data;

  /// Creates a new [GoogleCastDiscoveryCriteriaInitialize] with the given data.
  GoogleCastDiscoveryCriteriaInitialize._({
    required this.data,
  });

  /// Initializes with an application ID.
  factory GoogleCastDiscoveryCriteriaInitialize.initWithApplicationID(
      String applicationID) {
    return GoogleCastDiscoveryCriteriaInitialize._(
      data: <String, dynamic>{
        'method': 'initWithApplicationID',
        'applicationID': applicationID,
      },
    );
  }

  /// Initializes with a set of namespaces.
  factory GoogleCastDiscoveryCriteriaInitialize.initWithNamespaces(
      Set<String> namespaces) {
    return GoogleCastDiscoveryCriteriaInitialize._(
      data: <String, dynamic>{
        'method': 'initWithNamespaces',
        'namespaces': namespaces,
      },
    );
  }

  /// Converts the object to a map for serialization.
  Map<String, dynamic> toMap() => data;
}
