class MovieImage {
  final String filePath;

  MovieImage({required this.filePath});

  factory MovieImage.fromJson(Map<String, dynamic> json) {
    return MovieImage(
      filePath: json['file_path'],
    );
  }
}
