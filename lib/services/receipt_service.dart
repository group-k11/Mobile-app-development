import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/sale_model.dart';
import '../utils/helpers.dart';

/// Service for generating and sharing PDF receipts.
class ReceiptService {
  /// Generate a PDF receipt for a completed sale.
  static Future<Uint8List> generateReceipt({
    required SaleModel sale,
    String storeName = 'ShelfSense Store',
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, double.infinity,
            marginAll: 5 * PdfPageFormat.mm),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Store Header
              pw.Text(
                storeName,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Tax Invoice / Receipt',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 4),

              // Sale Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Receipt #', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(
                    sale.saleId.length > 8
                        ? sale.saleId.substring(0, 8).toUpperCase()
                        : sale.saleId.toUpperCase(),
                    style: pw.TextStyle(
                        fontSize: 9, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Date', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(formatDateTime(sale.timestamp),
                      style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Payment', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(sale.paymentMethod,
                      style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              if (sale.staffName.isNotEmpty)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Cashier', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text(sale.staffName,
                        style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5),

              // Column Headers
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 4,
                      child: pw.Text('Item',
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text('Qty',
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text('Price',
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.right),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text('Total',
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.right),
                    ),
                  ],
                ),
              ),
              pw.Divider(thickness: 0.5),

              // Items
              ...sale.items.map((item) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 4,
                          child: pw.Text(item.productName,
                              style: const pw.TextStyle(fontSize: 9),
                              maxLines: 2),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text('${item.quantity}',
                              style: const pw.TextStyle(fontSize: 9),
                              textAlign: pw.TextAlign.center),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                              formatCurrency(item.price),
                              style: const pw.TextStyle(fontSize: 9),
                              textAlign: pw.TextAlign.right),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                              formatCurrency(item.total),
                              style: const pw.TextStyle(fontSize: 9),
                              textAlign: pw.TextAlign.right),
                        ),
                      ],
                    ),
                  )),

              pw.SizedBox(height: 4),
              pw.Divider(thickness: 1),

              // Total
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL (${sale.totalItems} items)',
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      formatCurrency(sale.totalAmount),
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),

              pw.Divider(thickness: 1),
              pw.SizedBox(height: 8),

              // Footer
              pw.Text(
                'Thank you for your purchase!',
                style: pw.TextStyle(
                    fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Powered by ShelfSense',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Preview/print the receipt.
  static Future<void> printReceipt(Uint8List pdfBytes) async {
    await Printing.layoutPdf(onLayout: (_) => pdfBytes);
  }

  /// Share the receipt via WhatsApp, email, etc.
  static Future<void> shareReceipt(Uint8List pdfBytes,
      {String? saleId}) async {
    final dir = await getTemporaryDirectory();
    final fileName =
        'receipt_${saleId ?? DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'ShelfSense Receipt',
    );
  }

  /// Save receipt to device downloads.
  static Future<String> saveReceipt(Uint8List pdfBytes,
      {String? saleId}) async {
    final dir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory('${dir.path}/receipts');
    if (!await receiptsDir.exists()) {
      await receiptsDir.create(recursive: true);
    }

    final fileName =
        'receipt_${saleId ?? DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${receiptsDir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);

    return file.path;
  }
}
