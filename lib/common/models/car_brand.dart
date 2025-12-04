class CarBrand {
  final int id;
  final String company;
  final String model;
  final String? thumbnailImage;
  final String? category;

  CarBrand({
    required this.id,
    required this.company,
    required this.model,
    this.thumbnailImage,
    this.category,
  });

  factory CarBrand.fromJson(Map<String, dynamic> json) {
    return CarBrand(
      id: json['id'] as int,
      company: json['company'] as String,
      model: json['model'] as String,
      thumbnailImage: json['thumbnail_image'] as String?,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company': company,
      'model': model,
      'thumbnail_image': thumbnailImage,
      'category': category,
    };
  }
}
