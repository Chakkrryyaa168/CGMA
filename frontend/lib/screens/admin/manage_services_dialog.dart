import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';

class ManageServicesDialog extends StatefulWidget {
  const ManageServicesDialog({super.key});

  @override
  State<ManageServicesDialog> createState() => _ManageServicesDialogState();
}

class _ManageServicesDialogState extends State<ManageServicesDialog> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bProvider = Provider.of<BookingProvider>(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.design_services, color: Color(0xFFFFC700)),
          SizedBox(width: 10),
          Text('Services & Pricing Catalog', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC700),
                foregroundColor: const Color(0xFF121214),
                minimumSize: const Size(double.infinity, 44),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add New Service Package', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _showAddServiceSubDialog(context),
            ),
            const SizedBox(height: 16),
            const Text('Configured Workshop Services:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            bProvider.availableServices.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No custom services defined.', style: TextStyle(color: Colors.grey)),
                  )
                : Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: bProvider.availableServices.length,
                      itemBuilder: (context, index) {
                        final service = bProvider.availableServices[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF18181B),
                              child: Icon(Icons.handyman, color: Color(0xFFFFC700), size: 18),
                            ),
                            title: Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(service.description.isNotEmpty ? service.description : 'Standard Service Package'),
                            trailing: Text(
                              '\$${service.standardPrice.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF121214), fontSize: 15),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  void _showAddServiceSubDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('New Service & Price Entry', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Service Name *', hintText: 'Full Diagnostic & Tuning'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Base Price (\$) *', hintText: '89.99'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Service Description', hintText: 'Complete computerized OBD scan & checkup'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC700),
                foregroundColor: const Color(0xFF121214),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Service "${_nameController.text}" configured at \$${_priceController.text}!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Save Package', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
