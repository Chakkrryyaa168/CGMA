import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventory_provider.dart';

class AddSparePartDialog extends StatefulWidget {
  const AddSparePartDialog({super.key});

  @override
  State<AddSparePartDialog> createState() => _AddSparePartDialogState();
}

class _AddSparePartDialogState extends State<AddSparePartDialog> {
  final _formKey = GlobalKey<FormState>();
  final _partNumController = TextEditingController();
  final _partNameController = TextEditingController();
  final _categoryController = TextEditingController(text: 'General');
  final _priceController = TextEditingController();
  final _qtyController = TextEditingController();
  final _minQtyController = TextEditingController(text: '5');

  bool _isSubmitting = false;

  @override
  void dispose() {
    _partNumController.dispose();
    _partNameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
    _minQtyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final iProvider = Provider.of<InventoryProvider>(context, listen: false);

    final success = await iProvider.addSparePart(
      partNumber: _partNumController.text.trim(),
      partName: _partNameController.text.trim(),
      category: _categoryController.text.trim(),
      unitPrice: double.tryParse(_priceController.text.trim()) ?? 0.0,
      quantity: int.tryParse(_qtyController.text.trim()) ?? 0,
      minStockQty: int.tryParse(_minQtyController.text.trim()) ?? 5,
    );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Spare part added to workshop inventory!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted && iProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(iProvider.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.inventory_2, color: Color(0xFFFFC700)),
          SizedBox(width: 10),
          Text('Add Inventory Spare Part', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _partNumController,
                decoration: const InputDecoration(
                  labelText: 'Part SKU / Number *',
                  hintText: 'e.g. BRK-8890',
                  prefixIcon: Icon(Icons.qr_code),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _partNameController,
                decoration: const InputDecoration(
                  labelText: 'Part Name *',
                  hintText: 'e.g. Ceramic Brake Pad Set',
                  prefixIcon: Icon(Icons.build),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Unit Price (\$) *',
                        hintText: '45.00',
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _qtyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Stock Qty *',
                        hintText: '25',
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        hintText: 'Brakes / Engine',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _minQtyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Min Stock Alert Threshold',
                        hintText: '5',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFC700),
            foregroundColor: const Color(0xFF121214),
          ),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF121214)))
              : const Text('Add to Inventory', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
