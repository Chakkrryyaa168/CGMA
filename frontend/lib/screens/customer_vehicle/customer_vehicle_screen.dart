import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/vehicle_model.dart';
import 'add_vehicle_dialog.dart';
import 'register_customer_dialog.dart';

class CustomerVehicleScreen extends StatefulWidget {
  const CustomerVehicleScreen({super.key});

  @override
  State<CustomerVehicleScreen> createState() => _CustomerVehicleScreenState();
}

class _CustomerVehicleScreenState extends State<CustomerVehicleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookingProvider>(context, listen: false).fetchVehiclesAndServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bProvider = Provider.of<BookingProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final vehicles = bProvider.userVehicles;
    final isStaff = auth.userRole == 'ADMIN' || auth.userRole == 'RECEPTIONIST';

    return Scaffold(
      appBar: AppBar(
        title: Text(isStaff ? 'Customer & Vehicle Management' : 'My Registered Vehicles'),
        actions: [
          if (isStaff)
            IconButton(
              icon: const Icon(Icons.person_add_alt_1),
              tooltip: 'Register New Customer',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const RegisterCustomerDialog(),
                );
              },
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 96.0),
        child: FloatingActionButton.extended(
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => const AddVehicleDialog(),
            );
          },
          backgroundColor: const Color(0xFFFFC700),
          icon: const Icon(Icons.add_a_photo_outlined, color: Color(0xFF121214)),
          label: Text(isStaff ? 'Register Vehicle' : 'Add Vehicle', style: const TextStyle(color: Color(0xFF121214), fontWeight: FontWeight.bold)),
        ),
      ),
      body: Column(
        children: [
          if (isStaff)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFF18181B),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.badge, color: Color(0xFFFFC700), size: 20),
                      SizedBox(width: 8),
                      Text('Staff Management Console', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC700),
                      foregroundColor: const Color(0xFF121214),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    icon: const Icon(Icons.person_add, size: 16),
                    label: const Text('+ New Customer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const RegisterCustomerDialog(),
                      );
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: vehicles.isEmpty
                ? const Center(child: Text('No vehicles registered yet.'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 180),
                    itemCount: vehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = vehicles[index];
                      return VehicleCard(vehicle: vehicle);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;

  const VehicleCard({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.directions_car_filled, color: Color(0xFF18181B), size: 28),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${vehicle.brand} ${vehicle.model} (${vehicle.year})',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Plate: ${vehicle.plateNumber}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
                Chip(
                  label: Text(vehicle.status, style: const TextStyle(fontSize: 11, color: Colors.white)),
                  backgroundColor: vehicle.status == 'IN_SERVICE' ? Colors.orange : Colors.green,
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoColumn('Mileage', '${vehicle.mileage} km'),
                _buildInfoColumn('Color', vehicle.color),
                _buildInfoColumn('VIN', vehicle.vin ?? 'N/A'),
              ],
            ),
            if (vehicle.customer?.user != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Owner: ${vehicle.customer!.user!.fullName} (${vehicle.customer!.user!.phone})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
