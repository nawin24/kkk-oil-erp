import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/company.dart';
import '../models/customer.dart';
import '../models/sales_order.dart';
import '../services/pdf_invoice_service.dart';
import '../theme/app_theme.dart';

class InvoicePrintDialog extends StatelessWidget {
  final SalesOrder order;
  final Company company;
  final Customer? customer;

  const InvoicePrintDialog({
    super.key,
    required this.order,
    required this.company,
    this.customer,
  });

  static Future<void> show(
    BuildContext context, {
    required SalesOrder order,
    required Company company,
    Customer? customer,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => InvoicePrintDialog(
        order: order,
        company: company,
        customer: customer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 800,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: order.isGst ? AppColors.forestMedium : AppColors.goldDark,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.print, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${order.voucherType} — ${order.voucherNo}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Amount: ₹${order.grandTotal.toStringAsFixed(2)} | Date: ${order.date}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: PdfPreview(
                  build: (format) => PdfInvoiceService.generateInvoicePdf(
                    order: order,
                    company: company,
                    customer: customer,
                  ),
                  allowPrinting: true,
                  allowSharing: true,
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                  canDebug: false,
                  pdfFileName: '${order.voucherNo}.pdf',
                  previewPageMargin: EdgeInsets.zero,
                  loadingWidget: const Center(
                    child: CircularProgressIndicator(color: AppColors.forestMedium),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
