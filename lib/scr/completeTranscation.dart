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

  // Add new variables for payment modes
  List<Map<String, dynamic>> paymentModes = [];
  Map<String, dynamic>? selectedPaymentMode;
  bool isLoyaltyCard = false;
  double cardBalance = 0.0;
  double transactionAmount = 0.0;
  String cardTypeName = '';

  @override
  void initState() {
    super.initState();
    _initializeData();
    _checkCardType();
    _formattedAmountController.addListener(_updateTransactionAmount);
  }

  void _updateTransactionAmount() {
    final enteredAmount =
        double.tryParse(_formattedAmountController.text) ?? 0.0;
    setState(() {
      transactionAmount = enteredAmount;
    });
  }

  void _checkCardType() {
    // Check if this is a loyalty card transaction
    final cardType = widget.transactionData['card_type'];
    final balance = widget.transactionData['balance'] ?? 0;
    final formattedAmount = widget.transactionData['formatted_amount'] ?? '0';

    setState(() {
      isLoyaltyCard = cardType == 4;
      cardBalance = double.tryParse(balance.toString()) ?? 0.0;
      transactionAmount = double.tryParse(formattedAmount.toString()) ?? 0.0;
      cardTypeName = widget.transactionData['card_type_name'] ?? '';
    });

    if (isLoyaltyCard) {
      _fetchPaymentModes();
    }
  }

  Future<void> _fetchPaymentModes() async {
    try {
      final response = await http.get(
        Uri.parse('https://mis.ikwim.com/api/transaction/command/pay'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 200) {
          setState(() {
            paymentModes =
                List<Map<String, dynamic>>.from(responseData['data']);
          });
        }
      }
    } catch (e) {
      print('Error fetching payment modes: $e');
    }
  }

  void _showPaymentModeBottomSheet() {
    final remainingAmount = transactionAmount - cardBalance;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  const Text(
                    'Payment Mode Selection',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF870813),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Balance and Amount Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Card Type: $cardTypeName',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF870813),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Card Balance:',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              '${cardBalance.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Transaction Amount:',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              '${transactionAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Remaining Amount:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                              ),
                            ),
                            Text(
                              '${remainingAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Payment modes list
                  const Text(
                    'Choose Payment Mode for Remaining Amount:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: paymentModes.length,
                      itemBuilder: (context, index) {
                        final paymentMode = paymentModes[index];
                        final isSelected = selectedPaymentMode?['acc_id'] ==
                            paymentMode['acc_id'];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF870813)
                                  : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: isSelected
                                ? const Color(0xFF870813).withOpacity(0.1)
                                : null,
                          ),
                          child: RadioListTile<Map<String, dynamic>>(
                            title: Text(
                              paymentMode['acc_mode'],
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color:
                                    isSelected ? const Color(0xFF870813) : null,
                              ),
                            ),
                            value: paymentMode,
                            groupValue: selectedPaymentMode,
                            activeColor: const Color(0xFF870813),
                            onChanged: (value) {
                              setModalState(() {
                                selectedPaymentMode = value;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: selectedPaymentMode != null
                              ? () {
                                  Navigator.of(context).pop();
                                  _submitFormWithPaymentMode();
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA50000),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Confirm Payment'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Check if it's a loyalty card with insufficient balance
      if (isLoyaltyCard && transactionAmount > cardBalance) {
        _showPaymentModeBottomSheet();
        return;
      }

      _performSubmission();
    }
  }

  Future<void> _submitFormWithPaymentMode() async {
    _performSubmission();
  }

  Future<void> _performSubmission() async {
    setState(() {
      _isSubmitting = true;
    });

    final url = Uri.parse('${AppConfig.baseUrl}/api/transaction/command/post');
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

    final Map<String, dynamic> requestBody = {
      'transID': transID,
      'amount': _formattedAmountController.text,
      'phone': _phoneController.text,
      'display': _isDirectPayment ? '1' : (_qrCodeResult?.toString() ?? ''),
      'image': imageData ?? '',
      'password': _passwordController.text,
    };

    // Add payment mode if selected for loyalty cards
    if (isLoyaltyCard && selectedPaymentMode != null) {
      requestBody['payment_mode_id'] = selectedPaymentMode!['acc_id'];
    }

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
          _isSubmitting = false;
        });
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

  @override
  void dispose() {
    _formattedAmountController.removeListener(_updateTransactionAmount);
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
                      // Show card type info for loyalty cards
                      if (isLoyaltyCard) _buildLoyaltyCardInfo(),

                      _buildPlateNumberField(),

                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone number',
                        hint: 'Enter Phone number',
                        obscureTexts: false,
                        keyboardType: TextInputType.text,
                      ),

                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Enter Password',
                        obscureTexts: !_isPasswordVisible,
                        keyboardType: TextInputType.text,
                        isPassword: true,
                      ),

                      _buildTextField(
                        controller: _formattedAmountController,
                        label: 'Amount',
                        hint: 'Enter amount',
                        obscureTexts: false,
                        keyboardType: TextInputType.number,
                      ),

                      if (!_isDirectPayment)
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

  Widget _buildLoyaltyCardInfo() {
    final remainingAmount = transactionAmount - cardBalance;
    final hasInsufficientBalance = remainingAmount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasInsufficientBalance ? Colors.orange[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: hasInsufficientBalance
                ? Colors.orange[300]!
                : Colors.green[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasInsufficientBalance ? Icons.warning : Icons.credit_card,
                color: hasInsufficientBalance
                    ? Colors.orange[700]
                    : Colors.green[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                cardTypeName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: hasInsufficientBalance
                      ? Colors.orange[700]
                      : Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Card Balance:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '${cardBalance.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transaction Amount:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '${transactionAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (hasInsufficientBalance) ...[
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Additional Payment Required:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
                Text(
                  '${remainingAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
