class BikeModel {
  final String id;
  final String userId;
  final String name;
  final String brand;
  final String model;
  final String registrationNumber;
  final int year;
  final String fuelType; // 'petrol', 'electric', 'cng'
  final String? imageUrl;
  final String? insuranceExpiry;
  final String? pucExpiry;
  final int odometer;
  final String color;
  final bool isPrimary;
  final DateTime addedAt;

  const BikeModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.brand,
    required this.model,
    required this.registrationNumber,
    required this.year,
    required this.fuelType,
    this.imageUrl,
    this.insuranceExpiry,
    this.pucExpiry,
    required this.odometer,
    required this.color,
    required this.isPrimary,
    required this.addedAt,
  });

  BikeModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? brand,
    String? model,
    String? registrationNumber,
    int? year,
    String? fuelType,
    String? imageUrl,
    String? insuranceExpiry,
    String? pucExpiry,
    int? odometer,
    String? color,
    bool? isPrimary,
    DateTime? addedAt,
  }) {
    return BikeModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      year: year ?? this.year,
      fuelType: fuelType ?? this.fuelType,
      imageUrl: imageUrl ?? this.imageUrl,
      insuranceExpiry: insuranceExpiry ?? this.insuranceExpiry,
      pucExpiry: pucExpiry ?? this.pucExpiry,
      odometer: odometer ?? this.odometer,
      color: color ?? this.color,
      isPrimary: isPrimary ?? this.isPrimary,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'brand': brand,
        'model': model,
        'registrationNumber': registrationNumber,
        'year': year,
        'fuelType': fuelType,
        'imageUrl': imageUrl,
        'insuranceExpiry': insuranceExpiry,
        'pucExpiry': pucExpiry,
        'odometer': odometer,
        'color': color,
        'isPrimary': isPrimary,
        'addedAt': addedAt.toIso8601String(),
      };

  factory BikeModel.fromJson(Map<String, dynamic> json) => BikeModel(
        id: json['id'],
        userId: json['userId'],
        name: json['name'],
        brand: json['brand'],
        model: json['model'],
        registrationNumber: json['registrationNumber'],
        year: json['year'],
        fuelType: json['fuelType'],
        imageUrl: json['imageUrl'],
        insuranceExpiry: json['insuranceExpiry'],
        pucExpiry: json['pucExpiry'],
        odometer: json['odometer'],
        color: json['color'],
        isPrimary: json['isPrimary'],
        addedAt: DateTime.parse(json['addedAt']),
      );
}
