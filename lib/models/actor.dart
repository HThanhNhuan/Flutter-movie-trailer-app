class Actor {
  final int id;
  final String name;
  final String? biography;
  final String? profilePath;
  final String? birthday;
  final String? placeOfBirth;

  Actor({
    required this.id,
    required this.name,
    this.biography,
    this.profilePath,
    this.birthday,
    this.placeOfBirth,
  });

  factory Actor.fromJson(Map<String, dynamic> json) {
    return Actor(
      id: json['id'],
      name: json['name'] ?? 'Unknown',
      biography: json['biography'],
      profilePath: json['profile_path'],
      birthday: json['birthday'],
      placeOfBirth: json['place_of_birth'],
    );
  }
}
