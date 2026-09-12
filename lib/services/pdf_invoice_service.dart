import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/company.dart';
import '../models/customer.dart';
import '../models/sales_order.dart';
import '../utils/formatters.dart';

class PdfInvoiceService {
  static Future<Uint8List> generateInvoicePdf({
    required SalesOrder order,
    required Company company,
    Customer? customer,
  }) async {
    final pdf = pw.Document();
    pw.Font font;
    pw.Font fontBold;
    try {
      font = await PdfGoogleFonts.notoSansRegular();
      fontBold = await PdfGoogleFonts.notoSansBold();
    } catch (_) {
      font = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    final isGst = order.isGst;
    final isIntraState = customer?.gstin.startsWith(company.stateCode) ?? true;
    final halfGst = order.gstTotal / 2;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeader(company, order, fontBold),
              pw.SizedBox(height: 8),

              // Divider
              pw.Container(height: 1.5, color: PdfColors.grey800),
              pw.SizedBox(height: 8),

              // Customer & Invoice Details
              _buildBillingInfo(company, order, customer, fontBold),
              pw.SizedBox(height: 12),

              // Items Table
              _buildItemsTable(order, isGst, fontBold),
              pw.SizedBox(height: 8),

              // Calculation & Summary Section
              _buildTotalsSection(order, company, isGst, isIntraState, halfGst, fontBold),
              pw.Spacer(),

              // Bank Details & Signatory Footer
              _buildFooter(company, fontBold),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(Company company, SalesOrder order, pw.Font fontBold) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                company.name,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF10231B),
                ),
              ),
              if (company.legal != null && company.legal!.isNotEmpty)
                pw.Text(
                  company.legal!,
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
              pw.SizedBox(height: 3),
              pw.Text(
                company.address,
                style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
              ),
              pw.SizedBox(height: 3),
              pw.Row(
                children: [
                  pw.Text('GSTIN: ', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                  pw.Text(company.gstin, style: const pw.TextStyle(fontSize: 8.5)),
                  pw.SizedBox(width: 12),
                  if (company.fssai != null) ...[
                    pw.Text('FSSAI: ', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                    pw.Text(company.fssai!, style: const pw.TextStyle(fontSize: 8.5)),
                  ],
                ],
              ),
              pw.Text(
                'Phone: ${company.phone} | Email: ${company.email}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
            ],
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey600, width: 1),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            color: PdfColor.fromInt(0xFFF8FAFC),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                order.isGst ? 'TAX INVOICE' : 'DELIVERY VOUCHER',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: order.isGst ? PdfColor.fromInt(0xFF163025) : PdfColor.fromInt(0xFFB88219),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text('Voucher No: ${order.voucherNo}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.Text('Date: ${AppFormatters.formatDate(order.date)}', style: const pw.TextStyle(fontSize: 8.5)),
              pw.Text('Time: ${order.time.isNotEmpty ? order.time : "12:00:00"}', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('Payment: ${order.payMode} (${order.payStatus})', style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildBillingInfo(
    Company company,
    SalesOrder order,
    Customer? customer,
    pw.Font fontBold,
  ) {
    final custName = customer?.name ?? order.customerName ?? 'Counter Cash Customer';
    final custAddress = customer?.address.isNotEmpty == true
        ? customer!.address
        : (order.address.isNotEmpty ? order.address : 'Dharmapuri, Tamil Nadu');
    final custGstin = customer?.gstin.isNotEmpty == true
        ? customer!.gstin
        : (order.gstin.isNotEmpty ? order.gstin : 'URP (Unregistered)');

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('BILLED TO (BUYER):', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                pw.SizedBox(height: 2),
                pw.Text(custName, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Text(custAddress, style: const pw.TextStyle(fontSize: 8.5)),
                pw.SizedBox(height: 2),
                pw.Row(
                  children: [
                    pw.Text('GSTIN: ', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                    pw.Text(custGstin, style: const pw.TextStyle(fontSize: 8.5)),
                    pw.SizedBox(width: 10),
                    if (customer?.phone.isNotEmpty == true) ...[
                      pw.Text('Phone: ', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                      pw.Text(customer!.phone, style: const pw.TextStyle(fontSize: 8.5)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          pw.Container(width: 0.5, height: 45, color: PdfColors.grey400, margin: const pw.EdgeInsets.symmetric(horizontal: 8)),
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('DISPATCH & TRANSPORT:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                pw.SizedBox(height: 2),
                pw.Text('Vehicle: ${order.dispatchDetails?.vehicleNumber ?? "-"}', style: const pw.TextStyle(fontSize: 8.5)),
                pw.Text('Driver: ${order.dispatchDetails?.driverName ?? "-"}', style: const pw.TextStyle(fontSize: 8.5)),
                pw.Text('Godown: ${order.godown}', style: const pw.TextStyle(fontSize: 8.5)),
                pw.Text('Billed By: ${order.userName.isNotEmpty ? order.userName : "Staff"}', style: const pw.TextStyle(fontSize: 8.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(SalesOrder order, bool isGst, pw.Font fontBold) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFF163025)),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      headers: [
        '#',
        'Product Description',
        'Unit',
        'Qty',
        'Rate (Rs.)',
        if (isGst) 'Taxable (Rs.)',
        if (isGst) 'GST %',
        if (isGst) 'GST Amt (Rs.)',
        'Total (Rs.)',
      ],
      data: List<List<String>>.generate(order.items.length, (index) {
        final item = order.items[index];
        return [
          '${index + 1}',
          item.productName,
          item.unit,
          '${item.qty.toStringAsFixed(item.qty.truncateToDouble() == item.qty ? 0 : 2)}',
          item.rate.toStringAsFixed(2),
          if (isGst) item.taxableAmount.toStringAsFixed(2),
          if (isGst) '${item.gstRate.toStringAsFixed(0)}%',
          if (isGst) item.gstAmount.toStringAsFixed(2),
          item.finalAmount.toStringAsFixed(2),
        ];
      }),
    );
  }

  static pw.Widget _buildTotalsSection(
    SalesOrder order,
    Company company,
    bool isGst,
    bool isIntraState,
    double halfGst,
    pw.Font fontBold,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 3,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('AMOUNT IN WORDS:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
              pw.Text(
                AppFormatters.numberToWordsINR(order.grandTotal),
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
              ),
              pw.SizedBox(height: 8),
              if (company.bank != null && company.bank!.name.isNotEmpty) ...[
                pw.Text('BANK DETAILS FOR REMITTANCE:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                pw.Text('Bank: ${company.bank!.name}', style: const pw.TextStyle(fontSize: 8)),
                pw.Text('A/C No: ${company.bank!.acc}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                pw.Text('IFSC: ${company.bank!.ifsc}', style: const pw.TextStyle(fontSize: 8)),
              ],
            ],
          ),
        ),
        pw.SizedBox(width: 16),
        pw.Expanded(
          flex: 2,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(
              children: [
                _buildTotalRow('Taxable Value:', 'Rs. ${order.subtotal.toStringAsFixed(2)}'),
                if (isGst) ...[
                  if (isIntraState) ...[
                    _buildTotalRow('CGST (2.5%):', 'Rs. ${halfGst.toStringAsFixed(2)}'),
                    _buildTotalRow('SGST (2.5%):', 'Rs. ${halfGst.toStringAsFixed(2)}'),
                  ] else ...[
                    _buildTotalRow('IGST (5%):', 'Rs. ${order.gstTotal.toStringAsFixed(2)}'),
                  ],
                ],
                if (order.roundOff != 0.0)
                  _buildTotalRow('Round Off:', 'Rs. ${order.roundOff.toStringAsFixed(2)}'),
                pw.Divider(color: PdfColors.grey400, thickness: 0.5),
                _buildTotalRow(
                  'Grand Total:',
                  'Rs. ${order.grandTotal.toStringAsFixed(2)}',
                  isBold: true,
                  fontSize: 10.5,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTotalRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 8.5,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(Company company, pw.Font fontBold) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Declaration:', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
              pw.Text(
                'We declare that this invoice shows the actual price of the goods described and that all particulars are true and correct. Goods once sold will not be taken back.',
                style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 40),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'For ${company.name}',
              style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 25),
            pw.Text('Authorized Signatory', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
          ],
        ),
      ],
    );
  }
}
