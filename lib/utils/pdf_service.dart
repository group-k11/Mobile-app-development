import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Service to handle PDF invoice generation and preview/sharing.
class PdfService {
  /// Generates a simple PDF document for the current cart items.
  static Future<pw.Document> generatePdfBill(List<Map<String, dynamic>> cartItems, double totalAmount) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text("ShelfSense Invoice",
                      style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 10),
                pw.Text("Date: ${now.day}/${now.month}/${now.year}  Time: ${now.hour}:${now.minute}"),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text("Product", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text("Qty", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text("Price", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text("Total", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    ...cartItems.map((item) {
                      final qty = item['quantity'] ?? 1;
                      final price = (item['price'] as double?) ?? 0;
                      return pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item['name'] ?? 'Unknown')),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("x$qty")),
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(5), child: pw.Text("₹${price.toStringAsFixed(2)}")),
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text("₹${(price * qty).toStringAsFixed(2)}")),
                        ],
                      );
                    }),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Total Amount:", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Text("₹${totalAmount.toStringAsFixed(2)}",
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
                  ],
                ),
                pw.SizedBox(height: 40),
                pw.Center(
                  child: pw.Text("Thank you for shopping at ShelfSense!",
                      style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }

  /// Opens the PDF preview / print / share dialog.
  static Future<void> previewOrSharePdf(pw.Document pdf) async {
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
