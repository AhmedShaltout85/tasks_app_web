import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:tasks_app/models/preventive_maintenance_model.dart';

Future<void> generatePreventiveMaintenancePDF({
  required List<PreventiveMaintenanceModel> filteredData,
  String? selectedUsername,
  String? selectedAppName,
  String? selectedPlaceName,
  bool? selectedIsRemote,
  DateTime? startDate,
  DateTime? endDate,
}) async {
  final pdf = pw.Document();

  final fontArabic = await PdfGoogleFonts.cairoRegular();
  final fontArabicBold = await PdfGoogleFonts.cairoBold();

  const double headerFontSize = 7;
  const double contentFontSize = 5;
  const double cellPadding = 3;

  pw.TextStyle headerTextStyle = pw.TextStyle(
    font: fontArabicBold,
    fontSize: headerFontSize,
  );

  pw.TextStyle contentTextStyle = pw.TextStyle(
    font: fontArabic,
    fontSize: contentFontSize,
  );

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      theme: pw.ThemeData.withFont(base: fontArabic, bold: fontArabicBold),
      build: (pw.Context context) {
        return [
          pw.Header(
            level: 0,
            child: pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Text(
                'تقرير الصيانة الوقائية - Preventive Maintenance Report',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  font: fontArabicBold,
                ),
              ),
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text(
              'تاريخ الطباعة: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
              style: pw.TextStyle(
                fontSize: 12,
                // fontWeight: pw.FontWeight.bold,
                font: fontArabicBold,
              ),
            ),
          ),
        
          pw.SizedBox(height: 10),
          if (selectedUsername != null && selectedUsername != 'الكل')
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Text(
                'المستخدم: $selectedUsername',
                style: pw.TextStyle(fontSize: headerFontSize, font: fontArabic),
              ),
            ),
          if (selectedAppName != null && selectedAppName != 'الكل')
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Text(
                'التطبيق: $selectedAppName',
                style: pw.TextStyle(fontSize: headerFontSize, font: fontArabic),
              ),
            ),
          if (selectedPlaceName != null && selectedPlaceName != 'الكل')
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Text(
                'المكان: $selectedPlaceName',
                style: pw.TextStyle(fontSize: headerFontSize, font: fontArabic),
              ),
            ),
          if (selectedIsRemote != null)
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Text(
                'النوع: ${selectedIsRemote == true ? 'عن بُعد' : 'موقع'}',
                style: pw.TextStyle(fontSize: headerFontSize, font: fontArabic),
              ),
            ),
          if (startDate != null || endDate != null)
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Text(
                'التاريخ: ${startDate != null ? DateFormat('yyyy-MM-dd').format(startDate) : 'البداية'} إلى ${endDate != null ? DateFormat('yyyy-MM-dd').format(endDate) : 'النهاية'}',
                style: pw.TextStyle(fontSize: headerFontSize, font: fontArabic),
              ),
            ),
          pw.SizedBox(height: 15),
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                  children: [
                    _headerCell(
                        'اسم التطبيق', cellPadding, headerTextStyle),
                    _headerCell(
                        'الإجراء', cellPadding, headerTextStyle),
                    _headerCell('المستخدم', cellPadding, headerTextStyle),
                    _headerCell('المكان', cellPadding, headerTextStyle),
                    _headerCell('المكان الفرعي', cellPadding,
                        headerTextStyle),
                    _headerCell('النوع', cellPadding, headerTextStyle),
                  ],
                ),
                ...filteredData.map((item) {
                  String type = item.isRemote == 'true'
                      ? 'عن بُعد'
                      : 'موقع';
                  return pw.TableRow(
                    children: [
                      _contentCell(cellPadding, item.appName, contentTextStyle),
                      _contentCell(cellPadding, item.action, contentTextStyle),
                      _contentCell(
                          cellPadding, item.username, contentTextStyle),
                      _contentCell(
                          cellPadding, item.placeName, contentTextStyle),
                      _contentCell(
                          cellPadding, item.subPlace ?? '-', contentTextStyle),
                      _contentCell(cellPadding, type, contentTextStyle),
                    ],
                  );
                }),
              ],
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text(
              'إجمالي السجلات: ${filteredData.length}',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                font: fontArabicBold,
              ),
            ),
          ),
        ];
      },
    ),
  );

  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
  );
}

pw.Padding _headerCell(String label, double cellPadding, pw.TextStyle style) {
  return pw.Padding(
    padding: pw.EdgeInsets.all(cellPadding),
    child: pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Text(
        label,
        style: style,
        textAlign: pw.TextAlign.center,
      ),
    ),
  );
}

pw.Padding _contentCell(double cellPadding, String label, pw.TextStyle style) {
  bool hasArabic = _containsArabic(label);
  return pw.Padding(
    padding: pw.EdgeInsets.all(cellPadding),
    child: pw.Directionality(
      textDirection: hasArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      child: pw.Text(
        label,
        style: style,
        textAlign: hasArabic ? pw.TextAlign.right : pw.TextAlign.left,
      ),
    ),
  );
}

bool _containsArabic(String text) {
  final arabicRegex = RegExp(r'[\u0600-\u06FF]');
  return arabicRegex.hasMatch(text);
}
