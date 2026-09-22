/// User actions.
enum UserAction {
  /// User indicates a like preference for the currently playing content.
  like,

  /// User indicates a dislike preference for the currently playing content.
  dislike,

  /// User wants to follow or star currently playing content.
  follow,

  /// User wants to stop following currently playing content.
  unfollow;

  factory UserAction.fromMap(String value) {
    // Try matching by name (lowerCamelCase)
    for (final v in values) {
      if (v.name == value) return v;
    }
    // Fallback: match legacy UPPER_SNAKE_CASE
    switch (value) {
      case 'LIKE':
        return UserAction.like;
      case 'DISLIKE':
        return UserAction.dislike;
      case 'FOLLOW':
        return UserAction.follow;
      case 'UNFOLLOW':
        return UserAction.unfollow;
      default:
        throw ArgumentError('Unknown UserAction: $value');
    }
  }

  @override
  String toString() {
    return name;
  }
}
