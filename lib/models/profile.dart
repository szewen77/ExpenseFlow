class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.avatarEmoji,
  });

  final int id;
  final String name;
  final String avatarEmoji;

  UserProfile copyWith({int? id, String? name, String? avatarEmoji}) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'avatarEmoji': avatarEmoji,
    };
  }

  factory UserProfile.fromMap(Map<String, Object?> map) {
    return UserProfile(
      id: map['id'] as int,
      name: map['name'] as String,
      avatarEmoji: map['avatarEmoji'] as String? ?? '🙂',
    );
  }

  static const defaultProfile = UserProfile(
    id: 1,
    name: 'Guest',
    avatarEmoji: '🙂',
  );
}
