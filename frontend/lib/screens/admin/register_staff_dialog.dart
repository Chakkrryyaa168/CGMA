import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class RegisterStaffDialog extends StatefulWidget {
  final String role; // RECEPTIONIST, MECHANIC, ADMIN

  const RegisterStaffDialog({super.key, required this.role});

  @override
  State<RegisterStaffDialog> createState() => _RegisterStaffDialogState();
}

class _RegisterStaffDialogState extends State<RegisterStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController(text: 'staff123');
  final _specializationController = TextEditingController(); // For Mechanics

  bool _isSubmitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _specializationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.register(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      fullName: _fullNameController.text.trim(),
      role: widget.role,
      phone: _phoneController.text.trim(),
      specialization: _specializationController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.role} account created successfully! Initial password: staff123'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String roleTitle = widget.role == 'RECEPTIONIST'
        ? 'Receptionist'
        : widget.role == 'MECHANIC'
            ? 'Mechanic'
            : 'Staff Member';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.person_add_alt_1, color: Color(0xFFFFC700)),
          const SizedBox(width: 10),
          Text('Register $roleTitle', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Full name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address *',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (val) => val == null || !val.contains('@') ? 'Valid email is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Phone number is required' : null,
              ),
              if (widget.role == 'MECHANIC') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _specializationController,
                  decoration: const InputDecoration(
                    labelText: 'Specialization (e.g. Engine, Brakes, Transmission)',
                    prefixIcon: Icon(Icons.build_circle),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Default Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (val) => val == null || val.length < 6 ? 'Min 6 characters' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFC700),
            foregroundColor: const Color(0xFF121214),
          ),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF121214)))
              : Text('Create $roleTitle', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
