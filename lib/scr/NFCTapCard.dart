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

class NFCScreen extends StatefulWidget {
  const NFCScreen({Key? key}) : super(key: key);

  @override
  State<NFCScreen> createState() => _NFCScreenState();
}

class _NFCScreenState extends State<NFCScreen> {
  bool _isReading = false;
  bool _isVerifying = false;
  String _nfcStatus = 'Ready to scan';
  String _nfcData = 'No data';
  String _serialDecimalValue = '1';
  String? _savedCardId;
  String? _cardnumber;
  bool _showPinInput = false;
  bool _hideStartScanButton = false;
  String? _clientName;
  bool _start = false;
  String? _card_codef;
  String? _card_type_name;
  String? _clientname;
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
    // _getCardInfo();
    _loadSavedCardId();
  }

  @override
  void dispose() {
    // Make sure to finish any NFC session when the screen is disposed
    _finishNfcSession();
    _textController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  // Load the saved card ID from SharedPreferences
  Future<void> _loadSavedCardId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedCardId = prefs.getString('cardId');
      if (_savedCardId != null) {
        _nfcStatus = 'Card ID loaded from storage';
        _nfcData = 'Saved Card ID: $_savedCardId';
        _showPinInput = true;
        _hideStartScanButton = true;
      }
    });
  }

  // Save card ID to SharedPreferences
  Future<void> _saveCardId(String serialDecimal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('serialDecimal', serialDecimal);
    setState(() {
      _savedCardId = serialDecimal;
      _showPinInput = true;
      _hideStartScanButton = true;
    });
    print('Card ID saved to SharedPreferences: $serialDecimal');
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
      _serialDecimalValue = cardIdentifier.trim();
      await _getCardInfo();

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
      _nfcData = 'No data';
      _showPinInput = false;
      _hideStartScanButton = false;
      _pinController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Card data cleared'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _getCardInfo() async {
    try {
      // First try using NDEF data if available
      if (_ndefRecordData != null && _ndefRecordData!.isNotEmpty) {
        print('Trying card verification with NDEF data first');
        Map<String, dynamic> ndefRequestBody = {
          'card_no': _ndefRecordData,       
           "serial_number": _serialDecimalValue,

        };

        final ndefResponse = await http.post(
          Uri.parse('${AppConfig.baseUrl}/api/card/command/verify'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(ndefRequestBody),
        );

        print("NDEF Request: $ndefRequestBody");
        final ndefResponseData = jsonDecode(ndefResponse.body);
        print("NDEF Response: $ndefResponseData");

        // If NDEF verification is successful
        if ((ndefResponseData['status'] == 200) ||
            (ndefResponseData['status'] == '200')) {
          _processSuccessResponse(ndefResponseData);
          return; // Exit the method as verification succeeded
        } else {
          print('NDEF verification failed, falling back to serial number');
          // Continue to try with serial number (falls through to next section)
        }
      }

      // Fall back to serial number verification
      String cardnum = _serialDecimalValue.trim();
      Map<String, dynamic> serialRequestBody = {
        'card_no': cardnum,
        "serial_number": _serialDecimalValue,
      };

      final serialResponse = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/card/command/verify'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(serialRequestBody),
      );

      print("Serial Request: $serialRequestBody");
      final serialResponseData = jsonDecode(serialResponse.body);
      print("Serial Response: $serialResponseData");

      if ((serialResponseData['status'] == 200) ||
          (serialResponseData['status'] == '200')) {
        _processSuccessResponse(serialResponseData);
      } else {
        // Handle error response
        setState(() {
          _showCardinfo = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${serialResponseData['data']}'),
            backgroundColor: const Color(0xFFA50000),
          ),
        );
      }
    } catch (e) {
      setState(() {
        print('Card verification error: ${e.toString()}');
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification Error'),
          backgroundColor: Color(0xFFA50000),
        ),
      );
    }
  }

  // Helper method to process successful verification responses
  void _processSuccessResponse(dynamic responseData) {
    _card_codef = responseData['data']['card_code'];
    _card_type_name = responseData['data']['card_type_name'];
    _clientname = responseData['data']['client_name'];

    setState(() {
      _nfcStatus = 'Card is Valid!';
      _showPinInput = true;
      _cardinfo = true;
      _showCardinfo = true;
      _hideStartScanButton = true;
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Card verified successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    // Save the card ID
    _saveCardId(_serialDecimalValue);
  }

  Future<void> _verifyCard() async {
    if (_pinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your PIN'),
          backgroundColor: Color(0xFFA50000),
        ),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
      _nfcStatus = 'Verifying card...';
    });

    try {
      // Use the trimmed card identifier (either from NDEF record or serial number)
      String cardnum = _serialDecimalValue.trim();

      Map<String, dynamic> requestBody = {
        'card_no': cardnum,
        'pin': _pinController.text,
      };

      // Make the API call
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/card/command/verify'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );
      final responseData = jsonDecode(response.body);
      print("&&&&&&&&&&&&&&&&& $requestBody");
      print("&&&&&&&&&&&&&&&&& $responseData");
      if ((responseData['status'] == 200) ||
          (responseData['status'] == '200')) {
        // Parse the response
        final responseData = jsonDecode(response.body);
        print(responseData);
        setState(() {
          _nfcStatus = 'Card verified successfully!';
        });

        final storage = FlutterSecureStorage();
        await storage.write(key: 'PIN', value: _pinController.text);
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Card verified successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => VerifyVehicleScreen(
            cardId: _serialDecimalValue,
            responseData: responseData,
          ),
        ));

        // You can navigate to another screen here if needed
      } else {
        // Handle error response
        setState(() {
          print('Verification failed:${responseData['message']}');
          _nfcStatus = 'Verification failed Try Gain';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Verification failed: ${responseData['message'] ?? "Unknown error"}'),
            backgroundColor: const Color(0xFFA50000),
          ),
        );
      }
    } catch (e) {
      setState(() {
        // _nfcStatus = 'Error during verification: ${e.toString()}';
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
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Removes the back button

        title: const Text(
          'NFC Reader',
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
      body: SingleChildScrollView(
        child: Center(
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
                  color: _isReading
                      ? const Color(0xFFA50000)
                      : _hideStartScanButton
                          ? const Color(0xFFA50000)
                          : Colors.grey,
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
              if (_showCardinfo) ...[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Client name : ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _cardinfo
                                  ? Text(
                                      _clientname.toString(),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'monospace',
                                      ),
                                    )
                                  : Text(
                                      ' Unknown',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'monospace',
                                      ),
                                    )
                            ]),
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Card type : ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _cardinfo
                                  ? Text(
                                      _card_type_name.toString(),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'monospace',
                                      ),
                                    )
                                  : Text(
                                      ' Invalid Card Type',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'monospace',
                                      ),
                                    )
                            ]),
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Card number : ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _cardinfo
                                  ? Text(
                                      _card_codef.toString(),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'monospace',
                                      ),
                                    )
                                  : Text(
                                      ' Invalid Card',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'monospace',
                                      ),
                                    )
                            ])
                      ],
                    ),
                  ),
                ),
              ],
              // Only show scan button if we don't have a card ID yet
              if (!_hideStartScanButton) ...[
                const SizedBox(height: 32),
                _start
                    ? ElevatedButton(
                        onPressed: _isReading ? null : _readNfcTag,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA50000),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _isReading ? 'Scanning...' : 'Start Scan',
                          style: const TextStyle(fontSize: 16),
                        ),
                      )
                    : Container(
                        child: Text(''),
                      )
              ],

              // PIN input field and verify button (shown after successful scan)
              if (_showPinInput) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enter Card PIN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _pinController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Enter PIN',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        maxLength: 6,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isVerifying ? null : _verifyCard,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA50000),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            _isVerifying ? 'Verifying...' : 'Verify Card',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
