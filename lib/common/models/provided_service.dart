class ProvidedService {
  final int id;
  final int providerId;
  final String name;
  final String? description;
  final double price;
  final String currency;
  final String? category;
  final List<String> imageUrls;
  final DateTime createdAt;

  final String? providerName;
  final String? providerPhone;

  ProvidedService({
    required this.id,
    required this.providerId,
    required this.name,
    this.description,
    required this.price,
    required this.currency,
    this.category,
    required this.imageUrls,
    required this.createdAt,
    this.providerName,
    this.providerPhone,
  });

  factory ProvidedService.fromJson(Map<String, dynamic> json) {
    var images = <String>[];
    if (json['service_images'] != null) {
      images =
          (json['service_images'] as List)
              .map((e) => e['image_url'] as String)
              .toList();
    }

    String? pName;
    String? pPhone;
    if (json['service_providers'] != null) {
      pName = json['service_providers']['business_name'];
      pPhone = json['service_providers']['phone'];
    }

    return ProvidedService(
      id: json['id'] as int,
      providerId: json['provider_id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'MAD',
      category: json['category'] as String?,
      imageUrls: images,
      createdAt: DateTime.parse(json['created_at'] as String),
      providerName: pName,
      providerPhone: pPhone,
    );
  }
}
