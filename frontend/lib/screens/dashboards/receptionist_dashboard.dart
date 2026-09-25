import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/repair_job_provider.dart';
import '../../models/booking_model.dart';
import '../../models/repair_job_model.dart';
import '../booking/create_booking_screen.dart';
import '../repair_job/repair_job_detail_screen.dart';

class ReceptionistDashboard extends StatefulWidget {
  const ReceptionistDashboard({super.key});

  @override
  State<ReceptionistDashboard> createState() => _ReceptionistDashboardState();
}

class _ReceptionistDashboardState extends State<ReceptionistDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    final bProvider = Provider.of<BookingProvider>(context, listen: false);
    final rProvider = Provider.of<RepairJobProvider>(context, listen: false);

    await Future.wait([
      bProvider.fetchBookings(),
      rProvider.fetchRepairJobs(),
      rProvider.fetchMechanics(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final bProvider = Provider.of<BookingProvider>(context);
    final rProvider = Provider.of<RepairJobProvider>(context);

    final pendingBookings = bProvider.bookings.where((b) => b.status == 'PENDING' || b.status == 'CONFIRMED').toList();
    final activeRepairJobs = rProvider.repairJobs.where((j) => j.status != 'COMPLETED' && j.status != 'CANCELLED').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Reception Desk & Check-In'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 96.0),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateBookingScreen()),
            ).then((_) => _refreshData());
          },
          icon: const Icon(Icons.add_location_alt, color: Color(0xFF121214)),
          label: const Text('New Customer Booking', style: TextStyle(color: Color(0xFF121214), fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFFFFC700),
          elevation: 4,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Receptionist Banner
              Card(
                color: const Color(0xFF18181B),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Color(0xFFFFC700),
                        child: Icon(Icons.receipt_long, size: 30, color: Color(0xFF121214)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Receptionist: ${auth.currentUser?.fullName ?? "Staff"}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Front Desk • Vehicle Check-In & Customer Billing',
                              style: TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Section 1: Customer Arrivals & Check-In Pending
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pending Arrivals for Check-In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF121214))),
                  Chip(
                    label: Text('${pendingBookings.length} Arriving'),
                    backgroundColor: const Color(0xFFFFC700),
                    labelStyle: const TextStyle(color: Color(0xFF121214), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (bProvider.isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              else if (pendingBookings.isEmpty)
                _buildEmptyCard('No pending customer arrivals right now.')
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pendingBookings.length,
                  itemBuilder: (context, index) {
                    final booking = pendingBookings[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF18181B),
                          child: Icon(Icons.directions_car, color: Color(0xFFFFC700), size: 20),
                        ),
                        title: Text(booking.vehicle?.displayName ?? 'Booking #${booking.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Service: ${booking.service?.name ?? "General"}\nDate: ${booking.bookingDate} at ${booking.bookingTime}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        isThreeLine: true,
                        trailing: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC700),
                            foregroundColor: const Color(0xFF121214),
                          ),
                          icon: const Icon(Icons.check_circle_outline, size: 16),
                          label: const Text('CHECK-IN', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () => _showCheckInDialog(booking, bProvider, rProvider),
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 24),

              // Section 2: Active Repair Jobs & Billing Queue
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Active Garage Work Orders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF121214))),
                  Text(
                    '${activeRepairJobs.length} In Progress',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (rProvider.isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              else if (activeRepairJobs.isEmpty)
                _buildEmptyCard('No active repair jobs in garage.')
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activeRepairJobs.length,
                  itemBuilder: (context, index) {
                    final job = activeRepairJobs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF18181B),
                          child: Icon(Icons.build_circle, color: Color(0xFFFFC700), size: 20),
                        ),
                        title: Text(job.vehicle?.displayName ?? 'Job #${job.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Status: ${job.status.replaceAll('_', ' ')}\nMechanic: ${job.mechanic?.displayName ?? "Unassigned"}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (job.status == 'COMPLETED' || job.status == 'WAITING_FOR_PARTS')
                              IconButton(
                                icon: const Icon(Icons.mark_email_read, color: Colors.green),
                                tooltip: 'Notify Customer Vehicle Ready',
                                onPressed: () => _notifyCustomer(job),
                              ),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF121214)),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => RepairJobDetailScreen(repairJobId: job.id)),
                                ).then((_) => _refreshData());
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => RepairJobDetailScreen(repairJobId: job.id)),
                          ).then((_) => _refreshData());
                        },
                      ),
                    );
                  },
                ),
              const SizedBox(height: 180),
            ],
          ),
        ),
      ),
    );
  }

  void _showCheckInDialog(BookingModel booking, BookingProvider bProvider, RepairJobProvider rProvider) {
    final mileageCtrl = TextEditingController(text: '${booking.vehicle?.mileage ?? 10000}');
    final conditionCtrl = TextEditingController();
    String fuelLevel = 'HALF';
    int? selectedMechId;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSt) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Check-In Vehicle (${booking.vehicle?.plateNumber})', style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: mileageCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Check-In Odometer Mileage (km)'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: fuelLevel,
                      decoration: const InputDecoration(labelText: 'Fuel Level'),
                      items: const [
                        DropdownMenuItem(value: 'EMPTY', child: Text('Empty')),
                        DropdownMenuItem(value: 'QUARTER', child: Text('1/4 Quarter')),
                        DropdownMenuItem(value: 'HALF', child: Text('1/2 Half')),
                        DropdownMenuItem(value: 'THREE_QUARTER', child: Text('3/4 Three Quarter')),
                        DropdownMenuItem(value: 'FULL', child: Text('Full Tank')),
                      ],
                      onChanged: (val) => setSt(() => fuelLevel = val!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: conditionCtrl,
                      decoration: const InputDecoration(labelText: 'Vehicle Body Condition / Scratches'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: selectedMechId,
                      decoration: const InputDecoration(labelText: 'Assign Mechanic (Optional)'),
                      items: rProvider.mechanics.map((m) {
                        return DropdownMenuItem(value: m.id, child: Text(m.displayName));
                      }).toList(),
                      onChanged: (val) => setSt(() => selectedMechId = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC700),
                    foregroundColor: const Color(0xFF121214),
                  ),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final mileage = int.tryParse(mileageCtrl.text) ?? 0;
                    final ok = await bProvider.checkInBooking(
                      bookingId: booking.id,
                      checkInMileage: mileage,
                      fuelLevel: fuelLevel,
                      vehicleCondition: conditionCtrl.text,
                      mechanicId: selectedMechId,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (ok) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Vehicle checked in! Work Order created.'), backgroundColor: Colors.green),
                      );
                      _refreshData();
                    }
                  },
                  child: const Text('Confirm Check-In', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _notifyCustomer(RepairJobModel job) {
    final ownerName = job.vehicle?.customer?.user?.fullName ?? 'Customer';
    final ownerPhone = job.vehicle?.customer?.user?.phone ?? 'Registered Phone';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.mark_email_read, color: Colors.green),
              SizedBox(width: 8),
              Text('Notify Customer Ready', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Text(
            'Send vehicle completion SMS & Email notification to:\n\n'
            '• Owner: $ownerName\n'
            '• Contact: $ownerPhone\n'
            '• Vehicle: ${job.vehicle?.displayName}\n\n'
            'Notification Message:\n"Your vehicle is ready for pickup at Greenwood Drive Garage Hub. Total Invoice: \$${job.invoice?.totalAmount.toStringAsFixed(2) ?? '0.00'}"',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              icon: const Icon(Icons.send),
              label: const Text('SEND NOTIFICATION'),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Vehicle ready alert dispatched to $ownerName ($ownerPhone)!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyCard(String msg) {
    return Card(
      color: Colors.grey.shade100,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(child: Text(msg, style: TextStyle(color: Colors.grey.shade600))),
      ),
    );
  }
}
