import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/repair_job_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../models/repair_job_model.dart';
import '../../models/spare_part_model.dart';
import '../invoice/invoice_detail_screen.dart';

class RepairJobDetailScreen extends StatefulWidget {
  final int repairJobId;

  const RepairJobDetailScreen({super.key, required this.repairJobId});

  @override
  State<RepairJobDetailScreen> createState() => _RepairJobDetailScreenState();
}

class _RepairJobDetailScreenState extends State<RepairJobDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final rProvider = Provider.of<RepairJobProvider>(context, listen: false);
    final iProvider = Provider.of<InventoryProvider>(context, listen: false);
    await Future.wait([
      rProvider.fetchRepairJobs(),
      rProvider.fetchMechanics(),
      iProvider.fetchSpareParts(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final rProvider = Provider.of<RepairJobProvider>(context);
    final iProvider = Provider.of<InventoryProvider>(context);

    final jobList = rProvider.repairJobs.where((j) => j.id == widget.repairJobId).toList();
    if (jobList.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Repair Job Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final job = jobList.first;

    return Scaffold(
      appBar: AppBar(
        title: Text('Repair Job #${job.id}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Vehicle & Check-In Header Card (Vehicle Inspection Details)
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                            job.vehicle?.displayName ?? 'Vehicle #${job.vehicle?.id}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF121214)),
                          ),
                        ),
                        // Quick Status Update Selector Dropdown
                        DropdownButtonHideUnderline(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getStatusColor(job.status),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: DropdownButton<String>(
                              value: ['PENDING', 'IN_PROGRESS', 'WAITING_FOR_PARTS', 'COMPLETED'].contains(job.status) ? job.status : 'IN_PROGRESS',
                              dropdownColor: const Color(0xFF18181B),
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              items: const [
                                DropdownMenuItem(value: 'PENDING', child: Text('PENDING', style: TextStyle(color: Colors.white))),
                                DropdownMenuItem(value: 'IN_PROGRESS', child: Text('IN PROGRESS', style: TextStyle(color: Colors.white))),
                                DropdownMenuItem(value: 'WAITING_FOR_PARTS', child: Text('WAITING FOR PARTS', style: TextStyle(color: Colors.white))),
                                DropdownMenuItem(value: 'COMPLETED', child: Text('COMPLETED', style: TextStyle(color: Colors.white))),
                              ],
                              onChanged: (newStatus) async {
                                if (newStatus != null && newStatus != job.status) {
                                  await rProvider.updateJobStatus(job.id, newStatus);
                                  _loadData();
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildDetailItem('Odometer Mileage', '${job.checkInMileage} km'),
                        _buildDetailItem('Fuel Gauge', job.fuelLevel),
                        _buildDetailItem('Assigned Tech', job.mechanic?.displayName ?? 'Unassigned'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Body Inspection: ${job.vehicleCondition.isNotEmpty ? job.vehicleCondition : "No visible scratches/scuffs"}',
                              style: TextStyle(color: Colors.grey.shade800, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 2. Timeline Progress Indicator
            const Text('Repair Progress Timeline', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildTimeline(job.status),

            const SizedBox(height: 20),

            // Mechanic Assignment Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.engineering, color: Color(0xFF18181B)),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Assigned Mechanic', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(
                              job.mechanic?.displayName ?? 'Unassigned',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () => _showAssignMechanicDialog(job, rProvider),
                      icon: const Icon(Icons.person_add),
                      label: Text(job.mechanic == null ? 'Assign' : 'Reassign'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 3. Technician Repair Notes Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.edit_note, color: Color(0xFF18181B)),
                            SizedBox(width: 8),
                            Text('Technician Repair Notes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () => _showEditRepairNoteDialog(job, rProvider),
                          icon: const Icon(Icons.edit, size: 16),
                          label: Text(job.repairNote.isEmpty ? 'Add Note' : 'Edit'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job.repairNote.isNotEmpty ? job.repairNote : 'No repair notes logged by technician yet.',
                      style: TextStyle(fontSize: 13, color: job.repairNote.isNotEmpty ? Colors.black87 : Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 4. Diagnoses Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Diagnoses & Vehicle Inspection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Color(0xFF18181B)),
                  onPressed: () => _showAddDiagnosisDialog(job.id, rProvider),
                ),
              ],
            ),
            if (job.diagnoses.isEmpty)
              const Text('No diagnoses logged yet.', style: TextStyle(color: Colors.grey))
            else
              ...job.diagnoses.map((d) => Card(
                color: Colors.amber.shade50,
                child: ListTile(
                  title: Text('Finding: ${d.finding}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Action: ${d.recommendedAction}'),
                ),
              )),

            const SizedBox(height: 20),

            // 5. Spare Parts Used Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Spare Parts Used / Required', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.playlist_add, color: Color(0xFF18181B)),
                  onPressed: () => _showAddPartUsageDialog(job.id, rProvider, iProvider),
                ),
              ],
            ),
            if (job.partUsages.isEmpty)
              const Text('No spare parts recorded.', style: TextStyle(color: Colors.grey))
            else
              ...job.partUsages.map((pu) => Card(
                child: ListTile(
                  leading: const Icon(Icons.extension_outlined),
                  title: Text(pu.part?.partName ?? 'Part #${pu.id}'),
                  subtitle: Text('Qty: ${pu.quantityUsed} x \$${pu.unitPrice.toStringAsFixed(2)}'),
                  trailing: Text('\$${pu.partsCost.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              )),

            const SizedBox(height: 32),

            // Action Buttons Row (Generate Invoice & Complete / Handover to Receptionist)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final nav = Navigator.of(context);
                      final success = await rProvider.generateInvoice(job.id);
                      if (!mounted || !success) return;
                      nav.push(
                        MaterialPageRoute(
                          builder: (_) => InvoiceDetailScreen(repairJobId: job.id),
                        ),
                      ).then((_) {
                        if (mounted) _loadData();
                      });
                    },
                    icon: const Icon(Icons.receipt, color: Color(0xFF18181B)),
                    label: const Text('INVOICE', style: TextStyle(color: Color(0xFF18181B), fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFF18181B)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: job.status == 'COMPLETED'
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final ok = await rProvider.completeJob(job.id);
                            if (!mounted || !ok) return;
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Job Completed! Forwarded to Receptionist for customer notification & billing.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            _loadData();
                          },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('COMPLETE & SEND TO DESK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFFFFC700),
                      foregroundColor: const Color(0xFF121214),
                    ),
                  ),
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
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? const Color(0xFF1E3A8A) : Colors.grey.shade300,
                ),
                child: Icon(
                  isDone ? Icons.check : Icons.circle,
                  color: isDone ? Colors.white : Colors.grey,
                  size: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                steps[index].replaceAll('_', ' '),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                  color: isDone ? const Color(0xFF1E3A8A) : Colors.grey,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDetailItem(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'COMPLETED': return Colors.green;
      case 'IN_PROGRESS': return Colors.blue;
      case 'WAITING_FOR_PARTS': return Colors.amber;
      default: return Colors.orange;
    }
  }

  void _showEditRepairNoteDialog(RepairJobModel job, RepairJobProvider rProvider) {
    final noteCtrl = TextEditingController(text: job.repairNote);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Technician Repair Note', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: noteCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Enter technical repair notes, work done, or observations...',
              border: OutlineInputBorder(),
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
                final ok = await rProvider.updateRepairNote(job.id, noteCtrl.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
                if (ok) _loadData();
              },
              child: const Text('Save Note', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showAssignMechanicDialog(RepairJobModel job, RepairJobProvider rProvider) {
    int? selectedMechId = job.mechanic?.id;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSt) {
            return AlertDialog(
              title: const Text('Assign Mechanic'),
              content: DropdownButtonFormField<int>(
                initialValue: selectedMechId,
                items: rProvider.mechanics.map((m) {
                  return DropdownMenuItem(
                    value: m.id,
                    child: Text('${m.displayName} (${m.specialization})'),
                  );
                }).toList(),
                onChanged: (val) => setSt(() => selectedMechId = val),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedMechId != null) {
                      await rProvider.assignMechanic(job.id, selectedMechId!);
                      if (ctx.mounted) Navigator.pop(ctx);
                      _loadData();
                    }
                  },
                  child: const Text('Assign'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddDiagnosisDialog(int repairJobId, RepairJobProvider rProvider) {
    final findingCtrl = TextEditingController();
    final actionCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Diagnosis'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: findingCtrl, decoration: const InputDecoration(labelText: 'Finding / Issue')),
              const SizedBox(height: 12),
              TextField(controller: actionCtrl, decoration: const InputDecoration(labelText: 'Recommended Action')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (findingCtrl.text.isNotEmpty) {
                  await rProvider.addDiagnosis(repairJobId, findingCtrl.text, actionCtrl.text);
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadData();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showAddPartUsageDialog(int repairJobId, RepairJobProvider rProvider, InventoryProvider iProvider) {
    SparePartModel? selectedPart;
    int qty = 1;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSt) {
            return AlertDialog(
              title: const Text('Log Spare Part Usage'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<SparePartModel>(
                    initialValue: selectedPart,
                    decoration: const InputDecoration(labelText: 'Select Spare Part'),
                    items: iProvider.spareParts.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text('${p.partName} (Stock: ${p.quantity})'),
                      );
                    }).toList(),
                    onChanged: (val) => setSt(() => selectedPart = val),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Quantity Used: '),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: qty > 1 ? () => setSt(() => qty--) : null,
                      ),
                      Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setSt(() => qty++),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedPart != null) {
                      final messenger = ScaffoldMessenger.of(context);
                      final success = await rProvider.addPartUsage(repairJobId, selectedPart!.id, qty);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (!success && mounted) {
                        messenger.showSnackBar(
                          SnackBar(content: Text(rProvider.errorMessage ?? 'Part usage failed'), backgroundColor: Colors.red),
                        );
                      }
                      if (mounted) _loadData();
                    }
                  },
                  child: const Text('Add Part'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
