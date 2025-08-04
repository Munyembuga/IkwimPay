import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:ikwimpay/providers/globalapi.dart';
import 'package:ikwimpay/services/pump_service.dart';
import 'package:ikwimpay/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class PendingIndexingTransactionsScreen extends StatefulWidget {
  const PendingIndexingTransactionsScreen({Key? key}) : super(key: key);

  @override
  _PendingIndexingTransactionsScreenState createState() =>
      _PendingIndexingTransactionsScreenState();
}

class _PendingIndexingTransactionsScreenState
    extends State<PendingIndexingTransactionsScreen> {
  List<dynamic> shifts = [];
  bool isLoadingShifts = true;
  int? selectedShift;
  List<dynamic> pendingTransactions = [];
  bool isLoadingPending = false;

  @override
  void initState() {
    super.initState();
    fetchPendingTransactions();
  }

  // Future<void> fetchShifts() async {
  //   setState(() {
  //     isLoadingShifts = true;
  //   });

  //   try {
  //     final data = await PumpService.getShifts();
  //     setState(() {
  //       shifts = data['data'];
  //       isLoadingShifts = false;
  //     });
  //   } catch (e) {
  //     print('Error fetching shifts: $e');
  //     setState(() {
  //       isLoadingShifts = false;
  //     });
  //     ScaffoldMessenger.of(context)
  //         .showSnackBar(const SnackBar(content: Text('Error loading shifts')));
  //   }
  // }

  Future<void> fetchPendingTransactions() async {
    // if (selectedShift == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final siteId = authProvider.user?.siteId ?? 0;

    setState(() {
      isLoadingPending = true;
    });

    try {
      final data = await PumpService.getPendingIndexTransactions(
        siteId: siteId,
        shiftId: selectedShift,
      );

      setState(() {
        pendingTransactions = data['data'] ?? [];
        isLoadingPending = false;
      });
    } catch (e) {
      print('Error fetching pending transactions: $e');
      setState(() {
        isLoadingPending = false;
      });
    }
  }

  Future<void> approveTransaction(int transactionId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = 2235;
    final siteID = authProvider.user?.siteId ?? 0;

    try {
      final response = await PumpService.approveIndexTransaction(
          transactionId: transactionId, userId: userId, siteID: siteID);

      // Check if the response contains an error status
      if (response != null &&
          response['status'] != null &&
          response['status'] != 200) {
        // Handle API error response
        final errorMessage = response['message'] ?? 'Unknown error occurred';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print("Transaction approved successfully");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction approved successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh pending transactions
      fetchPendingTransactions();
    } catch (e) {
      print('Error approving transaction: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving transaction: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> rejectTransaction(int transactionId) async {
    // TODO: Implement reject transaction functionality
    // This would need to be added to PumpService
    print('Reject transaction: $transactionId');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reject functionality not implemented yet'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> editTransaction(Map<String, dynamic> transaction) async {
    final TextEditingController editIndexController = TextEditingController();
    final currentEndIndex = transaction['end_index']?.toString() ?? '';
    editIndexController.text = currentEndIndex;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
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
                'Edit Index',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF870813),
                ),
              ),
              const SizedBox(height: 20),

              // Transaction details
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
                      '${transaction['pomp_name']} - ${transaction['nozzle_name']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF870813),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem(
                            'Start Index:',
                            transaction['start_index']?.toString() ?? 'N/A',
                          ),
                        ),
                        Expanded(
                          child: _buildInfoItem(
                            'Shift:',
                            transaction['shift_name'] ?? 'N/A',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Current index input
              const Text(
                'End Index',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF870813),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: editIndexController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  hintText: 'Enter end index',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                ],
              ),
              const SizedBox(height: 24),

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
                      onPressed: () async {
                        if (editIndexController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter end index'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // Validation: End index should be greater than start index
                        final startIndex = double.tryParse(
                                transaction['start_index']?.toString() ??
                                    '0') ??
                            0;
                        final endIndex =
                            double.tryParse(editIndexController.text) ?? 0;

                        if (endIndex <= startIndex) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'End index must be greater than start index'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        Navigator.of(context).pop();
                        await updateTransaction(
                          transaction['pumpIndex'],
                          editIndexController.text,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB91C1C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Update'),
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
  }

  Future<void> updateTransaction(int transactionId, String newEndIndex) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final siteId = authProvider.user?.siteId ?? 0;
    final userId = authProvider.user?.userId ?? 0;
    try {
      // Call update API - you'll need to add this method to PumpService
      final response = await PumpService.updatePumpIndex(
        transactionId: transactionId,
        accId: userId,
        siteId: siteId,
        endIndex: double.parse(newEndIndex),
      );
      print('Update pump index response: $response');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Index updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh the list
      fetchPendingTransactions();
    } catch (e) {
      print('Error updating transaction: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating transaction: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pending Index Transactions',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color(0xFFB91C1C),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchPendingTransactions,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shift selection
            // _buildShiftSelection(),
            const SizedBox(height: 20),

            // Pending transactions header

            const SizedBox(height: 20),

            // Pending transactions list
            _buildPendingTransactionsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftSelection() {
    return Container(
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
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF870813)),
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
                        final shiftId = shift['shittId'];
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
                                  ? const Color(0xFF870813).withOpacity(0.1)
                                  : Colors.white,
                            ),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  selectedShift = shiftId;
                                });
                                fetchPendingTransactions();
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
                                      activeColor: const Color(0xFF870813),
                                      onChanged: (value) {
                                        setState(() {
                                          selectedShift = value;
                                        });
                                        fetchPendingTransactions();
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
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: status == 1
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        status == 1 ? 'Active' : 'Inactive',
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
    );
  }

  Widget _buildPendingTransactionsList() {
    // if (selectedShift == null) {
    //   return Container(
    //     padding: const EdgeInsets.all(40),
    //     child: const Center(
    //       child: Column(
    //         children: [
    //           Icon(
    //             Icons.info_outline,
    //             size: 60,
    //             color: Colors.grey,
    //           ),
    //           SizedBox(height: 16),
    //           Text(
    //             "Please select a shift to view pending transactions",
    //             style: TextStyle(
    //               fontSize: 16,
    //               color: Colors.grey,
    //               fontWeight: FontWeight.w500,
    //             ),
    //             textAlign: TextAlign.center,
    //           ),
    //         ],
    //       ),
    //     ),
    //   );
    // }

    return isLoadingPending
        ? const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF870813)),
            ),
          )
        : pendingTransactions.isEmpty
            ? Container(
                padding: const EdgeInsets.all(40),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 60,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        "No pending transactions",
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
                children: pendingTransactions.map<Widget>((transaction) {
                  return _buildTransactionCard(transaction);
                }).toList(),
              );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.userId ?? 0;
    final transactionAccId = transaction['acc_id'] ?? 0;
    final canEdit = currentUserId == transactionAccId;

    final nozzleName = transaction['nozzle_name'] ?? 'Unknown Nozzle';
    final pumpName = transaction['pomp_name'] ?? 'Unknown Pump';
    final startIndex = transaction['start_index']?.toString() ?? 'N/A';
    final endIndex = transaction['end_index']?.toString() ?? 'N/A';
    final shiftName = transaction['shift_name'] ?? 'N/A';
    final submittedBy = transaction['f_name'] ?? 'Unknown User';
    final transactionId = transaction['pumpIndex'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.hourglass_empty,
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$pumpName - $nozzleName',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF870813),
                        ),
                      ),
                      Text(
                        'Shift: $shiftName',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('Start Index:', startIndex),
                ),
                Expanded(
                  child: _buildInfoItem('End Index:', endIndex),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoItem('Submitted by:', submittedBy),
            const SizedBox(height: 16),

            // Action buttons row
            Row(
              children: [
                if (canEdit) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => editTransaction(transaction),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edits'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => approveTransaction(transactionId),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
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
      ),
    );
  }
}
