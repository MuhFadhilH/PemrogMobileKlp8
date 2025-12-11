class UserPreference {
  final List<String> favoriteGenres;
  final List<String> favoriteAuthors;
  final bool showAdultContent;
  final String languagePreference;

  UserPreference({
    this.favoriteGenres = const [],
    this.favoriteAuthors = const [],
    this.showAdultContent = false,
    this.languagePreference = 'id',
  });

  Map<String, dynamic> toMap() {
    return {
      'favoriteGenres': favoriteGenres,
      'favoriteAuthors': favoriteAuthors,
      'showAdultContent': showAdultContent,
      'languagePreference': languagePreference,
    };
  }

  factory UserPreference.fromMap(Map<String, dynamic> map) {
    return UserPreference(
      favoriteGenres: List<String>.from(map['favoriteGenres'] ?? []),
      favoriteAuthors: List<String>.from(map['favoriteAuthors'] ?? []),
      showAdultContent: map['showAdultContent'] ?? false,
      languagePreference: map['languagePreference'] ?? 'id',
    );
  }

  UserPreference copyWith({
    List<String>? favoriteGenres,
    List<String>? favoriteAuthors,
    bool? showAdultContent,
    String? languagePreference,
  }) {
    return UserPreference(
      favoriteGenres: favoriteGenres ?? this.favoriteGenres,
      favoriteAuthors: favoriteAuthors ?? this.favoriteAuthors,
      showAdultContent: showAdultContent ?? this.showAdultContent,
      languagePreference: languagePreference ?? this.languagePreference,
    );
  }
}
