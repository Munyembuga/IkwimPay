import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ikwimpay/providers/globalapi.dart';
import 'package:ikwimpay/scr/verifyVehiche.dart';
// import 'package:ikwimpay/scr/matchCard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// import 'package:/scr/VerifyVehicleScreen.dart';

class EnableCard extends StatefulWidget {
  const EnableCard({Key? key}) : super(key: key);

  @override
  State<EnableCard> createState() => _EnableCardState();
}

class _EnableCardState extends State<EnableCard> {
  bool _isReading = false;
  bool _isVerifying = false;
  String _nfcStatus = 'Ready to scan';
  String _nfcData = 'No data';
  String? _serialDecimalValue;
  String? _savedCardId;
  String? _cardnumber;
  bool _showPinInput = false;
  bool _hideStartScanButton = false;
  String? _clientName;
  bool _start = false;
  String? _card_codef;
  String? _card_type_name;
  bool _cardinfo = false;
  bool _showCardinfo = false;
  String? _ndefRecordData; // New variable to store NDEF record data

  String _reverseHexString(String hex) {
    // Splits the hex string into two-character chunks and reverses the order.
    List<String> hexBytes = [];
    for (var i = 0; i < hex.length; i += 2) {
      hexBytes.add(hex.substring(i, i + 2));
    }
    return hexBytes.reversed.join();
  }

