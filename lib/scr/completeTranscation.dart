import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:ikwimpay/providers/globalapi.dart';
import 'package:ikwimpay/scr/platenumber1.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TransactionFormScreen extends StatefulWidget {
  final Map<String, dynamic> transactionData;
  final dynamic nozzleidCard;
  const TransactionFormScreen({
    Key? key,
    required this.nozzleidCard,
    required this.transactionData,
  }) : super(key: key);
  TransactionFormScreen.withData({super.key})
      : transactionData = {},
        nozzleidCard = {};

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _plateNoController = TextEditingController();
  final _formattedAmountController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  final _displayImageController = TextEditingController();
  bool _isPasswordVisible = false;

  // Class variables
  late String _nozzleidData;
  String? _qrCodeResult;
  String? _imagePath; // Store file path
  String? _base64Image; // Store the base64 image data

  // State tracking
  bool _isVerifying = false;
  bool _isNozzleVerified = false;
  bool _isVerificationInProgress = false;
  bool _isSubmitting = false;
  bool _isDirectPayment = false; // Add this flag

  // Cache SharedPreferences instance
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Initialize SharedPreferences once
    _prefs = await SharedPreferences.getInstance();

    // Load data and verify nozzle
    await _loadInitialData();
    _nozzleidData = widget.transactionData['nozzle']?.toString() ?? '';

    // Only verify if we have necessary data
    if (_qrCodeResult != null) {
      _initiateNozzleVerification();
    }
  }

  void _initiateNozzleVerification() {
    setState(() {
      _isNozzleVerified = false;
      _isVerificationInProgress = true;
    });

    // Perform verification in background
    _verifyNozzleQrcode();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      final url =
          Uri.parse('${AppConfig.baseUrl}/api/transaction/command/post');
      final transID = widget.transactionData['transID']?.toString() ?? '';

      // Skip image requirement for direct payment
      String imageData = '';
      if (_isDirectPayment) {
        imageData = '404.png'; // No image needed for direct payment
      } else {
        // Ensure we have the base64 image data for regular transactions
        if (_base64Image == null && _imagePath != null) {
          try {
            final bytes = await File(_imagePath!).readAsBytes();
            imageData = base64Encode(bytes);
          } catch (e) {
            print('Error converting image to base64: $e');
            imageData = '';
          }
        } else {
          imageData = _base64Image ?? '';
        }
      }

      final Map<String, String> requestBody = {
        'transID': transID,
        'amount': _formattedAmountController.text,
        'phone': _phoneController.text,
        'display': _isDirectPayment ? '1' : (_qrCodeResult?.toString() ?? ''),
        'image': imageData ?? '',
        'password': _passwordController.text,
      };

      try {
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(requestBody),
            )
            .timeout(const Duration(seconds: 15)); // Add timeout
        print('Transaction request body: $requestBody');

        final responseData = jsonDecode(response.body);
        print('Transaction response: $responseData');

        if (responseData['status'] == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction submitted successfully')),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${responseData['message']}')),
          );
        }
      } catch (e) {
        print("Network error:&&&&&&&&&&&&&&&& $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isVerifying = false;
            _isSubmitting = false;
          });
        }
      }
    }
  }

  Future<void> _handleScanResult() async {
    try {
      final cameras = await availableCameras();
      final firstCamera = cameras.first;

      if (!mounted) return;
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TakePictureScreenFrame(
            camera: firstCamera,
            transactionData: widget.transactionData,
          ),
        ),
      );

      // Check if result is not null and has the expected structure
      if (result != null && mounted) {
        // Store QR code result and image data
        setState(() {
          _qrCodeResult = result['qrCode'];
          _base64Image = result['base64Image']; // Store the base64 directly
          _imagePath = result['imagePath']; // Also store path for backup

          // Update display controller with a placeholder text
          _displayImageController.text = 'Image captured';
        });

        // Verify the QR code only if we have a result
        if (_qrCodeResult != null) {
          _verifyNozzleQrcode();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accessing camera: $e')),
        );
      }
    }
  }

  Future<void> _verifyNozzleQrcode() async {
    if (_qrCodeResult == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please scan QR code first')),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isNozzleVerified = false;
        _isVerificationInProgress = true;
      });
    }

    final url = Uri.parse('${AppConfig.baseUrl}/api/nozzle/command/verify');

    final Map<String, String> requestBody = {
      'nozzle': _nozzleidData,
    };

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      final responseData = jsonDecode(response.body);

      if (!mounted) return;

      if (responseData['status'] == 200) {
        // Extract the disp_test value
        dynamic dispTest = responseData['data']['disp_test'];

        // Validate QR code
        bool isQrCodeValid = _qrCodeResult != null &&
            dispTest != null &&
            (dispTest.toString()) == _qrCodeResult;

        setState(() {
          _isNozzleVerified = isQrCodeValid;
          _isVerificationInProgress = false;
        });

        if (isQrCodeValid) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verified successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('QR Code does not match')),
          );
        }
      } else {
        setState(() {
          _isNozzleVerified = false;
          _isVerificationInProgress = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Error: ${responseData['message'] ?? "Unknown error"}')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isNozzleVerified = false;
          _isVerificationInProgress = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection error. Please try again.')),
        );
      }
    }
  }

  Future<void> _loadInitialData() async {
    if (_prefs == null) return;

    // Pre-fill form with existing data
    _formattedAmountController.text =
        widget.transactionData['formatted_amount'] ?? '';

    // Get plate number from SharedPreferences
    try {
      final plateNumber = _prefs!.getString('plate_number');
      final plateFromTransaction =
          widget.transactionData['plate_no'] ?? plateNumber ?? '';

      // Check if this is a direct payment transaction - handle both cases with capitalization
      _isDirectPayment = plateFromTransaction == "Direct Payment" ||
          plateFromTransaction == "Direct payment";

      if (_isDirectPayment) {
        // No need for QR verification for direct payment
        setState(() {
          _isNozzleVerified = true;
          // Set a default value for the image field to pass validation
          _displayImageController.text = '404.png';
        });
      }

      if (mounted) {
        setState(() {
          _plateNoController.text = plateFromTransaction;
        });
      }
    } catch (e) {
      print('Error loading plate number from SharedPreferences: $e');
    }
  }

  @override
  void dispose() {
    // Dispose controllers
    _plateNoController.dispose();
    _formattedAmountController.dispose();
    _passwordController.dispose();
    _displayImageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Complete Transaction',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: const Color(0xFFA50000),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.all(15.0),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPlateNumberField(),

                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone number',
                        hint: 'Enter Phone numbe',
                        obscureTexts: false,
                        keyboardType: TextInputType.text,
                      ),

                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Enter Password',
                        obscureTexts:
                            !_isPasswordVisible, // Use the visibility flag here
                        keyboardType: TextInputType.text,
                        isPassword: true, // Add this parameter
                      ),
                      _buildTextField(
                        controller: _formattedAmountController,
                        label: 'Amount',
                        hint: 'Enter amount',
                        obscureTexts: false,
                        keyboardType: TextInputType.number,
                      ),
                      if (!_isDirectPayment) // Only show the image field if not direct payment
                        _buildTextFieldDisplay(
                          controller: _displayImageController,
                          label: 'Image',
                          hint: 'Image',
                          keyboardType: TextInputType.url,
                        ),
                      const SizedBox(height: 24),

                      // Show verification status with optimized UI
                      if (_isVerificationInProgress)
                        const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFA50000),
                          ),
                        )
                      else if (_isNozzleVerified || _isDirectPayment)
                        _buildSubmitButton()
                      else
                        _buildScanButton(),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFA50000),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : const Text(
                'Submit',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildScanButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleScanResult,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Scan QR Code',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildPlateNumberField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _plateNoController,
            readOnly: true,
            enabled: false,
            decoration: InputDecoration(
              labelText: 'Plate Number',
              hintText: 'Auto-filled plate number',
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              suffixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
              fillColor: Colors.grey.shade100,
              filled: true,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Plate Number is required';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextFieldDisplay(
      {required TextEditingController controller,
      required String label,
      required String hint,
      TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: true,
      style: const TextStyle(
          color: Colors.black38, fontWeight: FontWeight.w400, fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Path of display',
        hintText: 'Path of display',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.camera_alt),
          onPressed: _handleScanResult,
          tooltip: 'Scan QR code with camera',
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please scan QR code';
        }
        return null;
      },
    );
  }

  // Widget _buildTextField({
  //   required TextEditingController controller,
  //   required String label,
  //   required String hint,
  //   required bool obscureTexts,
  //   TextInputType keyboardType = TextInputType.text,
  // }) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 16),
  //     child: TextFormField(
  //       controller: controller,
  //       keyboardType: keyboardType,
  //       obscureText: obscureTexts,
  //       decoration: InputDecoration(
  //         labelText: label,
  //         hintText: hint,
  //         hintStyle: const TextStyle(
  //             color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 14),
  //         border: OutlineInputBorder(
  //           borderRadius: BorderRadius.circular(8),
  //         ),
  //         errorStyle: const TextStyle(
  //             color: Colors.redAccent,
  //             fontWeight: FontWeight.w400,
  //             fontSize: 10),
  //       ),
  //       validator: (value) {
  //         if (value == null || value.isEmpty) {
  //           return 'Please enter $label';
  //         }
  //         return null;
  //       },
  //     ),
  //   );
  // }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureTexts,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureTexts,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: const TextStyle(
              color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          errorStyle: const TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.w400,
              fontSize: 10),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    // color: const Color(0xFFA50000),
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                )
              : null,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }
}
