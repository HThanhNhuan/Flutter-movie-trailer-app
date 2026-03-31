import 'genre.dart';

class Movie {
  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final String? releaseDate;
  final List<Genre>? genres;
  final List<ProductionCompany>? productionCompanies;
  final String? character; // Dùng cho danh sách phim của diễn viên

  Movie({
    required this.id,
    required this.title,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    this.releaseDate,
    this.genres,
    this.productionCompanies,
    this.character,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'],
      title: json['title'] ?? 'No Title',
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      releaseDate: json['release_date'],
      genres: json['genres'] != null
          ? (json['genres'] as List).map((g) => Genre.fromJson(g)).toList()
          : null,
      productionCompanies: json['production_companies'] != null
          ? (json['production_companies'] as List)
              .map((c) => ProductionCompany.fromJson(c))
              .toList()
          : null,
      // 'character' thường có trong API movie_credits của diễn viên
      character: json['character'],
    );
  }

  // Dành cho việc lưu vào DB SQLite
  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'title': title,
      'overview': overview,
      'poster_path': posterPath,
      'vote_average': voteAverage,
    };
  }

  factory Movie.fromDbMap(Map<String, dynamic> map) {
    return Movie(
      id: map['id'],
      title: map['title'],
      overview: map['overview'],
      posterPath: map['poster_path'],
      voteAverage: map['vote_average'],
    );
  }
}

class ProductionCompany {
  final String name;
  final String? logoPath;

  ProductionCompany({required this.name, this.logoPath});

  factory ProductionCompany.fromJson(Map<String, dynamic> json) {
    return ProductionCompany(
      name: json['name'],
      logoPath: json['logo_path'],
    );
  }
}
