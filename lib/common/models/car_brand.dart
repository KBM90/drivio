class CarBrand {
  final int id;
  final String company;
  final String model;
  final String? thumbnailImage;
  final String? category;
  final double? averageConsumption; // L/100km

  CarBrand({
    required this.id,
    required this.company,
    required this.model,
    this.thumbnailImage,
    this.category,
    this.averageConsumption,
  });

  factory CarBrand.fromJson(Map<String, dynamic> json) {
    return CarBrand(
      id: json['id'] as int,
      company: json['company'] as String,
      model: json['model'] as String,
      thumbnailImage: json['thumbnail_image'] as String?,
      category: json['category'] as String?,
      averageConsumption: (json['average_consumption'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company': company,
      'model': model,
      'thumbnail_image': thumbnailImage,
      'category': category,
      'average_consumption': averageConsumption,
    };
  }
}
