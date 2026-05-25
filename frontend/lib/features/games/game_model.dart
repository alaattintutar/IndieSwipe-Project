class Game {
  final String id;
  final String title;
  final String gifUrl;
  final String videoUrl;
  final String description;
  final String steamLink;
  final String price;
  final String reviewSummary;
  final List<String> tags;

  Game({
    required this.id,
    required this.title,
    required this.gifUrl,
    required this.videoUrl,
    required this.description,
    required this.steamLink,
    required this.price,
    required this.reviewSummary,
    required this.tags,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['_id'],
      title: json['title'],
      gifUrl: json['gifUrl'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      description: json['description'] ?? '',
      steamLink: json['steamLink'] ?? '',
      price: json['price'] ?? 'N/A',
      reviewSummary: json['reviewSummary'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}
