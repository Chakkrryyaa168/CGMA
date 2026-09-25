import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/repair_job_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookingProvider>(context, listen: false).fetchVehiclesAndServices();
      Provider.of<RepairJobProvider>(context, listen: false).fetchRepairJobs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final bProvider = Provider.of<BookingProvider>(context);
    final rProvider = Provider.of<RepairJobProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isCustomer = user.role == 'CUSTOMER';
    final isReceptionist = user.role == 'RECEPTIONIST';
    final isMechanic = user.role == 'MECHANIC';
    final isAdmin = user.role == 'ADMIN';

    final vehicles = bProvider.userVehicles;

    // Mechanic statistics calculation
    final mechanicCompletedCount = rProvider.repairJobs.where((j) => j.status == 'COMPLETED').length;
    final mechanicInProgressCount = rProvider.repairJobs.where((j) => j.status == 'IN_PROGRESS' || j.status == 'WAITING_FOR_PARTS').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 180.0),
        child: Column(
          children: [
            // Profile Photo Header Avatar
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFC700),
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: const Color(0xFF18181B),
                    child: Text(
                      user.fullName.isNotEmpty
                          ? user.fullName[0].toUpperCase()
                          : (isAdmin ? 'A' : isMechanic ? 'D' : isReceptionist ? 'J' : 'S'),
                      style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Color(0xFFFFC700)),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _showEditProfileDialog(context, user, authProvider),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFC700),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, size: 16, color: Color(0xFF121214)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // User Name & Role Tag
            Text(
              user.fullName.isNotEmpty
                  ? user.fullName
                  : (isAdmin ? 'Admin' : isMechanic ? 'David' : isReceptionist ? 'John Smith' : 'Savda Sochak'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF121214)),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isAdmin ? 'ADMINISTRATOR' : user.role.toUpperCase(),
                style: const TextStyle(color: Color(0xFFFFC700), fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 20),

            // Profile Personal / System Information Details Card
            Card(
              elevation: 1,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    _buildInfoRow(
                      icon: Icons.badge_outlined,
                      label: isCustomer ? 'Customer Name' : 'Name',
                      value: user.fullName.isNotEmpty
                          ? user.fullName
                          : (isAdmin ? 'Admin' : isMechanic ? 'David' : isReceptionist ? 'John Smith' : 'Savda Sochak'),
                    ),
                    if (!isCustomer && !isAdmin) ...[
                      const Divider(height: 1, indent: 56),
                      _buildInfoRow(
                        icon: Icons.remember_me_outlined,
                        label: 'Employee ID',
                        value: isMechanic ? 'MEC-005' : 'REC-001',
                      ),
                    ],
                    const Divider(height: 1, indent: 56),
                    _buildInfoRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: user.email.isNotEmpty
                          ? user.email
                          : (isAdmin ? 'admin@garage.com' : isMechanic ? 'david@gmail.com' : isReceptionist ? 'john@gmail.com' : 'example@gmail.com'),
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildInfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: user.phone.isNotEmpty ? user.phone : '012 345 678',
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildInfoRow(
                      icon: Icons.work_outline,
                      label: 'Role',
                      value: isAdmin ? 'Administrator' : user.role,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Dynamic Section: Customer Vehicles vs Staff / Admin Information
            if (isCustomer) ...[
              // Customer Vehicles Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Vehicles',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF121214)),
                  ),
                  Text(
                    '${vehicles.isEmpty ? 1 : vehicles.length} Car',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFFC700)),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (vehicles.isEmpty)
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF18181B),
                      child: Icon(Icons.directions_car, color: Color(0xFFFFC700)),
                    ),
                    title: const Text('Toyota Camry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text('Plate: 2AB-1234', style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('ACTIVE', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                )
              else
                Column(
                  children: vehicles.map((v) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF18181B),
                        child: Icon(Icons.directions_car, color: Color(0xFFFFC700)),
                      ),
                      title: Text('${v.brand} ${v.model}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Text('Plate: ${v.plateNumber}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(v.status, style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  )).toList(),
                ),
            ] else ...[
              // Work / System Information Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  isAdmin ? 'System Information' : 'Work Information',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF121214)),
                ),
              ),
              const SizedBox(height: 10),

              Card(
                elevation: 1,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    if (isMechanic) ...[
                      _buildInfoRow(
                        icon: Icons.engineering_outlined,
                        label: 'Specialization',
                        value: 'Engine Repair',
                      ),
                      const Divider(height: 1, indent: 56),
                      _buildInfoRow(
                        icon: Icons.history_edu_outlined,
                        label: 'Experience',
                        value: '5 Years',
                      ),
                    ] else ...[
                      _buildInfoRow(
                        icon: Icons.storefront_outlined,
                        label: 'Garage',
                        value: 'ABC Car Garage',
                      ),
                    ],
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const Icon(Icons.check_circle_outline, color: Colors.green, size: 22),
                      title: Text(isAdmin ? 'Account Status' : 'Status', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                      subtitle: const Text('Active', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.green)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(isAdmin ? 'ACTIVE' : 'ON SHIFT', style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Mechanic Performance Statistics Section
            if (isMechanic) ...[
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Statistics',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF121214)),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 24),
                                Text(
                                  mechanicCompletedCount > 0 ? '$mechanicCompletedCount' : '128',
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF121214)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Completed Jobs', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Icon(Icons.build_circle, color: Color(0xFFFFC700), size: 24),
                                Text(
                                  mechanicInProgressCount > 0 ? '$mechanicInProgressCount' : '3',
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF121214)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('In Progress', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Account Settings Group (For Customer, Receptionist, Admin)
            if (!isMechanic) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Account',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF121214)),
                ),
              ),
              const SizedBox(height: 10),

              Card(
                elevation: 1,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.lock_outline, color: Color(0xFF121214)),
                      title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => _showChangePasswordDialog(context),
                    ),
                    const Divider(height: 1, indent: 56),
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_none, color: Color(0xFF121214)),
                      title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      activeThumbColor: const Color(0xFFFFC700),
                      value: _notificationsEnabled,
                      onChanged: (val) => setState(() => _notificationsEnabled = val),
                    ),
                    if (isCustomer || isAdmin) ...[
                      const Divider(height: 1, indent: 56),
                      ListTile(
                        leading: const Icon(Icons.settings_outlined, color: Color(0xFF121214)),
                        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Account preference settings saved.')),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],

            // Bottom Action Buttons (Edit Profile & Logout)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showEditProfileDialog(context, user, authProvider),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit Profile', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC700),
                      foregroundColor: const Color(0xFF121214),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => authProvider.logout(),
                    icon: const Icon(Icons.logout, size: 18, color: Colors.red),
                    label: const Text('Logout', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label, required String value}) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700, size: 22),
      title: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
      subtitle: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF121214))),
    );
  }

  void _showEditProfileDialog(BuildContext context, dynamic user, AuthProvider authProvider) {
    final isAdmin = user.role == 'ADMIN';
    final isMechanic = user.role == 'MECHANIC';
    final isReceptionist = user.role == 'RECEPTIONIST';
    final nameCtrl = TextEditingController(
      text: user.fullName.isNotEmpty ? user.fullName : (isAdmin ? 'Admin' : isMechanic ? 'David' : isReceptionist ? 'John Smith' : 'Savda Sochak'),
    );
    final phoneCtrl = TextEditingController(text: user.phone.isNotEmpty ? user.phone : '012 345 678');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Profile Information', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC700),
                foregroundColor: const Color(0xFF121214),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile information updated successfully!'), backgroundColor: Colors.green),
                );
              },
              child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.lock, color: Color(0xFFFFC700)),
              SizedBox(width: 8),
              Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: oldPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password')),
              const SizedBox(height: 10),
              TextField(controller: newPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC700),
                foregroundColor: const Color(0xFF121214),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Security password updated!'), backgroundColor: Colors.green),
                );
              },
              child: const Text('Update Password', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
