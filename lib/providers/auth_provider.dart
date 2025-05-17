import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../providers/globalapi.dart';
import '../providers/logged_in_user.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String _errorMessage = '';
  LoggedInUser? _user;

  // Create secure storage instance
  final _secureStorage = const FlutterSecureStorage();

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String get errorMessage => _errorMessage;
  LoggedInUser? get user => _user;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    final String loginUrl = "${AppConfig.baseUrl}/android_access/login";

    try {
      final response = await http.post(
        Uri.parse(loginUrl),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "login-username": email,
          "login-password": password,
        },
      );

      print('Response body: ${response.headers}');
      final data = json.decode(response.body);
      print("Response data: $data");

      if (response.statusCode == 200 && data["status"] == "Success") {
        final userJson = data["user"];
        final siteJson = data["site"];
        final companyJson = data["company"];

        LoggedInUser user =
            LoggedInUser.fromJson(userJson, siteJson, companyJson);

        // Save to secure storage
        await _secureStorage.write(key: 'isLoggedIn', value: 'true');
        await _secureStorage.write(
            key: 'userData', value: jsonEncode(user.toJson()));

        _user = user;
        _isLoggedIn = true;
        _isLoading = false;

        print('===== LOGGED IN USER DATA =====');
        print('User ID: ${user.userId}');
        print('Name: ${user.fName}');
        print('Email: ${user.email}');
        print('Role: ${user.role}');
        print('Site ID: ${user.siteId}');
        print('Site Name: ${user.siteName}');
        print('==============================');

        notifyListeners();
        return true;
      } else {
        _errorMessage = data["message"] ?? "Invalid phone or password";
      }
    } catch (error) {
      print('Login error: $error');
      _errorMessage = "Invalid phone or password";
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    // Clear secure storage
    await _secureStorage.delete(key: 'isLoggedIn');
    await _secureStorage.delete(key: 'userData');

    _isLoggedIn = false;
    _user = null;
    notifyListeners();
  }

  Future<void> checkLoginStatus() async {
    try {
      // Read all necessary values in parallel to save time
      final Map<String, String?> allValues = await _secureStorage.readAll();
      final String? isLoggedInValue = allValues['isLoggedIn'];
      final String? userJson = allValues['userData'];

      // Quick check for logged in state
      if (isLoggedInValue != 'true' || userJson == null || userJson.isEmpty) {
        _isLoggedIn = false;
        _user = null;
        notifyListeners();
        return; // Exit early if not logged in
      }

      // We have login data, try to parse it
      try {
        _user = LoggedInUser.fromJsonStored(json.decode(userJson));
        _isLoggedIn = true;
      } catch (e) {
        print('Error parsing user data: $e');
        _isLoggedIn = false;
        _user = null;

        // Clean up invalid data in a separate Future to not block the UI
        _cleanupInvalidData();
      }
    } catch (error) {
      print('Error checking login status: $error');
      _isLoggedIn = false;
      _user = null;
    }

    notifyListeners();
  }

  // Move cleanup to a separate method to not block the login check
  Future<void> _cleanupInvalidData() async {
    try {
      await _secureStorage.delete(key: 'isLoggedIn');
      await _secureStorage.delete(key: 'userData');
    } catch (e) {
      print('Error cleaning up invalid data: $e');
    }
  }

  Future<LoggedInUser?> getUserData() async {
    try {
      String? userJson = await _secureStorage.read(key: 'userData');
      if (userJson != null) {
        return LoggedInUser.fromJsonStored(json.decode(userJson));
      }
    } catch (error) {
      print('Error getting user data: $error');
    }
    return null;
  }
}
