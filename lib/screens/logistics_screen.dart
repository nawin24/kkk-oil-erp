import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/operations.dart';
import '../providers/data_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_components.dart';

class LogisticsScreen extends StatelessWidget {
  const LogisticsScreen({super.key});

  void _showNewDispatchDialog(BuildContext context) {
    final data = context.read<DataProvider>();
    final vehicleCtrl = TextEditingController(text: 'TN 28 BK 5521');
    final driverCtrl = TextEditingController(text: 'S. Shanmugam');
    final routeCtrl = TextEditingController(text: 'Kangeyam -> Coimbatore');
    final billCtrl = TextEditingController(text: data.sales.isNotEmpty ? data.sales.first.id : 'V-2026-001');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generate Dispatch Gate Pass', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: vehicleCtrl, decoration: const InputDecoration(labelText: 'Vehicle Number (e.g. TN 28 BK 5521)')),
                const SizedBox(height: 12),
                TextField(controller: driverCtrl, decoration: const InputDecoration(labelText: 'Driver Name')),
                const SizedBox(height: 12),
                TextField(controller: routeCtrl, decoration: const InputDecoration(labelText: 'Delivery Destination / Route')),
                const SizedBox(height: 12),
                TextField(controller: billCtrl, decoration: const InputDecoration(labelText: 'Linked Voucher / Bill No.')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          GoldButton(
            label: 'Issue Gate Pass',
            icon: Icons.check,
            onPressed: () {
              final dispatch = Dispatch(
                id: 'DSP-${DateTime.now().millisecondsSinceEpoch % 10000}',
                soId: billCtrl.text.trim().isEmpty ? 'V-2026-001' : billCtrl.text.trim(),
                vehicle: vehicleCtrl.text.trim().isEmpty ? 'TN 28 BK 5521' : vehicleCtrl.text.trim(),
                driver: driverCtrl.text.trim().isEmpty ? 'Driver' : driverCtrl.text.trim(),
                route: routeCtrl.text.trim().isEmpty ? 'Local Area' : routeCtrl.text.trim(),
                status: 'Dispatched',
                pod: false,
              );

              data.dispatches.insert(0, dispatch);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Logistics & Dispatches', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('${data.dispatches.length} vehicles & gate passes tracked', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: GoldButton(
                    icon: Icons.add,
                    label: 'New Gate Pass',
                    onPressed: () => _showNewDispatchDialog(context),
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Logistics & Vehicle Dispatches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Gate passes, driver manifests & delivery tracking (${data.dispatches.length} active)',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                GoldButton(
                  icon: Icons.add,
                  label: 'New Gate Pass',
                  onPressed: () => _showNewDispatchDialog(context),
                ),
              ],
            ),
          const SizedBox(height: 14),

          Expanded(
            child: Card(
              child: ListView.separated(
                padding: EdgeInsets.all(isMobile ? 8 : 12),
                itemCount: data.dispatches.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, idx) {
                  final d = data.dispatches[idx];
                  final isDelivered = d.status == 'Delivered';

                  if (isMobile) {
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDelivered ? AppColors.successBg : AppColors.infoBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.local_shipping_outlined,
                                    color: isDelivered ? AppColors.success : AppColors.info, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(d.vehicle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                    const SizedBox(height: 2),
                                    Text('Driver: ${d.driver}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusBadge(
                                label: d.status,
                                tone: isDelivered ? BadgeTone.success : BadgeTone.info,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text('Route: ${d.route}',
                                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                      overflow: TextOverflow.ellipsis),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  d.pod ? 'POD Received ✓' : 'POD Pending',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: d.pod ? AppColors.success : AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDelivered ? AppColors.successBg : AppColors.infoBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.local_shipping_outlined, color: isDelivered ? AppColors.success : AppColors.info, size: 22),
                    ),
                    title: Row(
                      children: [
                        Text(d.vehicle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(width: 8),
                        Text('• ${d.driver}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        const Spacer(),
                        StatusBadge(
                          label: d.status,
                          tone: isDelivered ? BadgeTone.success : BadgeTone.info,
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Text('Route: ${d.route} • Bill No: ${d.soId}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          const Spacer(),
                          Text(d.pod ? 'POD Received ✓' : 'POD Pending',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: d.pod ? AppColors.success : AppColors.warning)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
