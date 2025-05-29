import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ikwimpay/providers/auth_provider.dart';
import 'package:ikwimpay/providers/globalapi.dart';
import 'package:ikwimpay/scr/homescreen.dart';
import 'package:ikwimpay/scr/plateScanner.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class DirectPaymentCardScreen extends StatefulWidget {
  final String cardId;

  final Map<String, dynamic> responseData;

  const DirectPaymentCardScreen({
    Key? key,
    required this.cardId,
    required this.responseData,
  }) : super(key: key);

  const DirectPaymentCardScreen.withoutTransaction({
    Key? key,
    required this.cardId,
  })  : responseData = const {}, // Initialize with empty map
        super(key: key);

  @override
  State<DirectPaymentCardScreen> createState() =>
      _DirectPaymentCardScreenState();
}

class _DirectPaymentCardScreenState extends State<DirectPaymentCardScreen> {
  bool _isNfcReading = false;
  bool _isReading = false;
  bool _isStartingTransaction = false;
  String _nozzle_tag = '1';
  // NFC-related variables
  String _nfcStatus = 'Ready to scan nozzle';
  String? _nozzleIdcard;
  String? _clientname;
  String? _balance;
  String? _cardnumber;
  Map<String, dynamic>? _verificationResult;
  int? _userRole;
  int? _cardType;
  int? _cardId;
  String _reverseHexString(String hex) {
    List<String> hexBytes = [];
    for (var i = 0; i < hex.length; i += 2) {
      hexBytes.add(hex.substring(i, i + 2));
    }
    return hexBytes.reversed.join();
  }

