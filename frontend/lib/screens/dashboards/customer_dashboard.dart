import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/repair_job_provider.dart';
import '../../models/repair_job_model.dart';
import '../booking/create_booking_screen.dart';
import '../invoice/invoice_detail_screen.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  String _selectedCategory = 'All';

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
      bProvider.fetchVehiclesAndServices(),
      bProvider.fetchBookings(),
      rProvider.fetchRepairJobs(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final bProvider = Provider.of<BookingProvider>(context);
    final rProvider = Provider.of<RepairJobProvider>(context);

    final vehicles = bProvider.userVehicles;
    final activeJobs = rProvider.repairJobs.where((j) => j.status != 'COMPLETED' && j.status != 'CANCELLED').toList();
    final completedJobs = rProvider.repairJobs.where((j) => j.status == 'COMPLETED').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('My Garage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateBookingScreen()),
          ).then((_) => _refreshData());
        },
        icon: const Icon(Icons.add, color: Color(0xFF121214)),
        label: const Text('Book Service', style: TextStyle(color: Color(0xFF121214), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFFC700),
        elevation: 4,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location Pin Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            'Greenwood Drive, Garage Hub',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Morning, ${auth.currentUser?.fullName.split(' ').first ?? "User"}!',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF121214)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Select a car or service matching your style.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF18181B),
                    child: Text(
                      auth.currentUser?.fullName.isNotEmpty == true ? auth.currentUser!.fullName[0].toUpperCase() : 'C',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFC700)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Filter Category Pills Horizontal List
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Vehicles', 'Live Repairs', 'Invoices'].map((category) {
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        showCheckmark: false,
                        label: Text(category),
                        selected: isSelected,
                        selectedColor: const Color(0xFFFFC700),
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? const Color(0xFF121214) : Colors.grey.shade700,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 13,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        side: BorderSide(color: isSelected ? const Color(0xFFFFC700) : Colors.grey.shade300),
                        onSelected: (val) {
                          if (val) setState(() => _selectedCategory = category);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              // Active Repair Job Live Progress Cards
              if ((_selectedCategory == 'All' || _selectedCategory == 'Live Repairs') && activeJobs.isNotEmpty) ...[
                const Text('Live Vehicle Repair Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF121214))),
                const SizedBox(height: 10),
                ...activeJobs.map((job) => _buildLiveProgressCard(job)),
                const SizedBox(height: 20),
              ],

              // Registered Vehicles Section
              if (_selectedCategory == 'All' || _selectedCategory == 'Vehicles') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('My Registered Vehicles', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF121214))),
                    Text('${vehicles.length} Vehicles', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFFC700))),
                  ],
                ),
                const SizedBox(height: 10),
                if (bProvider.isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                else if (vehicles.isEmpty)
                  _buildEmptyCard('No vehicles registered yet.')
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: vehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = vehicles[index];
                      return _buildCarCard(vehicle);
                    },
                  ),
                const SizedBox(height: 20),
              ],

              // Past Service History & Invoices Section
              if ((_selectedCategory == 'All' || _selectedCategory == 'Invoices') && completedJobs.isNotEmpty) ...[
                const Text('Past Service Receipts & Invoices', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF121214))),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: completedJobs.length,
                  itemBuilder: (context, index) {
                    final job = completedJobs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF18181B),
                          child: Icon(Icons.receipt_long, color: Color(0xFFFFC700), size: 20),
                        ),
                        title: Text(job.vehicle?.displayName ?? 'Repair Job #${job.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Completed • Total: \$${job.invoice?.totalAmount.toStringAsFixed(2) ?? "0.00"}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        trailing: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC700),
                            foregroundColor: const Color(0xFF121214),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          icon: const Icon(Icons.picture_as_pdf, size: 14),
                          label: const Text('PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => InvoiceDetailScreen(repairJobId: job.id)),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarCard(dynamic vehicle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Specs Badges
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    vehicle.displayName,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF121214)),
                  ),
                ),
                Row(
                  children: [
                    _buildSpecBadge(Icons.speed, '${vehicle.mileage} km'),
                    const SizedBox(width: 8),
                    _buildSpecBadge(Icons.color_lens_outlined, vehicle.color),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Car Visual Area
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.directions_car_rounded,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  // Dark Overlay Location/Status Tag
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF18181B),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFFFFC700), size: 12),
                          const SizedBox(width: 4),
                          Text(
                            vehicle.status == 'IN_SERVICE' ? 'In Repair Bay' : 'Biscayne Park Garage',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveProgressCard(RepairJobModel job) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFFFC700), width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  job.vehicle?.displayName ?? 'Work Order #${job.id}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF121214)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    job.status,
                    style: const TextStyle(color: Color(0xFFFFC700), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildTimeline(job.status),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(String status) {
    final steps = ['PENDING', 'IN_PROGRESS', 'WAITING_FOR_PARTS', 'COMPLETED'];
    int currentIndex = steps.indexOf(status);
    if (currentIndex == -1) currentIndex = 1;

    return Row(
      children: List.generate(steps.length, (index) {
        bool isDone = index <= currentIndex;
        return Expanded(
          child: Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? const Color(0xFFFFC700) : Colors.grey.shade300,
                ),
                child: Icon(
                  isDone ? Icons.check : Icons.circle,
                  color: isDone ? const Color(0xFF121214) : Colors.grey,
                  size: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                steps[index].replaceAll('_', ' '),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                  color: isDone ? const Color(0xFF121214) : Colors.grey,
                ),
              ),
            ],
          ),
        );
      }),
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