  final TextEditingController _textController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkNfcAvailability();
  }

  @override
  void dispose() {
    // Make sure to finish any NFC session when the screen is disposed
    _finishNfcSession();
    _textController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _checkNfcAvailability() async {
    try {
      NFCAvailability availability = await FlutterNfcKit.nfcAvailability;
      if (availability != NFCAvailability.available) {
        setState(() {
          _nfcStatus = 'NFC not available on this device';
          _start = false;
        });

        print('NFC is not available on this device');
      } else {
        setState(() {
          _nfcStatus = 'NFC is available. Ready to scan.';
        });
        await _readNfcTag();
        _start = true;

        print('NFC is available and ready to scan');
      }
    } catch (e) {
      setState(() {
        _nfcStatus = 'Error checking NFC ';
        print('Error checking NFC:${e.toString()} ');
      });
      print('Error checking NFC: $e');
    }
  }

  Future<void> _readNfcTag() async {
    if (_isReading) return;

    setState(() {
      _isReading = true;
      _nfcStatus = 'Scanning for card...';
    });

    print('Starting NFC scan session...');

    try {
      var tag = await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 20),
        iosAlertMessage: 'Hold your device near the NFC tag',
      );

      String serial = tag.id;
      String reversedSerial = _reverseHexString(serial);
      int? serialInt = int.tryParse(reversedSerial, radix: 16);
      String serialDecimal =
          serialInt != null ? serialInt.toString() : "Conversion failed";
      String identification = "Type: ${tag.type}";
      if (tag.atqa != null) identification += ", ATQA: ${tag.atqa}";
      if (tag.sak != null) identification += ", SAK: ${tag.sak}";

      _serialDecimalValue = serialDecimal;
      String cardIdentifier = serialDecimal; // Default to serial number

      setState(() {
        _nfcData = serial;
        _nfcStatus = 'Card detected!';
      });

      print('===== NFC TAG DETECTED =====');
      print('ID: ${tag.id}');
      print('Type: ${serialDecimal}');
      print('Standard: ${tag.standard}');
      print('===========================');

      // Attempt to read NDEF data if available
      if (tag.ndefAvailable == true) {
        print('NDEF tag detected. Reading data...');
        try {
          // Read NDEF message
          var ndefRecords = await FlutterNfcKit.readNDEFRecords();

          if (ndefRecords.isNotEmpty) {
            // Process NDEF records to extract meaningful data
            String extractedData = _extractNdefData(ndefRecords);

            if (extractedData.isNotEmpty) {
              // If we have valid NDEF data, use it instead of serial number
              _ndefRecordData = extractedData.trim();
              cardIdentifier = _ndefRecordData!;

              print('Using NDEF record data as identifier: $_ndefRecordData');

              setState(() {
                _nfcStatus = 'Card with records detected!';
                _nfcData = 'Using record data: $_ndefRecordData';
              });
            }
          }
        } catch (e) {
          print('Error reading NDEF data: $e');
          // Fall back to using serial number if NDEF reading fails
        }
      }

      // Use the preferred identifier (NDEF record or serial)
      // Send card data to server immediately after detection
      await _enablecardwithnfc();

      setState(() {
        _nfcStatus = 'Card detected and saved!';
        _hideStartScanButton = true;
      });
    } catch (e) {
      setState(() {
        _nfcStatus = 'Try again';
        print('Error: ${e.toString()}');
      });
      print('Error reading NFC tag: $e');
    } finally {
      await FlutterNfcKit.finish();
      if (mounted) {
        setState(() {
          _isReading = false;
        });
      }
      print('NFC session finished');
    }
  }

  // New method to extract meaningful data from NDEF records
  String _extractNdefData(List<dynamic> records) {
    for (var record in records) {
      if (record.type == 'Text') {
        // Try to extract the text content from the record
        try {
          // For Text records, the payload typically starts with a language code
          if (record.payload != null && record.payload!.isNotEmpty) {
            // Get the language code length from the first byte
            int languageCodeLength = record.payload![0] & 0x3F;
            if (record.payload!.length > languageCodeLength + 1) {
              // Extract the actual text data, skipping the language code
              return String.fromCharCodes(
                  record.payload!.sublist(languageCodeLength + 1));
            }
          }
        } catch (e) {
          print('Error parsing text record: $e');
        }
      } else if (record.type == 'Uri') {
        // For URI records, return the URI content
        try {
          if (record.payload != null && record.payload!.isNotEmpty) {
            // URI records typically have a prefix byte followed by the URI
            return String.fromCharCodes(record.payload!.sublist(1));
          }
        } catch (e) {
          print('Error parsing URI record: $e');
        }
      } else {
        // For other record types, try to convert payload to string if possible
        try {
          if (record.payload != null && record.payload!.isNotEmpty) {
            return String.fromCharCodes(record.payload!);
          }
        } catch (e) {
          print('Error parsing record: $e');
        }
      }
    }
    return ''; // Return empty string if no useful data found
  }

  void _finishNfcSession() {
    FlutterNfcKit.finish().catchError((e) {
      // Ignore errors when finishing the session
      print('Error finishing NFC session: $e');
    });
  }

  // Clear saved card ID and reset to initial state
  Future<void> _resetCardData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cardId');

    setState(() {
      _savedCardId = null;
      _nfcStatus = 'Ready to scan';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Card data cleared'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _enablecardwithnfc() async {
    try {
      Map<String, dynamic> requestBody = {
        'card_no': _serialDecimalValue,
        'card_code': _ndefRecordData,
      };

      // Make the API call
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/car/command/update_card_info'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );
      print("%%%%%%%%%%%%%%%% $requestBody");
      final responseData = jsonDecode(response.body);
      print("&&&&&&&&&&&&&&& $responseData");
      if ((responseData['status'] == 200) ||
          (responseData['status'] == '200')) {
        // Parse the response
        final responseData = jsonDecode(response.body);
        print(responseData);

        setState(() {
          _nfcStatus = 'Card is updated!';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Card verified successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Handle error response
        setState(() {
          _showCardinfo = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${responseData['data']}'),
            backgroundColor: const Color(0xFFA50000),
          ),
        );
      }
    } catch (e) {
      setState(() {
        print('fffffffffffffffffff ${e.toString()}');
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification Error'),
          backgroundColor: const Color(0xFFA50000),
        ),
      );
    } finally {
      setState(() {
        // _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Removes the back button

        title: const Text(
          'Enable card',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400),
        ),
        backgroundColor: const Color(0xFFA50000),
        actions: [
          if (_hideStartScanButton)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _resetCardData,
              tooltip: 'Scan new card',
            ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                _nfcStatus,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _isReading ? const Color(0xFFA50000) : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.contactless,
                size: 150,
                color: _isReading
                    ? const Color(0xFFA50000)
                    : _hideStartScanButton
                        ? const Color(0xFFA50000)
                        : Colors.grey,
              ),
            ),
            if (_showCardinfo)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _cardinfo ? "Card is valid!" : "Card is invalid",
                  style: TextStyle(
                    fontSize: 18,
                    color: _cardinfo ? Colors.green : const Color(0xFFA50000),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
