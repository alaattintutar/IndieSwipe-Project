class Game {
  final String id;
  final String title;
  final String gifUrl;
  final String description;
  final String steamLink;
  final List<String> tags;

  Game({
    required this.id,
    required this.title,
    required this.gifUrl,
    required this.description,
    required this.steamLink,
    required this.tags,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['_id'],
      title: json['title'],
      gifUrl: json['gifUrl'],
      description: json['description'],
      steamLink: json['steamLink'],
      tags: List<String>.from(json['tags']),
    );
  }
}