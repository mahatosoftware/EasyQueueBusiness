import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/constants/app_constants.dart';

class PosterPdfService {
  /// Generates printable PDF document bytes for a business queue poster
  static Future<Uint8List> generatePosterPdfBytes({
    required String businessName,
    required String branchName,
    required String queueTitle,
    required String checkInUrl,
    String? category,
    String? subCategory,
  }) async {
    final pdf = pw.Document(
      title: 'Queue Poster - $businessName',
      author: 'EasyQueue Business',
    );

    final orgCat = OrganizationCategoryManager.findCategory(category);
    final String label;
    if (subCategory != null && subCategory.trim().isNotEmpty) {
      label = '${orgCat.name} • ${subCategory.trim()}'.toUpperCase();
    } else if (category != null && category.trim().isNotEmpty) {
      label = orgCat.name.toUpperCase();
    } else {
      label = 'OFFICIAL QUEUE';
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(20),
                border: pw.Border.all(color: PdfColors.grey300, width: 2),
              ),
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Category / Type pill
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      borderRadius: pw.BorderRadius.circular(12),
                    ),
                    child: pw.Text(
                      label,
                      style: pw.TextStyle(
                        color: PdfColors.blue900,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 16),

                  // Business Name Prominently Featured
                  pw.Text(
                    businessName,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 26,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey900,
                    ),
                  ),
                  pw.SizedBox(height: 6),

                  // Branch & Queue Subtitle
                  pw.Text(
                    '$branchName | $queueTitle',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue700,
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  // Callout Banner
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(20),
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Text(
                      'SCAN TO JOIN QUEUE',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 18),

                  // QR Code
                  pw.Container(
                    padding: const pw.EdgeInsets.all(14),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(16),
                      border: pw.Border.all(color: PdfColors.grey400, width: 2),
                    ),
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: checkInUrl,
                      width: 200,
                      height: 200,
                      drawText: false,
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  // Instructions
                  pw.Text(
                    'Scan with EasyQueue App or Phone Camera',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey900,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Take a digital token and track live wait time on your smartphone without standing in line.',
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 24),
                  pw.Divider(color: PdfColors.grey300, thickness: 1),
                  pw.SizedBox(height: 12),

                  // Footer
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        'Powered by EasyQueue',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey800,
                        ),
                      ),
                      pw.Text(
                        ' - Real-Time Queue Management',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    checkInUrl,
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Exports the poster PDF to device file system / share sheet
  static Future<void> exportPdf({
    required String businessName,
    required String branchName,
    required String queueTitle,
    required String checkInUrl,
    String? category,
    String? subCategory,
  }) async {
    final bytes = await generatePosterPdfBytes(
      businessName: businessName,
      branchName: branchName,
      queueTitle: queueTitle,
      checkInUrl: checkInUrl,
      category: category,
      subCategory: subCategory,
    );

    final cleanName = businessName.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'EasyQueue_Poster_$cleanName.pdf',
    );
  }

  /// Opens the native Print preview sheet to print or save as PDF
  static Future<void> printPoster({
    required String businessName,
    required String branchName,
    required String queueTitle,
    required String checkInUrl,
    String? category,
    String? subCategory,
  }) async {
    final cleanName = businessName.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    await Printing.layoutPdf(
      name: 'EasyQueue_Poster_$cleanName',
      onLayout: (format) async => generatePosterPdfBytes(
        businessName: businessName,
        branchName: branchName,
        queueTitle: queueTitle,
        checkInUrl: checkInUrl,
        category: category,
        subCategory: subCategory,
      ),
    );
  }
}
