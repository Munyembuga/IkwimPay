import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:ikwimpay/scr/matchCard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

// Screen to capture pictures
class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;
  final Map<String, dynamic>? transactionData;

  const TakePictureScreen({
    super.key,
    required this.camera,
    this.transactionData,
  });
  const TakePictureScreen.withoutTransaction({
    super.key,
    required this.camera,
  }) : transactionData = null;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  final TextRecognizer _textRecognizer = TextRecognizer();
  // Updated regex to match multiple license plate formats
  final RegExp _plateRegex = RegExp(
      r'([A-Z]{3}\d{3}[A-Z]{1})|([A-Z]{2}\d{3}[A-Z]{2})|([A-Z]{2}\d{3}[A-Z]{1})');
  bool _isProcessing = false;
  bool _isFlashOn = false; // Track flash state
  final TextEditingController _manualPlateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.high);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    _textRecognizer.close();
    _manualPlateController.dispose();
    super.dispose();
  }

  // Toggle flash functionality
  Future<void> _toggleFlash() async {
    try {
      if (_isFlashOn) {
        await _controller.setFlashMode(FlashMode.off);
      } else {
        await _controller.setFlashMode(FlashMode.torch);
      }
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error toggling flash: $e')),
      );
    }
  }

  // Convert image file to base64 string
  Future<String> _convertImageToBase64(String imagePath) async {
    final File imageFile = File(imagePath);
    List<int> imageBytes = await imageFile.readAsBytes();
    String base64Image = base64Encode(imageBytes);
    return base64Image;
  }

  Future<void> _takePicture(BuildContext context) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();

      if (!context.mounted) return;

      // Process the image directly
      await _processImage(image.path, context);
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _processImage(String imagePath, BuildContext context) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Look for plate number pattern in recognized text
      String detectedPlate = '';
      print("========== ALL RECOGNIZED TEXT ==========");
      print("Full text: ${recognizedText.text}");

      // Print detailed breakdown of recognized text
      print("\n--------- TEXT BLOCKS BREAKDOWN ---------");
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          final text = line.text.replaceAll(' ', '').toUpperCase();
          final matches = _plateRegex.allMatches(text);

          for (Match match in matches) {
            detectedPlate = match.group(0) ?? '';
            if (detectedPlate.isNotEmpty) break;
          }

          if (detectedPlate.isNotEmpty) break;
        }
        if (detectedPlate.isNotEmpty) break;
      }

      if (!context.mounted) return;

      if (detectedPlate.isNotEmpty) {
        // Valid plate detected, save and navigate
        await _savePlateAndNavigate(context, detectedPlate, imagePath);
      } else {
        // No plate detected, show modal for manual input
        setState(() {
          _isProcessing = false;
        });
        _showManualInputModal(context, imagePath);
      }
    } catch (e) {
      if (!context.mounted) return;
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing image: $e')),
      );
    }
  }

  // Show modal bottom sheet for manual plate input
  void _showManualInputModal(BuildContext context, String imagePath) {
    _manualPlateController.text = ''; // Clear previous input

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'No valid license plate detected',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Display the captured image
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: FileImage(File(imagePath)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Please enter the license plate number manually:',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _manualPlateController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Example: ABC123D',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                style: const TextStyle(fontSize: 16),
                onChanged: (value) {
                  // Convert input to uppercase
                  final newValue = value.toUpperCase();
                  if (value != newValue) {
                    _manualPlateController.value =
                        _manualPlateController.value.copyWith(
                      text: newValue,
                      selection:
                          TextSelection.collapsed(offset: newValue.length),
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFA50000)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Color(0xFFA50000)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      // Inside the _showManualInputModal method, replace the Submit button's onPressed handler:
                      onPressed: () async {
                        final plateNumber = _manualPlateController.text.trim();
                        if (plateNumber.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Please enter a license plate number'),
                            ),
                          );
                          return;
                        }

                        try {
                          // Process the image
                          final String base64Image =
                              await _convertImageToBase64(imagePath);

                          // Save to SharedPreferences
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('plateNumber', plateNumber);
                          await prefs.setString('base64Image', base64Image);

                          // First dismiss the modal bottom sheet
                          Navigator.pop(context);

                          // Then navigate back to VerifyVehicleScreen with the data
                          if (context.mounted) {
                            Navigator.of(context)
                                .pop(); // This returns to VerifyVehicleScreen
                          }
                        } catch (e) {
                          print('Error processing plate data: $e');
                          // First dismiss the modal
                          Navigator.pop(context);
                          // Then navigate back to VerifyVehicleScreen
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA50000),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Submit',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Try Again',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _savePlateAndNavigate(
      BuildContext context, String plateNumber, String imagePath) async {
    try {
      setState(() {
        _isProcessing = true;
      });

      // Convert image to base64
      final String base64Image = await _convertImageToBase64(imagePath);

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('plateNumber', plateNumber);
      await prefs.setString('base64Image', base64Image);

      // Create updated transaction data
      final updatedData =
          Map<String, dynamic>.from(widget.transactionData ?? {});
      updatedData['plate_no'] = plateNumber;
      updatedData['imagePath'] = imagePath;
      updatedData['base64Image'] = base64Image;

      setState(() {
        _isProcessing = false;
      });

      if (!context.mounted) return;

      // Navigate to transaction form screen
      Navigator.of(context).pop(updatedData);
    } catch (e) {
      if (!context.mounted) return;
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFA50000),
        title: const Text(
          'Scan License Plate',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400),
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
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CameraPreview(_controller),
                          // Flash toggle button
                          Positioned(
                            left: 20,
                            top: 20,
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                icon: Icon(
                                  _isFlashOn ? Icons.flash_on : Icons.flash_off,
                                  color: Colors.white,
                                ),
                                onPressed: _toggleFlash,
                              ),
                            ),
                          ),
                          // Overlay to guide the license plate placement
                          Container(
                            width: MediaQuery.of(context).size.width * 0.8,
                            height: 100,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.black54,
                      width: double.infinity,
                      child: const Text(
                        'Position the license plate in the frame and take a picture\nFormat: ABC123D',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                // Loading overlay
                if (_isProcessing)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 20),
                          Text(
                            'Processing license plate...',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: _isProcessing
          ? null
          : FloatingActionButton(
              onPressed: () => _takePicture(context),
              backgroundColor: const Color(0xFFA50000),
              child: const Icon(Icons.camera_alt, color: Colors.white),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
