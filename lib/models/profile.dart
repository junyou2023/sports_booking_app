class Profile {
  final String email;
  final String companyName;
  final String phone;

  Profile({required this.email, required this.companyName, required this.phone});

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      email: json['email'] as String,
      companyName: json['company_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }
}
