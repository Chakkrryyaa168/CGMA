import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/repair_job_provider.dart';
import '../../providers/inventory_provider.dart';
import '../repair_job/repair_job_detail_screen.dart';
import '../customer_vehicle/register_customer_dialog.dart';
import '../admin/register_staff_dialog.dart';
import '../admin/manage_services_dialog.dart';
import '../admin/add_spare_part_dialog.dart';

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
    final completedJobs = rProvider.repairJobs.where((j) => j.status == 'COMPLETED').toList();
    final lowStockParts = iProvider.lowStockParts;

    double revenueGenerated = 0.0;
    for (var j in rProvider.repairJobs) {
      if (j.invoice != null) {
        revenueGenerated += j.invoice!.totalAmount;
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
              // Admin Executive Header Banner
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
                              'Master Control • System Settings & Operations',
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

              // Quick Executive Action Hub Row
              const Text('Management Actions Console', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF121214))),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildAdminActionButton(
                      label: '+ Add Mechanic',
                      icon: Icons.engineering,
                      color: const Color(0xFF18181B),
                      textColor: const Color(0xFFFFC700),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => const RegisterStaffDialog(role: 'MECHANIC'),
                        ).then((_) => _refreshData());
                      },
                    ),
                    _buildAdminActionButton(
                      label: '+ Add Receptionist',
                      icon: Icons.person_add,
                      color: const Color(0xFF18181B),
                      textColor: const Color(0xFFFFC700),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => const RegisterStaffDialog(role: 'RECEPTIONIST'),
                        ).then((_) => _refreshData());
                      },
                    ),
                    _buildAdminActionButton(
                      label: '+ Add Customer',
                      icon: Icons.group_add,
                      color: const Color(0xFFFFC700),
                      textColor: const Color(0xFF121214),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => const RegisterCustomerDialog(),
                        ).then((_) => _refreshData());
                      },
                    ),
                    _buildAdminActionButton(
                      label: 'Services & Prices',
                      icon: Icons.design_services,
                      color: const Color(0xFF18181B),
                      textColor: Colors.white,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => const ManageServicesDialog(),
                        ).then((_) => _refreshData());
                      },
                    ),
                    _buildAdminActionButton(
                      label: '+ Spare Part SKU',
                      icon: Icons.inventory_2,
                      color: Colors.blue.shade900,
                      textColor: Colors.white,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => const AddSparePartDialog(),
                        ).then((_) => _refreshData());
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Executive Analytics Grid
              const Text('System Reports & Performance Statistics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF121214))),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _buildMetricCard(
                    title: 'Total Revenue Collected',
                    value: '\$${revenueGenerated.toStringAsFixed(2)}',
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
                    title: 'Service Bookings',
                    value: '${bProvider.bookings.length}',
                    icon: Icons.event_available,
                    color: const Color(0xFFD97706),
                  ),
                  _buildMetricCard(
                    title: 'Low Stock SKU Alerts',
                    value: '${lowStockParts.length}',
                    icon: Icons.warning_amber,
                    color: Colors.red.shade700,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Section: All Garage Work Orders & Status Monitor
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('All Service Jobs & Work Orders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF121214))),
                  Text(
                    '${rProvider.repairJobs.length} Total Jobs (${completedJobs.length} Paid)',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (rProvider.isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              else if (rProvider.repairJobs.isEmpty)
                _buildEmptyCard('No repair jobs found in system database.')
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rProvider.repairJobs.length,
                  itemBuilder: (context, index) {
                    final job = rProvider.repairJobs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF18181B),
                          child: Icon(
                            job.status == 'COMPLETED' ? Icons.check_circle : Icons.build,
                            color: job.status == 'COMPLETED' ? Colors.green : const Color(0xFFFFC700),
                            size: 20,
                          ),
                        ),
                        title: Text(job.vehicle?.displayName ?? 'Job #${job.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Status: ${job.status.replaceAll('_', ' ')} | Tech: ${job.mechanic?.displayName ?? "Unassigned"}\n'
                          'Bill: \$${job.invoice?.totalAmount.toStringAsFixed(2) ?? "0.00"}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        isThreeLine: true,
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

              // Section: Low Stock Spare Parts & Inventory Alerts
              if (lowStockParts.isNotEmpty) ...[
                const Text('Critical Inventory & Spare Part Alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
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
                      subtitle: Text('SKU #${part.partNumber} | Qty Remaining: ${part.quantity} (Min: ${part.minStockQty})'),
                      trailing: Text('\$${part.unitPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // System Settings Card
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF18181B),
                    child: Icon(Icons.settings, color: Color(0xFFFFC700)),
                  ),
                  title: const Text('System & Workshop Configuration Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Tax Rate (7%), Currency (\$), Automated Reminders Active', style: TextStyle(fontSize: 11)),
                  trailing: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('System configuration is operating under optimal default settings.')),
                      );
                    },
                    child: const Text('Configure'),
                  ),
                ),
              ),
              const SizedBox(height: 180),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        onPressed: onTap,
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
