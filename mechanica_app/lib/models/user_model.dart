class UserModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String? profileImageUrl;
  final String referralCode;
  final double walletBalance;
  final String membershipPlan; // 'none', 'silver', 'gold', 'platinum'
  final int loyaltyPoints;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.profileImageUrl,
    required this.referralCode,
    required this.walletBalance,
    required this.membershipPlan,
    required this.loyaltyPoints,
    required this.createdAt,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? profileImageUrl,
    String? referralCode,
    double? walletBalance,
    String? membershipPlan,
    int? loyaltyPoints,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      referralCode: referralCode ?? this.referralCode,
      walletBalance: walletBalance ?? this.walletBalance,
      membershipPlan: membershipPlan ?? this.membershipPlan,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'profileImageUrl': profileImageUrl,
        'referralCode': referralCode,
        'walletBalance': walletBalance,
        'membershipPlan': membershipPlan,
        'loyaltyPoints': loyaltyPoints,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'],
        name: json['name'],
        phone: json['phone'],
        email: json['email'],
        profileImageUrl: json['profileImageUrl'],
        referralCode: json['referralCode'],
        walletBalance: (json['walletBalance'] as num).toDouble(),
        membershipPlan: json['membershipPlan'],
        loyaltyPoints: json['loyaltyPoints'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}
