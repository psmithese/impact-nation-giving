import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../domain/models/receipt.dart';

class ReceiptService {
  static Future<Uint8List> generateReceiptPdf(Receipt receipt) async {
    final pdf = pw.Document();

    // Load the church logo from assets
    final logoBytes = await rootBundle.load('assets/images/ingc_logo.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    final currency = NumberFormat.currency(symbol: 'NGN ', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header: logo on left, VERIFIED badge on right
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Church logo + name stacked
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Image(logoImage, width: 56, height: 56),
                      pw.SizedBox(width: 10),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'IMPACT NATION GOSPEL CENTER',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900,
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'Contribution Receipt',
                            style: pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.green100,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      border: pw.Border.all(color: PdfColors.green700),
                    ),
                    child: pw.Text(
                      'VERIFIED',
                      style: pw.TextStyle(
                        color: PdfColors.green700,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              pw.SizedBox(height: 40),
              
              // Receipt Number & Date
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Receipt No.', style: const pw.TextStyle(color: PdfColors.grey600)),
                      pw.Text(receipt.id, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Date', style: const pw.TextStyle(color: PdfColors.grey600)),
                      pw.Text(dateFormat.format(receipt.verifiedAt), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              
              pw.Divider(height: 40, thickness: 1, color: PdfColors.grey300),
              
              // Details
              pw.Text('Received From', style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 12)),
              pw.SizedBox(height: 4),
              pw.Text(receipt.memberName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              
              pw.SizedBox(height: 24),
              
              pw.Text('For Campaign', style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 12)),
              pw.SizedBox(height: 4),
              pw.Text(receipt.campaignName, style: pw.TextStyle(fontSize: 16)),
              
              pw.SizedBox(height: 32),
              
              // Payment Table
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(8)),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Contribution Payment'),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                'Method: ${receipt.paymentMethod == 'BANK_TRANSFER' ? 'Bank Transfer' : 'Cash'}',
                                style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 10),
                              ),
                              if (receipt.transferReference != null)
                                pw.Text(
                                  'Ref: ${receipt.transferReference}',
                                  style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 10),
                                ),
                              if (receipt.receivedBy != null)
                                pw.Text(
                                  'Cash Given To: ${receipt.receivedBy}',
                                  style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 10),
                                ),
                            ],
                          ),
                          pw.Text(
                            currency.format(receipt.amount),
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              pw.Spacer(),
              
              // Footer
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Thank you for your generous contribution!',
                  style: pw.TextStyle(
                    color: PdfColors.blue900,
                    fontWeight: pw.FontWeight.bold,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'This is a system generated receipt and does not require a physical signature.',
                  style: const pw.TextStyle(
                    color: PdfColors.grey500,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
