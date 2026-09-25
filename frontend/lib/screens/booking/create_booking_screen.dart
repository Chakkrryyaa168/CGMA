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

  final List<TimeOfDay> _presetTimeSlots = const [
    TimeOfDay(hour: 9, minute: 0),
    TimeOfDay(hour: 10, minute: 30),
    TimeOfDay(hour: 13, minute: 30),
    TimeOfDay(hour: 15, minute: 0),
    TimeOfDay(hour: 16, minute: 30),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookingProvider>(context, listen: false).fetchVehiclesAndServices();
    });
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedVehicle == null || _selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both a vehicle and a service.'),
          backgroundColor: Colors.red,
        ),
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
          const SnackBar(content: Text('Booking confirmed! Work order scheduled.'), backgroundColor: Colors.green),
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

  @override
  Widget build(BuildContext context) {
    final bProvider = Provider.of<BookingProvider>(context);

    // Auto-select first vehicle & service if not selected yet
    if (_selectedVehicle == null && bProvider.userVehicles.isNotEmpty) {
      _selectedVehicle = bProvider.userVehicles.first;
    }
    if (_selectedService == null && bProvider.availableServices.isNotEmpty) {
      _selectedService = bProvider.availableServices.first;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Book Service Appointment'),
        backgroundColor: const Color(0xFF18181B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 180.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Banner Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC700),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.calendar_month, color: Color(0xFF121214), size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SCHEDULE SERVICE',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Choose your vehicle, service package, and date',
                            style: TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 1. SELECT VEHICLE SECTION
              const Text('1. Select Your Vehicle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF121214))),
              const SizedBox(height: 10),

              if (bProvider.isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
              else if (bProvider.userVehicles.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.amber.shade200)),
                  child: const Text('No vehicles registered. Please register a vehicle in your profile first.', style: TextStyle(color: Colors.black87)),
                )
              else
                Column(
                  children: bProvider.userVehicles.map((vehicle) {
                    final isSelected = _selectedVehicle?.id == vehicle.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedVehicle = vehicle),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFFC700) : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: const Color(0xFFFFC700).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
                              : [],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isSelected ? const Color(0xFF18181B) : Colors.grey.shade300,
                              child: Icon(Icons.directions_car, color: isSelected ? const Color(0xFFFFC700) : Colors.grey.shade700, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(vehicle.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF121214))),
                                  const SizedBox(height: 2),
                                  Text('Plate: ${vehicle.plateNumber} • ${vehicle.mileage} km', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? const Color(0xFFFFC700) : Colors.transparent,
                                border: Border.all(color: isSelected ? const Color(0xFFFFC700) : Colors.grey.shade400, width: 2),
                              ),
                              child: Icon(Icons.check, size: 14, color: isSelected ? const Color(0xFF121214) : Colors.transparent),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 20),

              // 2. SELECT SERVICE PACKAGE SECTION
              const Text('2. Choose Service Package', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF121214))),
              const SizedBox(height: 10),

              if (bProvider.availableServices.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('No services available right now.')))
              else
                Column(
                  children: bProvider.availableServices.map((service) {
                    final isSelected = _selectedService?.id == service.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedService = service),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFFC700) : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: const Color(0xFFFFC700).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFFFC700) : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.build_circle, color: isSelected ? const Color(0xFF121214) : Colors.grey.shade700, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF121214))),
                                  const SizedBox(height: 2),
                                  Text(
                                    service.description.isNotEmpty ? service.description : 'Standard garage maintenance service',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF18181B),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '\$${service.standardPrice.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFFFFC700)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 20),

              // 3. DATE & TIME SLOT SELECTION
              const Text('3. Select Date & Time Slot', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF121214))),
              const SizedBox(height: 10),

              // Date Picker Button
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_month, color: Color(0xFFFFC700), size: 20),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF121214)),
                          ),
                        ],
                      ),
                      const Icon(Icons.edit_calendar, color: Colors.grey, size: 18),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Preset Time Slot Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _presetTimeSlots.map((timeSlot) {
                    final isSelected = _selectedTime.hour == timeSlot.hour && _selectedTime.minute == timeSlot.minute;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        showCheckmark: false,
                        label: Text(timeSlot.format(context)),
                        selected: isSelected,
                        selectedColor: const Color(0xFFFFC700),
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? const Color(0xFF121214) : Colors.grey.shade800,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 12,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        side: BorderSide(color: isSelected ? const Color(0xFFFFC700) : Colors.grey.shade300),
                        onSelected: (val) {
                          if (val) setState(() => _selectedTime = timeSlot);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              // 4. PROBLEM DESCRIPTION & NOTES
              const Text('4. Vehicle Symptoms & Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF121214))),
              const SizedBox(height: 10),

              TextFormField(
                controller: _problemController,
                maxLines: 2,
                decoration: _inputDecoration('Describe Any Engine / Brake Symptoms', Icons.description_outlined),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _noteController,
                decoration: _inputDecoration('Special Instructions (Optional)', Icons.note_alt_outlined),
              ),

              const SizedBox(height: 24),

              // BOOKING SUMMARY CARD
              if (_selectedVehicle != null && _selectedService != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Estimated Total', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          Text(
                            '\$${_selectedService!.standardPrice.toStringAsFixed(2)}',
                            style: const TextStyle(color: Color(0xFFFFC700), fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white24, height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Vehicle: ${_selectedVehicle!.displayName}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                          Text('Date: ${DateFormat('MMM d').format(_selectedDate)} at ${_selectedTime.format(context)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // CONFIRM BOOKING YELLOW PILL BUTTON
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: bProvider.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC700),
                    foregroundColor: const Color(0xFF121214),
                    elevation: 4,
                    shadowColor: const Color(0xFFFFC700).withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: bProvider.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Color(0xFF121214), strokeWidth: 2.5),
                        )
                      : const Text(
                          'CONFIRM SERVICE BOOKING',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFFFFC700)),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFFFC700), width: 1.5),
      ),
    );
  }
}
