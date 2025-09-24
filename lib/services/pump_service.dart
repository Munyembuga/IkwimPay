import 'dart:convert';
import 'package:http/http.dart' as http;

class PumpService {
  static const String baseUrl = 'https://mis.ikwim.com/api/pump/command';

  static Future<Map<String, dynamic>> getShifts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_shifts'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load shifts');
      }
    } catch (e) {
      throw Exception('Error fetching shifts: $e');
    }
  }

  static Future<Map<String, dynamic>> getShiftInfo({
    required int userId,
    required int siteId,
    required int shiftId,
  }) async {
    print(
        "Response body&&&&&&&&&&&&&&&& userId: $userId, siteId: $siteId, shiftId: $shiftId");
    try {
      final response = await http.post(
        Uri.parse('https://mis.ikwim.com/api/pump/command/shift_info'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId, // Use the actual userId instead of hardcoded 2236
          'site_id': siteId,
          'sitshift_id': shiftId,
        }),
      );
      print("Response body&&&&&&&&&&&&&&&&: ${response.body}");
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load shift info');
      }
    } catch (e) {
      throw Exception('Error fetching shift info: $e');
    }
  }

  static Future<Map<String, dynamic>> getNozzleIndex({
    required int nozzleId,
    required int siteId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/nozzle_index'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nozzle_id': nozzleId,
          'site_id': siteId,
        }),
      );
      print("Response body&&&&&&&&&&&&&&&&: ${response.body}");
      print("Response body&&&&&&&&&&&&&&&&: ${response.body}");
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load nozzle index');
      }
    } catch (e) {
      throw Exception('Error fetching nozzle index: $e');
    }
  }

  static Future<Map<String, dynamic>> submitPumpIndex({
    required int nozzleId,
    required int productId,
    required double sellingPrice,
    required int shiftsiteId,
    required double startIndex,
    required double endIndex,
    required int accId,
    required int siteId,
  }) async {
    try {
      final requestBody = {
        'nozzle_id': nozzleId,
        'product_id': productId,
        'selling_price': sellingPrice,
        'shiftsiteId': shiftsiteId,
        'start_index': startIndex,
        'end_index': endIndex,
        'acc_id': accId,
        'site_id': siteId,
      };

      print('Submit index request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('https://mis.ikwim.com/api/pump/command/add_index'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Submit index response status: ${response.statusCode}');
      print('Submit index response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = response.body;

        // Check if response is HTML (redirect page)
        if (responseBody.contains('<!DOCTYPE html>')) {
          throw Exception(
              'Server returned redirect page. Check if the API endpoint is correct.');
        }

        try {
          return jsonDecode(responseBody);
        } catch (jsonError) {
          throw Exception('Invalid JSON response: $jsonError');
        }
      } else if (response.statusCode == 301 || response.statusCode == 302) {
        // Handle redirect
        final location = response.headers['location'];
        throw Exception(
            'API endpoint moved to: $location. Please update the endpoint URL.');
      } else {
        throw Exception(
            'Failed to submit index. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error submitting index: $e');
    }
  }

  static Future<Map<String, dynamic>> getPendingIndexTransactions({
    required int siteId,
    required int? userId,
  }) async {
    try {
      final requestBody = {
        'site_id': siteId,
        'user_id': userId,
        // if (shiftId != null) 'shift_id': shiftId,
      };

      print('Pending transactions request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/pending_approvals'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Pending transactions response status: ${response.statusCode}');
      print('Pending transactions response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = response.body;

        if (responseBody.contains('<!DOCTYPE html>')) {
          throw Exception(
              'Server returned redirect page. Check if the API endpoint is correct.');
        }

        try {
          return jsonDecode(responseBody);
        } catch (jsonError) {
          throw Exception('Invalid JSON response: $jsonError');
        }
      } else {
        throw Exception(
            'Failed to fetch pending transactions. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching pending transactions: $e');
    }
  }

  static Future<Map<String, dynamic>> approveIndexTransaction(
      {required int transactionId,
      required int userId,
      required int siteID}) async {
    try {
      final requestBody = {
        'pumpIndex_id': transactionId,
        'approver_acc_id': userId,
        'site_id': siteID,
      };

      print('Approve transaction request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/approve_index'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Approve transaction response status: ${response.statusCode}');
      print('Approve transaction response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = response.body;
        if (responseBody.contains('<!DOCTYPE html>')) {
          throw Exception(
              'Server returned redirect page. Check if the API endpoint is correct.');
        }

        try {
          return jsonDecode(responseBody);
        } catch (jsonError) {
          throw Exception('Invalid JSON response: $jsonError');
        }
      } else {
        throw Exception(
            'Failed to approve transaction. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error approving transaction: $e');
    }
  }

  static Future<Map<String, dynamic>> updatePumpIndex({
    required int transactionId,
    required int accId,
    required int siteId,
    required double endIndex,
  }) async {
    try {
      final requestBody = {
        'pumpIndex_id': transactionId,
        'acc_id': accId,
        'site_id': siteId,
        'end_index': endIndex,
      };

      print('Update pump index request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/edit_indexing'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Update pump index response status: ${response.statusCode}');
      print('Update pump index response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = response.body;

        if (responseBody.contains('<!DOCTYPE html>')) {
          throw Exception(
              'Server returned redirect page. Check if the API endpoint is correct.');
        }

        try {
          final jsonResponse = jsonDecode(responseBody);

          // Check if the response contains an error status
          if (jsonResponse['status'] != null && jsonResponse['status'] != 200) {
            throw Exception(
                jsonResponse['message'] ?? 'Unknown error occurred');
          }

          return jsonResponse;
        } catch (jsonError) {
          if (jsonError is Exception &&
              jsonError.toString().contains('Exception: ')) {
            rethrow; // Re-throw our custom exceptions
          }
          throw Exception('Invalid JSON response: $jsonError');
        }
      } else {
        // Try to decode the error response to get the message
        try {
          final errorResponse = jsonDecode(response.body);
          final errorMessage =
              errorResponse['message'] ?? 'Failed to update pump index';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception(
              'Failed to update pump index. Status: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (e is Exception && e.toString().startsWith('Exception: ')) {
        rethrow; // Re-throw our custom exceptions with proper messages
      }
      throw Exception('Error updating pump index: $e');
    }
  }
}
