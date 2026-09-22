import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/repair_job_provider.dart';
import '../../providers/inventory_provider.dart';
import '../repair_job/repair_job_detail_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
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
      rProvider.fetchMechanics(),
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
    final lowStockParts = iProvider.lowStockParts;

    double estimatedRevenue = 0.0;
    for (var j in rProvider.repairJobs) {
      if (j.invoice != null) {
        estimatedRevenue += j.invoice!.totalAmount;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Admin Executive Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Admin Header Banner
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
                        child: Icon(Icons.admin_panel_settings, size: 30, color: Color(0xFF121214)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Admin: ${auth.currentUser?.fullName ?? "Administrator"}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Executive Dashboard • Operations & Inventory',
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

              // Executive Analytics Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _buildMetricCard(
                    title: 'Revenue Generated',
                    value: '\$${estimatedRevenue.toStringAsFixed(2)}',
                    icon: Icons.attach_money,
                    color: Colors.green.shade700,
                  ),
                  _buildMetricCard(
                    title: 'Active Work Orders',
                    value: '${activeJobs.length}',
                    icon: Icons.engineering,
                    color: const Color(0xFF121214),
                  ),
                  _buildMetricCard(
                    title: 'Total Bookings',
                    value: '${bProvider.bookings.length}',
                    icon: Icons.event_available,
                    color: const Color(0xFFD97706),
                  ),
                  _buildMetricCard(
                    title: 'Low Stock Alerts',
                    value: '${lowStockParts.length}',
                    icon: Icons.warning_amber,
                    color: Colors.red.shade700,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Section: All Garage Work Orders
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Active Garage Work Orders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF121214))),
                  Text(
                    '${activeJobs.length} In Progress',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (rProvider.isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              else if (activeJobs.isEmpty)
                _buildEmptyCard('No active repair jobs across garage.')
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF18181B),
                          child: Icon(Icons.build, color: Color(0xFFFFC700), size: 20),
                        ),
                        title: Text(job.vehicle?.displayName ?? 'Job #${job.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Status: ${job.status} | Mechanic: ${job.mechanic?.displayName ?? "Unassigned"}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        trailing: const Icon(Icons.chevron_right, color: Color(0xFF121214)),
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

              const SizedBox(height: 24),

              // Section: Low Stock Inventory Alerts
              if (lowStockParts.isNotEmpty) ...[
                const Text('Critical Inventory Alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(height: 8),
                Card(
                  color: Colors.red.shade50,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: lowStockParts.map((part) => ListTile(
                      leading: const Icon(Icons.warning_amber, color: Colors.red),
                      title: Text(part.partName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Part #${part.partNumber} | Qty Remaining: ${part.quantity} (Min: ${part.minStockQty})'),
                      trailing: Text('\$${part.unitPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    )).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({required String title, required String value, required IconData icon, required Color color}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
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
