class Profile {
  final String email;
  final bool isProvider;
  final String companyName;
  final String phone;
  final String address;

  Profile({
    required this.email,
    required this.isProvider,
    required this.companyName,
    required this.phone,
    required this.address,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      email: json['email'] as String,
      isProvider: json['is_provider'] as bool? ?? false,
      companyName: json['company_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
    );
  }
}
