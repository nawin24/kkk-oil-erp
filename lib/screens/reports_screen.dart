import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/ui_components.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<DataProvider>();
    final sales = data.getFilteredSales(auth.currentUser).where((s) => !s.isCancelled).toList();

    double totalTurnover = 0.0;
    double totalTaxable = 0.0;
    double totalGst = 0.0;

    int b2bCount = 0;
    double b2bSales = 0.0;
    int b2cCount = 0;
    double b2cSales = 0.0;

    for (final s in sales) {
      totalTurnover += s.grandTotal;
      totalTaxable += s.subtotal;
      totalGst += s.gstTotal;

      if (s.gstin.isNotEmpty && s.gstin != 'URP') {
        b2bCount++;
        b2bSales += s.grandTotal;
      } else {
        b2cCount++;
        b2cSales += s.grandTotal;
      }
    }

    final halfGst = totalGst / 2;
    final isMobile = MediaQuery.of(context).size.width < 700;

    final metricCard1 = MetricCard(
      title: 'TOTAL GROSS TURNOVER',
      value: AppFormatters.inr(totalTurnover),
      subtitle: '${sales.length} Active Vouchers',
      icon: Icons.receipt_long,
      iconColor: AppColors.forestMedium,
      iconBg: AppColors.successBg,
    );

    final metricCard2 = MetricCard(
      title: 'NET TAXABLE VALUE',
      value: AppFormatters.inr(totalTaxable),
      subtitle: 'Pre-tax turnover base',
      icon: Icons.account_balance,
      iconColor: AppColors.info,
      iconBg: AppColors.infoBg,
    );

    final metricCard3 = MetricCard(
      title: 'GST TAX COLLECTED',
      value: AppFormatters.inr(totalGst),
      subtitle: 'Output GST liability',
      icon: Icons.pie_chart_outline,
      iconColor: AppColors.goldDeep,
      iconBg: AppColors.goldSoft,
    );

    final b2bCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('B2B Registered Supplies', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                StatusBadge(label: '$b2bCount Bills', tone: BadgeTone.info),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              AppFormatters.inr(b2bSales),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.info),
            ),
            const SizedBox(height: 4),
            const Text('Invoices with valid customer GSTIN registered on portal.', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );

    final b2cCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('B2C Retail & Counter Sales', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                StatusBadge(label: '$b2cCount Bills', tone: BadgeTone.gold),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              AppFormatters.inr(b2cSales),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.goldDeep),
            ),
            const SizedBox(height: 4),
            const Text('Direct retail consumers and unregistered party walk-ins.', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('GST Returns & Sales Turnover Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Executive summary of GSTR-1, outward supplies, and B2B/B2C breakup', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 16),

          // GST Metric Cards
          if (isMobile) ...[
            metricCard1,
            const SizedBox(height: 10),
            metricCard2,
            const SizedBox(height: 10),
            metricCard3,
          ] else
            Row(
              children: [
                Expanded(child: metricCard1),
                const SizedBox(width: 16),
                Expanded(child: metricCard2),
                const SizedBox(width: 16),
                Expanded(child: metricCard3),
              ],
            ),
          const SizedBox(height: 18),

          // GSTR-1 Tax Split Breakdown Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('GSTR-1 Tax Component Breakdown', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const Divider(height: 20),
                  if (isMobile)
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildTaxColumn('Taxable Value', AppFormatters.inr(totalTaxable))),
                            Expanded(child: _buildTaxColumn('Integrated Tax (IGST)', '₹0.00')),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(child: _buildTaxColumn('CGST (2.5%)', AppFormatters.inr(halfGst))),
                            Expanded(child: _buildTaxColumn('SGST (2.5%)', AppFormatters.inr(halfGst))),
                          ],
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTaxColumn('Total Taxable Value', AppFormatters.inr(totalTaxable)),
                        _buildTaxColumn('Central Tax (CGST 2.5%)', AppFormatters.inr(halfGst)),
                        _buildTaxColumn('State Tax (SGST 2.5%)', AppFormatters.inr(halfGst)),
                        _buildTaxColumn('Integrated Tax (IGST 5%)', '₹0.00'),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // B2B vs B2C Split Card
          if (isMobile) ...[
            b2bCard,
            const SizedBox(height: 12),
            b2cCard,
          ] else
            Row(
              children: [
                Expanded(child: b2bCard),
                const SizedBox(width: 16),
                Expanded(child: b2cCard),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTaxColumn(String label, String amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(amount, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.forestMedium)),
      ],
    );
  }
}
