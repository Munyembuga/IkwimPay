import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ikwimpay/providers/auth_provider.dart';
import 'package:ikwimpay/providers/globalapi.dart';
import 'package:ikwimpay/scr/cardViewPump.dart';
import 'package:ikwimpay/scr/userProfile';
import 'package:ikwimpay/scr/paymentScreen.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class Firstscreen extends StatefulWidget {
  final Function(int)? onTabChange;

  const Firstscreen({Key? key, this.onTabChange}) : super(key: key);

  @override
  _FirstscreenState createState() => _FirstscreenState();
}

class _FirstscreenState extends State<Firstscreen> {
  List<dynamic> pump = [];
  bool isLoading = false;
  int? _userRole;
  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final userSite = authProvider.user?.siteId;
    print("&&&&&&&&&&&&&&& $userSite");
    // Fetch nozzles when the screen initializes
    fetchNozzlesIfNeeded();
  }

  Future<void> fetchNozzlesIfNeeded() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.user?.role;
    final userSite = authProvider.user?.siteId;
    _userRole = userRole;
    // Check if user has role 5
    if (userRole == 5) {
      setState(() {
        isLoading = true;
      });

      try {
        // Make the API call
        final response = await http.post(
          Uri.parse('${AppConfig.baseUrl}/api/pump/command/verify'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode({'site': userSite}),
        );
        print('Response body: ${response.body}');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            pump = data['data'];
            print(
                "&&&&&&&&&&&&&&&&&&& ${data['data']}"); // Fixed string interpolation
            isLoading = false;
          });
        } else {
          // Handle error
          setState(() {
            isLoading = false;
          });
        }
      } catch (e) {
        // Handle exception
        print('Error fetching nozzles: $e');
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user?.role.toString();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120.0),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF870813), Color(0xFFB91C1C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Title Section
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: const Text(
                    'Welcome to IKWIM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Profile Section
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      const ProfileSection(),
                      const Spacer(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Red Section
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF870813), Color(0xFFB91C1C)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  // Welcome Text

                  // Post-paid, Pre-paid, Master Icons
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildPaymentOption('POST PAID', Icons.receipt_long),
                        _buildPaymentOption(
                            'PRE-PAID', Icons.account_balance_wallet),
                        _buildPaymentOption(
                            'MASTER', Icons.admin_panel_settings),
                        _buildPaymentOption('Royalty', Icons.diamond),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            // Main Content
            _userRole == 6
                ? Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF870813), Color(0xFFB91C1C)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.payment,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                "Payment Options",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionCard(
                                'Card Payment',
                                Icons.money,
                                Colors.green,
                                () {
                                  // Handle card payment
                                  print('Card payment selected');
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildActionCard(
                                'Pump Indexing',
                                Icons.money,
                                Colors.green,
                                () {
                                  // Handle pump indexing
                                  print('Pump indexing selected');
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildActionCard(
                                'Bon Payment',
                                Icons.phone_android,
                                Colors.blue,
                                () {
                                  // Handle Bon payment
                                  print('Bon payment selected');
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionCard(
                                'Cash Payment',
                                Icons.money,
                                Colors.green,
                                () {
                                  // Handle cash payment
                                  print('Cash payment selected');
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildActionCard(
                                'Mobile Money',
                                Icons.phone_android,
                                Colors.blue,
                                () {
                                  // Handle mobile money
                                  print('Mobile money selected');
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF870813), Color(0xFFB91C1C)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.local_gas_station,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                "Available Pumps",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        isLoading
                            ? const Center(
                                child: Column(
                                  children: [
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFF870813)),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      "Loading pumps...",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              )
                            : pump.isEmpty
                                ? Container(
                                    padding: const EdgeInsets.all(40),
                                    child: const Center(
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.local_gas_station_outlined,
                                            size: 60,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            "No pumps found",
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: pump.map<Widget>((item) {
                                      return _buildPumpCard(item);
                                    }).toList(),
                                  ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildPumpCard(Map<String, dynamic> pumpData) {
    final pumpName = pumpData['pomp_name'] ?? 'Unknown Pump';
    final pumpId = pumpData['pomp_id']?.toString() ?? 'N/A';
    final siteName = pumpData['site_name'] ?? 'Unknown Site';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF8F9FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => DetailedCardView(
                        pumpId: pumpData['pomp_id'],
                      )),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF870813).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.local_gas_station,
                        color: Color(0xFF870813),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Fuel Pump',
                      style: TextStyle(
                        color: Color(0xFF870813),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoItem('Pump Name:', pumpName),
                          const SizedBox(height: 8),
                          _buildInfoItem('Site Location:', siteName),
                          const SizedBox(height: 8),
                          _buildInfoItem('Pump ID:', pumpId),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String text, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback? onTap) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {
          if (title == 'Card Payment') {
            // Navigate to card tab in bottom navigation
            widget.onTabChange?.call(1);
          } else if (title == 'Bon Payment') {
            // Navigate to wallet tab in bottom navigation
            widget.onTabChange?.call(2);
          } else {
            // Navigate to payment screen for other payment types
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentScreen(paymentType: title),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
