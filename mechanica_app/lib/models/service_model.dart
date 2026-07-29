class ServiceModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String iconName;
  final String category;
  final String duration; // e.g. "2-3 hours"
  final bool isPopular;
  final List<String> includes;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.iconName,
    required this.category,
    required this.duration,
    required this.isPopular,
    required this.includes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'iconName': iconName,
        'category': category,
        'duration': duration,
        'isPopular': isPopular,
        'includes': includes,
      };

  factory ServiceModel.fromJson(Map<String, dynamic> json) => ServiceModel(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        price: (json['price'] as num).toDouble(),
        iconName: json['iconName'],
        category: json['category'],
        duration: json['duration'],
        isPopular: json['isPopular'],
        includes: List<String>.from(json['includes']),
      );
}