  @override
  void initState() {
    super.initState();
    _mapResponseData();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.user?.role;
    _userRole = userRole;

    // Give the UI a moment to build before starting the NFC scan
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        _startNfcNozzleScanning();
      }
    });
  }

  void _mapResponseData() {
    _clientname =
        widget.responseData['data']?['client_name'].toString() ?? 'N/A';
    _balance = widget.responseData['data']?['balance'].toString() ?? 'N/A';
    _cardnumber = widget.responseData['data']?['card_no'].toString() ?? 'N/A';
    _cardType = widget.responseData['data']?['card_type'];
    _cardId = widget.responseData['data']?['card_id'];
    // Optional: Print for debugging
    print('_clientnameFFFFFFFFFFF : $_clientname');
    print('_clientnameFFFFFFFFFFF : $_balance');
    print('_clientnameFFFFFFFFFFF : $_cardnumber');
    print('__cardTypeFFFFFFFFFFF : $_cardType');
    print('___cardIdFFFFFFFFFFF : $_cardId');
    print(widget.responseData['data']);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _startTransaction() async {
    setState(() {
      _isStartingTransaction = true; // Set loading state
    });
    if (_mapResponseData == null || _nozzleIdcard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please  nozzle verification first'),
          backgroundColor: const Color(0xFFA50000),
        ),
      );
      setState(() {
        _isStartingTransaction = false; // Reset loading state
      });
      return;
    }
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) {
      setState(() {
        _isStartingTransaction = false; // Reset loading state
      });
      return;
    }

    try {
      String userId = user.userId.toString();
      print(widget.responseData['data']?['card_type'].toString() ?? 'N/A');
      // Prepare request body based on card type
      Map<String, dynamic> requestBody;
      print(widget.responseData['data']?['card_type'].toString() ?? 'N/A');

      // Check if card type is 5
      // if (_cardType == 5) {
      requestBody = {
        'card_id': widget.responseData['data']?['card_id'].toString() ?? 'N/A',
        'plate_no':
            widget.responseData['data']?['card_type_name'].toString() ?? 'N/A',
        'nozzle_id': _nozzleIdcard.toString(),
        'user_id': userId.toString(),
        'plate_image': "",
      };
      // }

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/transaction/command/lock'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );
      print('HJJJJJJJJJJJJJJJJJ ${jsonEncode(requestBody)}');
      Map<String, dynamic> responseData = jsonDecode(response.body);
      print('&&&&&&&&&&&&&&&&&&&&hhhhhhhhhhhhh ${responseData}');

      if ((responseData['success'] == 200) || responseData['status'] == '200') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction started successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HomeScreen(initialIndex: 3),
              ));
        }); // TODO: Navigate to the next screen or perform next action
      } else {
        // Show error SnackBar with delay

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Transaction started failed: ${responseData['message'] ?? 'Unknown error'}'),
            backgroundColor: const Color(0xFFA50000),
            duration: const Duration(seconds: 5),
          ),
        );

        // Future.delayed(const Duration(seconds: 2), () {
        //   Navigator.push(
        //       context,
        //       MaterialPageRoute(
        //         builder: (context) => const HomeScreen(initialIndex: 1),
        //       ));
        // });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting transaction: ${e.toString()}'),
          backgroundColor: const Color(0xFFA50000),
        ),
      );
    } finally {
      setState(() {
        _isStartingTransaction = false;
      });
    }
  }

  Future<void> _saveZolle(_nozzleIdcard) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('serialDecimal', _nozzleIdcard);

    print('Card ID saved to SharedPreference: $_nozzleIdcard');
  }

  Future<void> _startNfcNozzleScanning() async {
    if (_isNfcReading) return;

    setState(() {
      _isNfcReading = true;
      _isReading = true;
      _nfcStatus = 'Scanning for nozzle NFC tag...';
      _nozzleIdcard = null; // Reset nozzle ID when starting a new scan
    });

    try {
      var tag = await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 20),
        iosAlertMessage: 'Hold your device near the nozzle NFC tag',
      );

      String serial = tag.id;
      String reversedSerial = _reverseHexString(serial);
      int? serialInt = int.tryParse(reversedSerial, radix: 16);
      String serialDecimal =
          serialInt != null ? serialInt.toString() : "Conversion failed";

      _nozzle_tag = serialDecimal;

      setState(() {
        _nfcStatus = 'Nozzle Detected! Verifying...';
      });

      // Immediately verify the nozzle after detection
      await _verifyNozzle();
    } catch (e) {
      setState(() {
        print('Error scanning nozzle: ${e.toString()}');
        _nfcStatus = 'Scan failed. Tap to try again.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nozzle scanning timed out. Please try again.'),
          backgroundColor: Color(0xFFA50000),
        ),
      );
    } finally {
      await FlutterNfcKit.finish();
      if (mounted) {
        setState(() {
          _isNfcReading = false;
          _isReading = false;
        });
      }
    }
  }

  // New method to separate concerns
  Future<void> _verifyNozzle() async {
    setState(() {
      _nfcStatus = 'Verifying nozzle...';
    });

    try {
      Map<String, dynamic> requestBody = {
        'nozzle_tag': _nozzle_tag,
      };

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/nozzle/command/verify'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      final responseData = jsonDecode(response.body);
      print("Nozzle verification response: $responseData");

      if (responseData['status'] == 200) {
        _nozzleIdcard = responseData['data']['nozzle_id'].toString();
        await _saveZolle(_nozzleIdcard!);

        setState(() {
          _nfcStatus = 'Nozzle verified successfully!';
        });

        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(
        //     content: Text('Nozzle verified successfully!'),
        //     backgroundColor: Colors.green,
        //   ),
        // );
      } else {
        setState(() {
          _nfcStatus = 'Nozzle verification failed. Please try again.';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Verification failed: ${responseData['message'] ?? responseData['data'] ?? "Unknown error"}'),
            backgroundColor: const Color(0xFFA50000),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _nfcStatus = 'Verification error. Please try again.';
      });

      print('Nozzle verification error: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error verifying nozzle: ${e.toString()}'),
          backgroundColor: const Color(0xFFA50000),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Direct Payment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400),
        ),
        backgroundColor: const Color(0xFFA50000),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Client',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      _buildInfoItem('Name:', _clientname.toString()),
                      _buildInfoItem('Balance:', _balance.toString()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Remove the plate number field and verify button
              // Instead, show the nozzle scanning section directly
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.contactless,
                        size: 100,
                        color:
                            _isReading ? const Color(0xFFA50000) : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      _nfcStatus,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (!_isNfcReading && _nozzleIdcard == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFA50000)),
                          onPressed: _startNfcNozzleScanning,
                          child: const Text(
                            'Scan Nozzle',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    if (_nozzleIdcard != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isStartingTransaction
                                ? null
                                : _startTransaction,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              backgroundColor: _isStartingTransaction
                                  ? Colors.grey.shade400
                                  : const Color(0xFFA50000),
                            ),
                            child: _isStartingTransaction
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : const Text(
                                    'Start Transaction',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                      )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildInfoItem(String label, String value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(width: 3),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}
