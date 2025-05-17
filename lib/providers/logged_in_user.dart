class LoggedInUser {
  final int userId;
  final String fName;
  final String email;
  final int role;
  final int siteId;
  final String siteName;
  final String companyname;
  final String address;
  final int cpyid;

  LoggedInUser({
    required this.userId,
    required this.fName,
    required this.email,
    required this.role,
    required this.siteId,
    required this.siteName,
    required this.companyname,
    required this.address,
    required this.cpyid,
  });

  // From login API response
  factory LoggedInUser.fromJson(Map<String, dynamic> userJson,
      Map<String, dynamic> siteJson, Map<String, dynamic> companyJson) {
    return LoggedInUser(
      userId: userJson['account_id'] ?? 0,
      fName: userJson['first_name'] ?? '',
      email: userJson['email'] ?? '',
      role: userJson['role'] ?? 0,
      siteId: siteJson['site_id'] ?? 0,
      siteName: siteJson['site_name'] ?? '',
      companyname: companyJson['company_full_name'] ?? '',
      address: companyJson['address'] ?? '',
      cpyid: companyJson['cpy_id'] ?? 0, // Make sure this is parsed as int
    );
  }

  // From SharedPreferences (single JSON map)
  factory LoggedInUser.fromJsonStored(Map<String, dynamic> json) {
    return LoggedInUser(
      userId: json['user_id'] ?? 0,
      fName: json['f_name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 0,
      siteId: json['site_id'] ?? 0,
      siteName: json['site_name'] ?? '',
      companyname: json['company_full_name'] ?? '',
      address: json['address'] ?? '',
      cpyid: json['cpy_id'] ?? 0, // Make sure this is parsed as int
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'f_name': fName,
      'email': email,
      'role': role,
      'site_id': siteId,
      'site_name': siteName,
      'company_full_name':
          companyname, // Make sure keys match between to/fromJson
      'address': address,
      'cpy_id': cpyid,
    };
  }
}
