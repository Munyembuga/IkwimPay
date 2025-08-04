import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';

class PaymentScreen extends StatefulWidget {
  final String paymentType;

  const PaymentScreen({Key? key, required this.paymentType}) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _tinController = TextEditingController();
  final TextEditingController _purchaseCodeController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  String? _selectedProduct;
  String _selectedOption = 'TIN';

  final List<String> _products = ['AGO', 'Essence', 'Diesel', 'Kerosene'];

  @override
  void dispose() {
    _amountController.dispose();
    _plateController.dispose();
    _tinController.dispose();
    _purchaseCodeController.dispose();
    _telephoneController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.paymentType} Payment'),
        backgroundColor: const Color(0xFF870813),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment Type Header
              // Container(
              //   width: double.infinity,
              //   padding: const EdgeInsets.all(16.0),
              //   decoration: BoxDecoration(
              //     gradient: const LinearGradient(
              //       colors: [Color(0xFF870813), Color(0xFFB91C1C)],
              //       begin: Alignment.centerLeft,
              //       end: Alignment.centerRight,
              //     ),
              //     borderRadius: BorderRadius.circular(12),
              //   ),
              //   child: Row(
              //     children: [
              //       Icon(
              //         widget.paymentType == 'Cash Payment'
              //             ? Icons.money
              //             : Icons.phone_android,
              //         color: Colors.white,
              //         size: 24,
              //       ),
              //       const SizedBox(width: 12),
              //       Text(
              //         widget.paymentType,
              //         style: const TextStyle(
              //           color: Colors.white,
              //           fontSize: 20,
              //           fontWeight: FontWeight.bold,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              const SizedBox(height: 24),

              // Product Dropdown Search
              _buildSectionTitle('Select Product'),
              const SizedBox(height: 8),
              DropdownSearch<String>(
                popupProps: const PopupProps.menu(
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    decoration: InputDecoration(
                      hintText: "Search product...",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                items: (filter, infiniteScrollProps) async {
                  return _products;
                },
                decoratorProps: DropDownDecoratorProps(
                  decoration: InputDecoration(
                    hintText: "Choose Product",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF870813)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedProduct = newValue;
                  });
                },
                selectedItem: _selectedProduct,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a product';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Plate Number Field
              _buildSectionTitle('Plate Number'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _plateController,
                decoration: _buildInputDecoration('Enter Plate Number'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter plate number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Amount Field
              _buildSectionTitle('Amount'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                decoration: _buildInputDecoration('Enter Amount'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Radio Button Section
              _buildSectionTitle('Payment Method'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('TIN'),
                        value: 'TIN',
                        groupValue: _selectedOption,
                        activeColor: const Color(0xFF870813),
                        onChanged: (String? value) {
                          setState(() {
                            _selectedOption = value!;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Phone'),
                        value: 'Phone',
                        groupValue: _selectedOption,
                        activeColor: const Color(0xFF870813),
                        onChanged: (String? value) {
                          setState(() {
                            _selectedOption = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Conditional Fields
              if (_selectedOption == 'TIN') ...[
                _buildSectionTitle('TIN Details'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _tinController,
                  decoration: _buildInputDecoration('Enter TIN'),
                  validator: (value) {
                    if (_selectedOption == 'TIN' &&
                        (value == null || value.isEmpty)) {
                      return 'Please enter TIN';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: _buildInputDecoration('Enter Name Or Company'),
                  validator: (value) {
                    if (_selectedOption == 'TIN' &&
                        (value == null || value.isEmpty)) {
                      return 'Please enter Name Or Company';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _purchaseCodeController,
                  decoration: _buildInputDecoration('Enter Purchase Code'),
                  validator: (value) {
                    if (_selectedOption == 'TIN' &&
                        (value == null || value.isEmpty)) {
                      return 'Please enter purchase code';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telephoneController,
                  decoration: _buildInputDecoration('Enter Telephone'),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (_selectedOption == 'TIN' &&
                        (value == null || value.isEmpty)) {
                      return 'Please enter telephone number';
                    }
                    return null;
                  },
                ),
              ] else if (_selectedOption == 'Phone') ...[
                _buildSectionTitle('Phone Details'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  decoration: _buildInputDecoration('Enter Phone Number'),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (_selectedOption == 'Phone' &&
                        (value == null || value.isEmpty)) {
                      return 'Please enter phone number';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF870813),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Process Payment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF870813),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF870813)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  void _submitPayment() {
    if (_formKey.currentState!.validate()) {
      // Process payment logic here
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Payment Confirmation'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Payment Type: ${widget.paymentType}'),
                Text('Product: $_selectedProduct'),
                Text('Amount: ${_amountController.text}'),
                Text('Plate Number: ${_plateController.text}'),
                Text('Method: $_selectedOption'),
                if (_selectedOption == 'TIN') ...[
                  Text('TIN: ${_tinController.text}'),
                  Text('Purchase Code: ${_purchaseCodeController.text}'),
                  Text('Telephone: ${_telephoneController.text}'),
                ] else if (_selectedOption == 'Phone') ...[
                  Text('Phone: ${_phoneController.text}'),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Payment processed successfully!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF870813),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );
    }
  }
}
