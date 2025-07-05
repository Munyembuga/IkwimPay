import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:ikwimpay/providers/auth_provider.dart';
import 'package:provider/provider.dart';
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
  int? _userRole;
  // Updated regex to match multiple license plate formats including RE 007X
  final RegExp _plateRegex = RegExp(
      r'([A-Z]{2}\s?\d{3}[A-Z])|([A-Z]{3}\s?\d{3}[A-Z])|([A-Z]{2}\s?\d{3}[A-Z]{2})|([A-Z0-9]{3}\d{0,3}[A-Z0-9]{1})|([A-Z0-9]{2}\d{0,3}[A-Z0-9]{2})|([A-Z0-9]{2}\d{0,3}[A-Z0-9]{1})');

  // Enhanced character correction maps based on position and format knowledge
  final Map<String, String> _letterCorrections = {
    '0': 'O',
    '1': 'I',
    '2': 'Z',
    '5': 'S',
    '8': 'B',
    '6': 'G',
    '4': 'A',
    '7': 'T',
    '9': 'P',
  };

  final Map<String, String> _numberCorrections = {
    'O': '0',
    'I': '1',
    'L': '1',
    'Z': '2',
    'S': '5',
    'B': '8',
    // 'G': '6',
    'D': '0',
    'Q': '0',
    'T': '7',
    // 'A': '4',
    // 'P': '9',
  };

  // Position-specific corrections
  final Map<int, Map<String, String>> _positionSpecificCorrections = {
    0: {'0': 'O', '1': 'I', '8': 'B'}, // First position
    1: {'0': 'O', '1': 'I', '5': 'S'}, // Second position
    6: {'0': 'O', '1': 'I', '5': 'S'}, // Last position in 7-char plate
    5: {'0': 'O', '1': 'I', '8': 'B'}, // Last position in 6-char plate
  };

  bool _isProcessing = false;
  bool _isFlashOn = false; // Track flash state
  final TextEditingController _manualPlateController = TextEditingController();

  // Confidence tracking for matches
  double _plateConfidence = 0.0;
  List<Map<String, dynamic>> _potentialMatchesWithScore = [];

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.user?.role;
    _userRole = userRole;
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

  // Enhanced function to apply format-specific corrections to detected text
  String _applyFormatCorrections(String text) {
    if (text.isEmpty) return text;

    // Standardize text: handle spaces and make uppercase
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim().toUpperCase();
    String noSpaceText = text.replaceAll(' ', '');

    _potentialMatchesWithScore.clear();
    String correctedText = '';
    double confidence = 0.0;

    // Format 1: "RE 007X" - 2 letters + space + 3 digits + 1 letter
    if ((text.length >= 6 && text.length <= 8) || (noSpaceText.length == 6)) {
      String workingText = noSpaceText;
      if (workingText.length == 6 &&
          RegExp(r'^[A-Z0-9]{2}[0-9A-Z]{3}[A-Z0-9]{1}$')
              .hasMatch(workingText)) {
        String format1Text = '';
        double format1Confidence = 0.9; // High confidence for RE 007X format

        for (int i = 0; i < workingText.length; i++) {
          String char = workingText[i];

          if (i < 2) {
            // First 2 should be letters (RE)
            if (RegExp(r'[0-9]').hasMatch(char)) {
              char = _letterCorrections[char] ?? char;
              format1Confidence -= 0.1;
            } else {
              format1Confidence += 0.05;
            }
          } else if (i >= 2 && i < 5) {
            // Middle 3 should be numbers (007)
            if (RegExp(r'[A-Z]').hasMatch(char)) {
              char = _numberCorrections[char] ?? char;
              format1Confidence -= 0.1;
            } else {
              format1Confidence += 0.05;
            }
          } else {
            // Last one should be letter (X)
            if (RegExp(r'[0-9]').hasMatch(char)) {
              char = _letterCorrections[char] ?? char;
              format1Confidence -= 0.1;
            } else {
              format1Confidence += 0.05;
            }
          }

          format1Text += char; // No space added here
        }

        _potentialMatchesWithScore.add({
          'text': format1Text,
          'confidence': format1Confidence,
          'format': 'RE007X'
        });

        if (format1Confidence > confidence) {
          correctedText = format1Text;
          confidence = format1Confidence;
        }
      }
    }

    // Format 2: ABC123D - 3 letters + 3 numbers + 1 letter
    if (noSpaceText.length == 7 &&
        RegExp(r'^[A-Z0-9]{3}[A-Z0-9]{3}[A-Z0-9]{1}$').hasMatch(noSpaceText)) {
      correctedText = '';
      confidence = 0.7; // Base confidence for matching length and pattern

      for (int i = 0; i < noSpaceText.length; i++) {
        String char = noSpaceText[i];
        // Apply position-specific corrections first
        if (_positionSpecificCorrections.containsKey(i) &&
            _positionSpecificCorrections[i]!.containsKey(char)) {
          char = _positionSpecificCorrections[i]![char]!;
          confidence +=
              0.05; // Boost confidence for position-specific correction
        }

        if (i < 3) {
          // First 3 should be letters
          if (RegExp(r'[0-9]').hasMatch(char)) {
            char = _letterCorrections[char] ?? char;
            confidence -= 0.02; // Penalty for needed correction
          } else {
            confidence += 0.02; // Boost for correct character type
          }
        } else if (i >= 3 && i < 6) {
          // Middle 3 should be numbers
          if (RegExp(r'[A-Z]').hasMatch(char)) {
            char = _numberCorrections[char] ?? char;
            confidence -= 0.02; // Penalty for needed correction
          } else {
            confidence += 0.02; // Boost for correct character type
          }
        } else {
          // Last one should be letter
          if (RegExp(r'[0-9]').hasMatch(char)) {
            char = _letterCorrections[char] ?? char;
            confidence -= 0.02; // Penalty for needed correction
          } else {
            confidence += 0.02; // Boost for correct character type
          }
        }
        correctedText += char;
      }

      // Store this candidate with its confidence score
      _potentialMatchesWithScore.add({
        'text': correctedText,
        'confidence': confidence,
        'format': 'ABC123D'
      });
    }

    // Format 3: AB123CD - 2 letters + 3 numbers + 2 letters
    if (noSpaceText.length == 7 &&
        RegExp(r'^[A-Z0-9]{2}[A-Z0-9]{3}[A-Z0-9]{2}$').hasMatch(noSpaceText)) {
      String format2Text = '';
      double format2Confidence = 0.7;

      for (int i = 0; i < noSpaceText.length; i++) {
        String char = noSpaceText[i];
        // Apply position-specific corrections
        if (_positionSpecificCorrections.containsKey(i) &&
            _positionSpecificCorrections[i]!.containsKey(char)) {
          char = _positionSpecificCorrections[i]![char]!;
          format2Confidence += 0.05;
        }

        if (i < 2 || i >= 5) {
          // First 2 and last 2 should be letters
          if (RegExp(r'[0-9]').hasMatch(char)) {
            char = _letterCorrections[char] ?? char;
            format2Confidence -= 0.02;
          } else {
            format2Confidence += 0.02;
          }
        } else {
          // Middle 3 should be numbers
          if (RegExp(r'[A-Z]').hasMatch(char)) {
            char = _numberCorrections[char] ?? char;
            format2Confidence -= 0.02;
          } else {
            format2Confidence += 0.02;
          }
        }
        format2Text += char;
      }

      _potentialMatchesWithScore.add({
        'text': format2Text,
        'confidence': format2Confidence,
        'format': 'AB123CD'
      });

      // If this format has higher confidence, use it
      if (format2Confidence > confidence) {
        correctedText = format2Text;
        confidence = format2Confidence;
      }
    }

    // Select the best match from all potential matches
    if (_potentialMatchesWithScore.isNotEmpty) {
      _potentialMatchesWithScore
          .sort((a, b) => b['confidence'].compareTo(a['confidence']));
      correctedText = _potentialMatchesWithScore.first['text'];
      confidence = _potentialMatchesWithScore.first['confidence'];
    }

    _plateConfidence = confidence;
    return correctedText;
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

      // Reset potential matches
      _potentialMatchesWithScore = [];

      // Look for plate number pattern in recognized text
      String detectedPlate = '';
      List<String> potentialPlates = [];

      print("========== ALL RECOGNIZED TEXT ==========");
      print("Full text: ${recognizedText.text}");

      // Print detailed breakdown of recognized text
      print("\n--------- TEXT BLOCKS BREAKDOWN ---------");

      // Special handling for two-line plates like "RE 007X"
      List<String> allLines = [];

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          String lineText = line.text.trim().toUpperCase();
          allLines.add(lineText);
          print("Text line: $lineText");
        }
      }

      // Try to combine lines for two-line plate format (RE on top, 007X on bottom)
      for (int i = 0; i < allLines.length - 1; i++) {
        String line1 = allLines[i].replaceAll(' ', '');
        String line2 = allLines[i + 1].replaceAll(' ', '');

        // Check if first line has 2 letters and second line has 3 digits + 1 letter
        if (RegExp(r'^[A-Z]{2}$').hasMatch(line1) &&
            RegExp(r'^[0-9]{3}[A-Z]$').hasMatch(line2)) {
          String combinedText = line1 + line2; // RE007X
          print("Combined two-line plate: $combinedText");
          potentialPlates.add(combinedText);
          break;
        }
      }

      // Also process individual lines and full text
      String fullTextNoSpaces =
          recognizedText.text.replaceAll(RegExp(r'\s+'), '').toUpperCase();
      potentialPlates.add(fullTextNoSpaces);

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          final text = line.text.replaceAll(' ', '').toUpperCase();

          // Pre-processing: Try applying corrections before regex matching
          final correctedText = _applyFormatCorrections(text);
          print(
              "Corrected text: $correctedText (confidence: ${_plateConfidence.toStringAsFixed(2)})");

          // Add both original and corrected text to potential plates
          potentialPlates.add(text);
          if (text != correctedText) {
            potentialPlates.add(correctedText);
          }
        }
      }

      // Check for matches in all potential plates
      for (String plateText in potentialPlates) {
        final matches = _plateRegex.allMatches(plateText);
        for (Match match in matches) {
          String candidate = match.group(0) ?? '';
          if (candidate.isNotEmpty) {
            // Apply format correction and remove all spaces
            detectedPlate =
                _applyFormatCorrections(candidate).replaceAll(' ', '');
            print(
                "Detected plate: $detectedPlate (confidence: ${_plateConfidence.toStringAsFixed(2)})");

            // Debug information about all potential matches
            print("\nAll potential matches:");
            _potentialMatchesWithScore
                .sort((a, b) => b['confidence'].compareTo(a['confidence']));
            for (var match in _potentialMatchesWithScore) {
              print(
                  "${match['text']} - Format: ${match['format']} - Confidence: ${match['confidence'].toStringAsFixed(2)}");
            }
            break;
          }
        }
        if (detectedPlate.isNotEmpty) break;
      }

      if (!context.mounted) return;

      if (detectedPlate.isNotEmpty) {
        // Valid plate detected, save and navigate
        await _savePlateAndNavigate(context, detectedPlate, imagePath);
      } else {
        // No plate detected
        setState(() {
          _isProcessing = false;
        });

        // Only show manual input modal if user role is not 6
        if (_userRole != 6) {
          _showManualInputModal(context, imagePath);
        } else {
          // For role 6, just show a message and don't offer manual input
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No license plate detected. Please try again.'),
              backgroundColor: Color(0xFFA50000),
            ),
          );
        }
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

      // Remove all spaces from plate number before saving
      String cleanPlateNumber = plateNumber.replaceAll(' ', '');

      // Convert image to base64
      final String base64Image = await _convertImageToBase64(imagePath);

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('plateNumber', cleanPlateNumber);
      await prefs.setString('base64Image', base64Image);

      // Create updated transaction data
      final updatedData =
          Map<String, dynamic>.from(widget.transactionData ?? {});
      updatedData['plate_no'] = cleanPlateNumber;
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
