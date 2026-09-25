import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/repair_job_provider.dart';
import '../repair_job/repair_job_detail_screen.dart';

class MechanicDashboard extends StatefulWidget {
  const MechanicDashboard({super.key});

  @override
  State<MechanicDashboard> createState() => _MechanicDashboardState();
}

class _MechanicDashboardState extends State<MechanicDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    final rProvider = Provider.of<RepairJobProvider>(context, listen: false);
    await rProvider.fetchRepairJobs();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final rProvider = Provider.of<RepairJobProvider>(context);

    // Filter jobs assigned to logged-in mechanic
    final myJobs = rProvider.repairJobs.where((j) {
      if (j.mechanic?.user?.id != null && auth.currentUser?.id != null) {
        return j.mechanic!.user!.id == auth.currentUser!.id;
      }
      return true; // Show all if unassigned filter
    }).toList();

    final activeJobs = myJobs.where((j) => j.status != 'COMPLETED' && j.status != 'CANCELLED').toList();
    final completedJobs = myJobs.where((j) => j.status == 'COMPLETED').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Mechanic Workbench'),
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
              // Mechanic Header Banner
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
                        child: Icon(Icons.build, size: 30, color: Color(0xFF121214)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mechanic: ${auth.currentUser?.fullName ?? "Technician"}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${activeJobs.length} Active Work Orders Assigned',
                              style: const TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Section 1: My Active Assigned Jobs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('My Active Work Orders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF121214))),
                  Chip(
                    label: Text('${activeJobs.length} Active'),
                    backgroundColor: const Color(0xFFFFC700),
                    labelStyle: const TextStyle(color: Color(0xFF121214), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (rProvider.isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              else if (activeJobs.isEmpty)
                _buildEmptyCard('No active repair jobs assigned to you currently.')
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activeJobs.length,
                  itemBuilder: (context, index) {
                    final job = activeJobs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFF18181B),
                                child: Icon(Icons.directions_car, color: Color(0xFFFFC700), size: 20),
                              ),
                              title: Text(job.vehicle?.displayName ?? 'Job #${job.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Condition: ${job.vehicleCondition.isNotEmpty ? job.vehicleCondition : "Normal"}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF18181B),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  job.status,
                                  style: const TextStyle(color: Color(0xFFFFC700), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Diagnoses: ${job.diagnoses.length} | Parts: ${job.partUsages.length}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.handyman, size: 14),
                                  label: const Text('OPEN WORKBENCH', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFC700),
                                    foregroundColor: const Color(0xFF121214),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => RepairJobDetailScreen(repairJobId: job.id)),
                                    ).then((_) => _refreshData());
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 24),

              // Section 2: Completed Repair History
              if (completedJobs.isNotEmpty) ...[
                const Text('My Completed Work History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF121214))),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: completedJobs.length,
                  itemBuilder: (context, index) {
                    final job = completedJobs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: const Icon(Icons.check_circle, color: Colors.green),
                        title: Text(job.vehicle?.displayName ?? 'Job #${job.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Completed • Check-In Mileage: ${job.checkInMileage} km', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
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
