import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:ikwimpay/providers/globalapi.dart';
import 'package:ikwimpay/services/pump_service.dart';
import 'package:ikwimpay/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';

class PumpIndexingScreen extends StatefulWidget {
  const PumpIndexingScreen({Key? key}) : super(key: key);

  @override
  _PumpIndexingScreenState createState() => _PumpIndexingScreenState();
}

class _PumpIndexingScreenState extends State<PumpIndexingScreen> {
  List<dynamic> pumps = [];
  List<dynamic> nozzles = [];
  List<dynamic> shifts = [];
  bool isLoading = true;
  bool isLoadingShifts = true;
  bool isLoadingNozzles = false;
  String? selectedPump;
  Map<String, dynamic>? selectedPumpData;
  String? selectedNozzle;
  String? previousIndex;
  int? selectedShift;
  final TextEditingController currentIndexController = TextEditingController();
  Map<String, dynamic>? selectedNozzleData;
  double? nozzleSellingPrice; // Add this variable to store selling price

  @override
  void initState() {
    super.initState();
    fetchShifts();
  }

  Future<void> fetchShifts() async {
    setState(() {
      isLoadingShifts = true;
    });

    try {
      final data = await PumpService.getShifts();
      setState(() {
        shifts = data['data'];
        isLoadingShifts = false;
      });
    } catch (e) {
      print('Error fetching shifts: $e');
      setState(() {
        isLoadingShifts = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error loading shifts')));
    }
  }

  Future<void> fetchPumpsAndNozzles() async {
    if (selectedShift == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.userId ?? 0;
    final siteId = authProvider.user?.siteId ?? 0;

    setState(() {
      isLoading = true;
      pumps = [];
      nozzles = [];
      selectedPump = null;
      selectedPumpData = null;
      selectedNozzle = null;
      previousIndex = null;
    });

    try {
      final data = await PumpService.getShiftInfo(
        userId: userId,
        siteId: siteId,
        shiftId: selectedShift!,
      );
      print('Fetched data: $data');
      setState(() {
        pumps = data['pump'];
        nozzles = data['nozzles'];
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching pumps and nozzles: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading pumps and nozzles')));
    }
  }

  List<dynamic> getNozzlesForPump(String pumpId) {
    return nozzles
        .where((nozzle) => nozzle['pomp_id'].toString() == pumpId)
        .toList();
  }

  Future<void> fetchPreviousIndex(String nozzleId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final siteId = authProvider.user?.siteId ?? 0;

    setState(() {
      isLoadingNozzles = true;
      previousIndex = null;
      nozzleSellingPrice = null; // Reset selling price
    });

    try {
      final data = await PumpService.getNozzleIndex(
        nozzleId: int.parse(nozzleId),
        siteId: siteId,
      );

      setState(() {
        previousIndex = data['data']['end_index']?.toString() ?? 'N/A';
        // Store the selling price from the response
        nozzleSellingPrice =
            data['data']['selling_price']?.toDouble() ?? 1500.0;
        isLoadingNozzles = false;
      });

      print('Nozzle selling price: $nozzleSellingPrice');
    } catch (e) {
      print('Error fetching previous index: $e');
      setState(() {
        previousIndex = "N/A";
        nozzleSellingPrice = 1500.0; // Default selling price
        isLoadingNozzles = false;
      });
    }
  }

  Future<void> submitIndex() async {
    if (selectedShift == null ||
        selectedNozzle == null ||
        selectedNozzleData == null ||
        currentIndexController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select shift, nozzle and enter current index'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validation: Current index should be greater than previous index
    if (previousIndex != null && previousIndex != "N/A") {
      double current = double.tryParse(currentIndexController.text) ?? 0;
      double previous = double.tryParse(previousIndex!) ?? 0;

      if (current <= previous) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Current index must be greater than previous index'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final siteId = authProvider.user?.siteId ?? 0;
      final userId = authProvider.user?.userId ?? 0;

      // Parse the current and previous index values
      final double endIndex = double.tryParse(currentIndexController.text) ?? 0;
      final double startIndex = double.tryParse(previousIndex ?? '0') ?? 0;

      // Get nozzle details
      final nozzleId = int.tryParse(selectedNozzle!) ?? 0;

      // Use the selling price from the nozzle index response
      final productId = selectedNozzleData?['tank_id'] ?? 1;
      final sellingPrice =
          nozzleSellingPrice ?? 1500.0; // Use the fetched selling price

      print("Using selling price: $sellingPrice");

      await PumpService.submitPumpIndex(
        nozzleId: nozzleId,
        productId: productId is int
            ? productId
            : int.tryParse(productId.toString()) ?? 1,
        sellingPrice: sellingPrice,
        shiftsiteId: selectedShift!,
        startIndex: startIndex,
        endIndex: endIndex,
        accId: userId,
        siteId: siteId,
      );

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Index updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear fields and refresh
      setState(() {
        currentIndexController.clear();
        if (selectedNozzle != null) {
          fetchPreviousIndex(selectedNozzle!);
        }
      });
    } catch (e) {
      print('Error updating index: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating index: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pump Indexing',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            )),
        backgroundColor: const Color(0xFFB91C1C),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shift selection
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Shift',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF870813),
                    ),
                  ),
                  const SizedBox(height: 12),
                  isLoadingShifts
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF870813)),
                            ),
                          ),
                        )
                      : shifts.isEmpty
                          ? const Text(
                              'No shifts available',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            )
                          : Row(
                              children: shifts.map<Widget>((shift) {
                                final shiftId = shift[
                                    'shittId']; // Changed back to 'shittId'
                                final shiftName = shift['shift_name'];
                                final status = shift['status'];

                                return Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: selectedShift == shiftId
                                            ? const Color(0xFF870813)
                                            : Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      color: selectedShift == shiftId
                                          ? const Color(0xFF870813)
                                              .withOpacity(0.1)
                                          : Colors.white,
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          selectedShift = shiftId;
                                        });
                                        fetchPumpsAndNozzles();
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 8,
                                        ),
                                        child: Column(
                                          children: [
                                            Radio<int>(
                                              value: shiftId,
                                              groupValue: selectedShift,
                                              activeColor:
                                                  const Color(0xFF870813),
                                              onChanged: (value) {
                                                setState(() {
                                                  selectedShift = value;
                                                });
                                                fetchPumpsAndNozzles();
                                              },
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              shiftName,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: status == 1
                                                    ? Colors.green
                                                        .withOpacity(0.1)
                                                    : Colors.red
                                                        .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                status == 1
                                                    ? 'Active'
                                                    : 'Inactive',
                                                style: TextStyle(
                                                  color: status == 1
                                                      ? Colors.green
                                                      : Colors.red,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                ],
              ),
            ),

            if (selectedShift != null) ...[
              const SizedBox(height: 20),

              // Pump selection with dropdown_search
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Pump',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF870813),
                      ),
                    ),
                    const SizedBox(height: 12),
                    isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF870813)),
                              ),
                            ),
                          )
                        : DropdownSearch<Map<String, dynamic>>(
                            items: (filter, infiniteScrollProps) =>
                                pumps.cast<Map<String, dynamic>>(),
                            itemAsString: (Map<String, dynamic> pump) =>
                                pump['pomp_name'] ?? 'Unknown Pump',
                            compareFn: (item1, item2) =>
                                item1['pomp_id'] == item2['pomp_id'],
                            decoratorProps: DropDownDecoratorProps(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Colors.grey,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                hintText: 'Select pump',
                              ),
                            ),
                            popupProps: PopupProps.menu(
                              showSearchBox: true,
                              searchFieldProps: const TextFieldProps(
                                decoration: InputDecoration(
                                  hintText: 'Search pumps...',
                                  prefixIcon: Icon(Icons.search),
                                ),
                              ),
                              itemBuilder:
                                  (context, pump, isSelected, isHighlighted) {
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF870813)
                                            .withOpacity(0.1)
                                        : null,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pump['pomp_name'] ?? 'Unknown Pump',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      // Text(
                                      //   'ID: ${pump['pomp_id']}',
                                      //   style: TextStyle(
                                      //     fontSize: 12,
                                      //     color: Colors.grey[600],
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            onChanged: (pump) {
                              setState(() {
                                selectedPump = pump?['pomp_id'].toString();
                                selectedPumpData = pump;
                                selectedNozzle = null;
                                previousIndex = null;
                              });
                            },
                            selectedItem: selectedPumpData,
                          ),
                  ],
                ),
              ),
            ],

            if (selectedPump != null) ...[
              const SizedBox(height: 20),

              // Nozzle selection with dropdown_search
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Nozzle',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF870813),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownSearch<Map<String, dynamic>>(
                      items: (filter, infiniteScrollProps) =>
                          getNozzlesForPump(selectedPump!)
                              .cast<Map<String, dynamic>>(),
                      itemAsString: (Map<String, dynamic> nozzle) =>
                          '${nozzle['nozzle_name']}',
                      compareFn: (item1, item2) =>
                          item1['nozzle_id'] == item2['nozzle_id'],
                      decoratorProps: DropDownDecoratorProps(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Colors.grey,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          hintText: 'Select nozzle',
                        ),
                      ),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: const TextFieldProps(
                          decoration: InputDecoration(
                            hintText: 'Search nozzles...',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                        itemBuilder:
                            (context, nozzle, isSelected, isHighlighted) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF870813).withOpacity(0.1)
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nozzle['nozzle_name'] ?? 'Unknown Nozzle',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                // Text(
                                //   'Code: ${nozzle['nozle_code']} | ID: ${nozzle['nozzle_id']}',
                                //   style: TextStyle(
                                //     fontSize: 12,
                                //     color: Colors.grey[600],
                                //   ),
                                // ),
                              ],
                            ),
                          );
                        },
                      ),
                      onChanged: (nozzle) {
                        setState(() {
                          selectedNozzle = nozzle?['nozzle_id'].toString();
                          selectedNozzleData = nozzle;
                        });
                        if (nozzle != null) {
                          fetchPreviousIndex(nozzle['nozzle_id'].toString());
                        }
                      },
                      selectedItem: selectedNozzle != null
                          ? getNozzlesForPump(selectedPump!)
                              .cast<Map<String, dynamic>>()
                              .firstWhere(
                                (nozzle) =>
                                    nozzle['nozzle_id'].toString() ==
                                    selectedNozzle,
                                orElse: () => <String, dynamic>{},
                              )
                          : null,
                    ),
                  ],
                ),
              ),
            ],

            if (selectedNozzle != null) ...[
              const SizedBox(height: 20),

              // Previous index and current index input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Previous index display
                    const Text(
                      'Previous Index (Ending Index)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF870813),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey.shade50,
                      ),
                      width: double.infinity,
                      child: isLoadingNozzles
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF870813)),
                                ),
                              ),
                            )
                          : Text(
                              previousIndex ?? 'No previous index found',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),

                    const SizedBox(height: 24),

                    // Current index input
                    const Text(
                      'Current Index',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF870813),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: currentIndexController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        hintText: 'Enter current index',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*$')),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: submitIndex,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB91C1C),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Submit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
