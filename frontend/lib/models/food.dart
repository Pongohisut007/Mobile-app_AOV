class Food {
  final int idfoods;
  final String name;
  final String category;
  final String description;
  final String filePathImage;

  Food({
    required this.idfoods,
    required this.name,
    required this.category,
    required this.description,
    required this.filePathImage,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      idfoods: json['idfoods'] as int,
      name: json['name'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      filePathImage: json['file_path_image'] as String,
    );
  }

}