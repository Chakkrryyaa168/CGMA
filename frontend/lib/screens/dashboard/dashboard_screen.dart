import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/repair_job_provider.dart';
import '../../providers/inventory_provider.dart';
import '../booking/create_booking_screen.dart';
import '../repair_job/repair_job_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
    final iProvider = Provider.of<InventoryProvider>(context, listen: false);

    await Future.wait([
      bProvider.fetchBookings(),
      rProvider.fetchRepairJobs(),
      iProvider.fetchSpareParts(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final bProvider = Provider.of<BookingProvider>(context);
    final rProvider = Provider.of<RepairJobProvider>(context);
    final iProvider = Provider.of<InventoryProvider>(context);

    final activeJobs = rProvider.repairJobs.where((j) => j.status != 'COMPLETED' && j.status != 'CANCELLED').toList();
    final todayBookings = bProvider.bookings.where((b) => b.status == 'PENDING' || b.status == 'CONFIRMED' || b.status == 'CHECKED_IN').toList();
    final lowStockParts = iProvider.lowStockParts;

    return Scaffold(
      appBar: AppBar(
        title: Text('CGMS Dashboard (${auth.userRole})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh Data',
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
          icon: const Icon(Icons.add),
          label: const Text('New Booking'),
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
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
              // Welcome Banner
              Card(
                color: const Color(0xFF1E3A8A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.amber,
                        child: Icon(Icons.garage, size: 32, color: Colors.black87),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${auth.currentUser?.fullName ?? 'User'}!',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Role: ${auth.userRole} | Garage Operations Active',
                              style: const TextStyle(fontSize: 13, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Summary Stats Row
              Row(
                children: [
                  _buildStatCard(
                    title: 'Active Jobs',
                    value: activeJobs.length.toString(),
                    icon: Icons.build_circle_outlined,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    title: 'Bookings',
                    value: bProvider.bookings.length.toString(),
                    icon: Icons.calendar_today_outlined,
                    color: Colors.amber.shade800,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    title: 'Low Stock',
                    value: lowStockParts.length.toString(),
                    icon: Icons.warning_amber_rounded,
                    color: Colors.red.shade700,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Section 1: Active Repair Jobs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Active Repair Jobs',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextChip(count: activeJobs.length, label: 'Jobs'),
                ],
              ),
              const SizedBox(height: 8),

              if (rProvider.isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              else if (activeJobs.isEmpty)
                _buildEmptyCard('No active repair jobs in progress.')
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activeJobs.length,
                  itemBuilder: (context, index) {
                    final job = activeJobs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(job.status).withValues(alpha: 0.15),
                          child: Icon(Icons.directions_car, color: _getStatusColor(job.status)),
                        ),
                        title: Text(
                          job.vehicle?.displayName ?? 'Repair Job #${job.id}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Status: ${job.status} | Mechanic: ${job.mechanic?.displayName ?? "Unassigned"}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RepairJobDetailScreen(repairJobId: job.id),
                            ),
                          ).then((_) => _refreshData());
                        },
                      ),
                    );
                  },
                ),

              const SizedBox(height: 24),

              // Section 2: Recent Bookings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Upcoming Service Bookings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextChip(count: todayBookings.length, label: 'Bookings'),
                ],
              ),
              const SizedBox(height: 8),

              if (bProvider.isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              else if (todayBookings.isEmpty)
                _buildEmptyCard('No upcoming service bookings.')
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: todayBookings.length,
                  itemBuilder: (context, index) {
                    final booking = todayBookings[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(Icons.event, color: Color(0xFF1E3A8A)),
                        title: Text(booking.vehicle?.displayName ?? 'Booking #${booking.id}'),
                        subtitle: Text('${booking.service?.name ?? "Service"}\nDate: ${booking.bookingDate} at ${booking.bookingTime}'),
                        isThreeLine: true,
                        trailing: Chip(
                          label: Text(booking.status, style: const TextStyle(fontSize: 11, color: Colors.white)),
                          backgroundColor: booking.status == 'CHECKED_IN' ? Colors.green : Colors.orange,
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 24),

              // Section 3: Inventory Stock Alerts
              if (lowStockParts.isNotEmpty) ...[
                const Text(
                  'Inventory Alerts (Low / Out of Stock)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                ),
                const SizedBox(height: 8),
                Card(
                  color: Colors.red.shade50,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: lowStockParts.map((part) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.warning, color: Colors.red),
                        title: Text(part.partName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Part #${part.partNumber} | Qty Remaining: ${part.quantity} (Min: ${part.minStockQty})'),
                        trailing: Text('\$${part.unitPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      )).toList(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color color}) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Column(
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Text(message, style: TextStyle(color: Colors.grey.shade600)),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'COMPLETED': return Colors.green;
      case 'IN_PROGRESS': return Colors.blue;
      case 'WAITING_FOR_PARTS': return Colors.amber;
      case 'CANCELLED': return Colors.red;
      default: return Colors.orange;
    }
  }
}

class TextChip extends StatelessWidget {
  final int count;
  final String label;

  const TextChip({super.key, required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count $label',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
      ),
    );
  }
}
