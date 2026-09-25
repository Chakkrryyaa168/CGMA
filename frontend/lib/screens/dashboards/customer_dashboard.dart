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
        title: const Text('My Garage & Customer Hub'),
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
          icon: const Icon(Icons.add, color: Color(0xFF121214)),
          label: const Text('Book Service', style: TextStyle(color: Color(0xFF121214), fontWeight: FontWeight.bold)),
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
              // Greeting & Location Header
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
                        'Morning, ${auth.currentUser?.fullName.split(' ').first ?? "Customer"}!',
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
                    radius: 24,
                    backgroundColor: const Color(0xFF18181B),
                    child: Text(
                      auth.currentUser?.fullName.isNotEmpty == true ? auth.currentUser!.fullName[0].toUpperCase() : 'C',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFC700)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Cool Promotional Discount Banner Card
              _buildDiscountBanner(),

              const SizedBox(height: 20),

              // Vroom VIP Loyalty Rewards Bar
              _buildLoyaltyCard(),

              const SizedBox(height: 20),

              // Quick Action Services & Emergency SOS Row
              _buildQuickServicesHeader(),

              const SizedBox(height: 16),

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

              // Registered Vehicles Section with Car Images
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
              const SizedBox(height: 180),
            ],
          ),
        ),
      ),
    );
  }

  // Cool Promotional Discount Banner Card with Car Asset Backdrop
  Widget _buildDiscountBanner() {
    return Container(
      height: 160,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: AssetImage('assets/images/need_service_banner.jpg'),
          fit: BoxFit.cover,
          onError: _onImageError,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Dark Gradient Overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.9),
                  Colors.black.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC700),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '25% OFF DISCOUNT',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF121214)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF18181B),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFC700)),
                      ),
                      child: const Text(
                        'PROMO: VROOM25',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFFC700)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Need a Service?\nGet 25% Off Full Diagnostic!',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC700),
                    foregroundColor: const Color(0xFF121214),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateBookingScreen()),
                    ).then((_) => _refreshData());
                  },
                  child: const Text('Claim Offer Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Vroom VIP Loyalty Points Card
  Widget _buildLoyaltyCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC700).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.workspace_premium, color: Color(0xFFFFC700), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Vroom VIP Loyalty Club', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('450 Points', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFFFC700))),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: const LinearProgressIndicator(
                    value: 0.75,
                    backgroundColor: Color(0xFF27272A),
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC700)),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                const Text('50 pts away from 15% OFF Voucher reward!', style: TextStyle(fontSize: 10, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Quick Action Services Grid Header & Roadside Emergency SOS
  Widget _buildQuickServicesHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Popular Maintenance Services', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF121214))),
            GestureDetector(
              onTap: () => _showEmergencySosDialog(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.sos, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('24/7 Roadside SOS', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildServiceQuickCard('Engine Oil Change', '\$49.99', Icons.oil_barrel, Colors.amber.shade800),
              _buildServiceQuickCard('Brake Inspection', '\$39.99', Icons.minor_crash, Colors.red.shade700),
              _buildServiceQuickCard('Tire & Alignment', '\$59.99', Icons.tire_repair, Colors.blue.shade700),
              _buildServiceQuickCard('AC & Battery Check', '\$29.99', Icons.battery_charging_full, Colors.green.shade700),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceQuickCard(String name, String price, IconData icon, Color color) {
    return Container(
      width: 135,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF121214)), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(price, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  static void _onImageError(Object exception, StackTrace? stackTrace) {}

  // Registered Vehicle Card with Car Image Backdrop
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
            // Vehicle Title & Specs Badges
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
                    const SizedBox(width: 6),
                    _buildSpecBadge(Icons.color_lens_outlined, vehicle.color),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Car Visual Area with Real Car Image
            Container(
              height: 135,
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                image: const DecorationImage(
                  image: AssetImage('assets/images/banner_car.png'),
                  fit: BoxFit.cover,
                  onError: _onImageError,
                ),
              ),
              child: Stack(
                children: [
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.5),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),

                  // Top Left Plate Number Tag
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.black87),
                      ),
                      child: Text(
                        vehicle.plateNumber.toUpperCase(),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black),
                      ),
                    ),
                  ),

                  // Bottom Right Location Tag Overlay
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
    // Calculate estimated total cost from labor fee + part usages
    double estimatedPartsCost = job.partUsages.fold(0.0, (sum, p) => sum + p.partsCost);
    double estimatedLabor = job.invoice?.laborCost ?? 50.0;
    double totalEstimate = job.invoice?.totalAmount ?? (estimatedLabor + estimatedPartsCost);

    return Card(
      elevation: 3,
      shadowColor: Colors.black26,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFFFC700), width: 1.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    job.vehicle?.displayName ?? 'Work Order #${job.id}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF121214)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    job.status.replaceAll('_', ' '),
                    style: const TextStyle(color: Color(0xFFFFC700), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            _buildTimeline(job.status),

            const Divider(height: 24),

            // Estimated Cost & Diagnosis Summary Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ESTIMATED SERVICE COST', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(
                      '\$${totalEstimate.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF121214)),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC700),
                    foregroundColor: const Color(0xFF121214),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  icon: const Icon(Icons.receipt_long, size: 16),
                  label: Text(
                    job.invoice != null ? 'View Invoice & Pay' : 'View Breakdown',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => InvoiceDetailScreen(repairJobId: job.id)),
                    ).then((_) => _refreshData());
                  },
                ),
              ],
            ),
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

  void _showEmergencySosDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text('24/7 Roadside SOS', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Need emergency roadside assistance or urgent vehicle towing?\n\nOur Vroom dispatch team is standing by to assist your location.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.phone),
              label: const Text('CALL DISPATCH (+1-800-VROOM-SOS)'),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dispatching emergency tow truck to your GPS location...'),
                    backgroundColor: Colors.red,
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
