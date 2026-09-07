import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/booking_provider.dart';
import '../../models/vehicle_model.dart';
import '../../models/service_model.dart';

class CreateBookingScreen extends StatefulWidget {
  const CreateBookingScreen({super.key});

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  VehicleModel? _selectedVehicle;
  ServiceModel? _selectedService;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  final _problemController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookingProvider>(context, listen: false).fetchVehiclesAndServices();
    });
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedVehicle == null || _selectedService == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select both a vehicle and a service.')),
        );
        return;
      }

      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final timeStr = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00';

      final bProvider = Provider.of<BookingProvider>(context, listen: false);
      final success = await bProvider.createBooking(
        vehicleId: _selectedVehicle!.id,
        serviceId: _selectedService!.id,
        bookingDate: dateStr,
        bookingTime: timeStr,
        problemDescription: _problemController.text.trim(),
        note: _noteController.text.trim(),
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking created successfully!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(bProvider.errorMessage ?? 'Booking failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bProvider = Provider.of<BookingProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Service Booking'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Vehicle Selection
              DropdownButtonFormField<VehicleModel>(
                initialValue: _selectedVehicle,
                decoration: const InputDecoration(
                  labelText: 'Select Vehicle',
                  prefixIcon: Icon(Icons.directions_car),
                  border: OutlineInputBorder(),
                ),
                items: bProvider.userVehicles.map((v) {
                  return DropdownMenuItem(
                    value: v,
                    child: Text(v.displayName),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedVehicle = val),
                validator: (v) => v == null ? 'Select a vehicle' : null,
              ),

              const SizedBox(height: 16),

              // 2. Service Selection
              DropdownButtonFormField<ServiceModel>(
                initialValue: _selectedService,
                decoration: const InputDecoration(
                  labelText: 'Select Service Offering',
                  prefixIcon: Icon(Icons.build),
                  border: OutlineInputBorder(),
                ),
                items: bProvider.availableServices.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text('${s.name} (\$${s.standardPrice.toStringAsFixed(2)})'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedService = val),
                validator: (v) => v == null ? 'Select a service' : null,
              ),

              const SizedBox(height: 16),

              // 3. Date & Time Selection Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (picked != null) setState(() => _selectedDate = picked);
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                        );
                        if (picked != null) setState(() => _selectedTime = picked);
                      },
                      icon: const Icon(Icons.access_time),
                      label: Text(_selectedTime.format(context)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 4. Problem Description
              TextFormField(
                controller: _problemController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Problem Description / Symptoms',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // 5. Notes
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Special Instructions / Notes',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: bProvider.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                ),
                child: bProvider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('CONFIRM BOOKING', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
