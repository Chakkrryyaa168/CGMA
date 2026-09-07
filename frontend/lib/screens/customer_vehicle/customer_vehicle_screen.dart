import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../models/vehicle_model.dart';

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
    final vehicles = bProvider.userVehicles;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer & Vehicle Management'),
      ),
      body: vehicles.isEmpty
          ? const Center(child: Text('No vehicles registered yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                return VehicleCard(vehicle: vehicle);
              },
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
                    const Icon(Icons.directions_car_filled, color: Color(0xFF1E3A8A), size: 28),
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
