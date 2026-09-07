import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../providers/repair_job_provider.dart';
import '../../models/invoice_model.dart';
import 'invoice_pdf_preview_screen.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final int repairJobId;

  const InvoiceDetailScreen({super.key, required this.repairJobId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  InvoiceModel? _invoice;
  bool _isLoading = true;
  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _fetchInvoice();
  }

  Future<void> _fetchInvoice() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.dio.get(ApiConstants.invoices);
      if (response.statusCode == 200) {
        final list = (response.data as List).map((j) => InvoiceModel.fromJson(j)).toList();
        final match = list.where((inv) => inv.repairJobId == widget.repairJobId).toList();
        if (match.isNotEmpty) {
          _invoice = match.first;
        }
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice - Job #${widget.repairJobId}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _invoice == null
              ? const Center(child: Text('No invoice generated for this job yet.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Invoice Header Card
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text('OFFICIAL INVOICE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A8A))),
                                      Text('Car Garage Management System', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                  Chip(
                                    label: Text('Invoice #${_invoice!.id}'),
                                    backgroundColor: Colors.amber.shade100,
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              _buildCostRow('Labor Cost', _invoice!.laborCost),
                              _buildCostRow('Service Fee', _invoice!.serviceFee),
                              _buildCostRow('Spare Parts Cost', _invoice!.partsCost),
                              const Divider(height: 20),
                              _buildCostRow('Subtotal', _invoice!.subtotal, isBold: true),
                              _buildCostRow('Tax (7%)', _invoice!.tax),
                              _buildCostRow('Discount', -_invoice!.discount, color: Colors.green),
                              const Divider(height: 24, thickness: 1.5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('TOTAL AMOUNT DUE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  Text(
                                    '\$${_invoice!.totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                final rJobProvider = Provider.of<RepairJobProvider>(context, listen: false);
                                final jobList = rJobProvider.repairJobs.where((j) => j.id == widget.repairJobId).toList();
                                final job = jobList.isNotEmpty ? jobList.first : null;

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => InvoicePdfPreviewScreen(
                                      invoice: _invoice!,
                                      repairJob: job,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF1E3A8A)),
                              label: const Text('EXPORT / PRINT PDF', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: Color(0xFF1E3A8A)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showPaymentDialog(context),
                              icon: const Icon(Icons.payment),
                              label: const Text('PAYMENT', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: Colors.green.shade700,
                                foregroundColor: Colors.white,
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

  Widget _buildCostRow(String label, double amount, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isBold ? 15 : 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(fontSize: isBold ? 15 : 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context) {
    String selectedMethod = 'CASH';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSt) {
            return AlertDialog(
              title: const Text('Collect Payment'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Amount: \$${_invoice!.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('Select Payment Method:'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedMethod,
                    items: const [
                      DropdownMenuItem(value: 'CASH', child: Text('Cash')),
                      DropdownMenuItem(value: 'CARD', child: Text('Credit / Debit Card')),
                      DropdownMenuItem(value: 'QR', child: Text('QR Code / PromptPay')),
                      DropdownMenuItem(value: 'BANK_TRANSFER', child: Text('Bank Transfer')),
                    ],
                    onChanged: (val) => setSt(() => selectedMethod = val!),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: () async {
                    try {
                      final response = await _apiClient.dio.post(
                        ApiConstants.payments,
                        data: {
                          'invoice': _invoice!.id,
                          'amount': _invoice!.totalAmount,
                          'method': selectedMethod,
                          'status': 'COMPLETED', // Signals auto-completion & ServiceHistory!
                        },
                      );

                      if (response.statusCode == 201 && ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Payment Completed! Repair job closed & Service History recorded.'),
                            backgroundColor: Colors.green,
                          ),
                        );

                        // Refresh providers
                        Provider.of<RepairJobProvider>(context, listen: false).fetchRepairJobs();
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Payment failed'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: const Text('Confirm Payment'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
