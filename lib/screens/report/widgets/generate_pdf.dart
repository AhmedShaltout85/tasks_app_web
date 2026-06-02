import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:tasks_app/models/daily_task_model.dart';

Future<void> generatePDF({
  required List<DailyTaskModel> filteredData,
  DateTime? startDate,
  DateTime? endDate,
  String? selectedAssignee,
  String? selectedApplication,
  String? selectedVisitPlace,
  String? selectedStatus,
  String? selectedIsRemote,
}) async {
  final pdf = pw.Document();

  // Load Arabic fonts - these support both Arabic and English characters
  final fontArabic = await PdfGoogleFonts.cairoRegular();
  final fontArabicBold = await PdfGoogleFonts.cairoBold();

  final double headerFontSize = 7;
  final double contentFontSize = 5;
  final double cellPadding = 3;

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
                'تقرير الأنشطة اليومية',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  font: fontArabicBold,
                ),
              ),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Directionality(
            textDirection: pw.TextDirection.ltr,
            child: pw.Text(
              'Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey700,
                font: fontArabic,
              ),
            ),
          ),
          pw.SizedBox(height: 10),
          if (startDate != null || endDate != null)
            pw.Directionality(
              textDirection: pw.TextDirection.ltr,
              child: pw.Text(
                'Date Range: ${startDate != null ? DateFormat('yyyy-MM-dd').format(startDate) : 'N/A'} to ${endDate != null ? DateFormat('yyyy-MM-dd').format(endDate) : 'N/A'}',
                style: pw.TextStyle(fontSize: headerFontSize, font: fontArabic),
              ),
            ),
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text(
              'الادارة - : أدارة البرامج وصيانتها',
              style: pw.TextStyle(fontSize: headerFontSize, font: fontArabic),
            ),
          ),
          if (selectedAssignee != null && selectedAssignee != 'All')
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Text(
                'المسند إليه - : $selectedAssignee',
                style: pw.TextStyle(fontSize: headerFontSize, font: fontArabic),
              ),
            ),
          if (selectedApplication != null && selectedApplication != 'All')
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Text(
                'اسم التطبيق : $selectedApplication',
                style: pw.TextStyle(fontSize: headerFontSize, font: fontArabic),
              ),
            ),
          if (selectedVisitPlace != null && selectedVisitPlace != 'All')
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Text(
                'مكان الزيارة : $selectedVisitPlace',
                style: pw.TextStyle(fontSize: headerFontSize, font: fontArabic),
              ),
            ),
          if (selectedStatus != null && selectedStatus != 'All')
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Text(
                'الحالة : $selectedStatus',
                style: pw.TextStyle(fontSize: headerFontSize, font: fontArabic),
              ),
            ),
          if (selectedIsRemote != null && selectedIsRemote != 'All')
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Text(
                'نوع العمل : $selectedIsRemote',
                style: pw.TextStyle(fontSize: headerFontSize, font: fontArabic),
              ),
            ),
          pw.SizedBox(height: 20),
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                  children: [
                    headerCellBilingual(
                      'التاريخ',
                      cellPadding,
                      headerTextStyle,
                    ),
                    headerCellBilingual(
                      'اسم المهمة',
                      cellPadding,
                      headerTextStyle,
                    ),
                    headerCellBilingual(
                      'اسم التطبيق',
                      cellPadding,
                      headerTextStyle,
                    ),
                    headerCellBilingual(
                      'مخصصة لـ',
                      cellPadding,
                      headerTextStyle,
                    ),
                    headerCellBilingual(
                      'مخصصة من',
                      cellPadding,
                      headerTextStyle,
                    ),
                    headerCellBilingual(
                      'مكان الزيارة',
                      cellPadding,
                      headerTextStyle,
                    ),
                    headerCellBilingual(
                      'الحالة',
                      cellPadding,
                      headerTextStyle,
                    ),
                    headerCellBilingual(
                      'الأولوية',
                      cellPadding,
                      headerTextStyle,
                    ),
                    headerCellBilingual(
                      'نوع العمل',
                      cellPadding,
                      headerTextStyle,
                    ),
                    headerCellBilingual(
                      'الموظفين المتعاونين',
                      cellPadding,
                      headerTextStyle,
                    ),
                    headerCellBilingual(
                      'تاريخ الاستحقاق',
                      cellPadding,
                      headerTextStyle,
                    ),
                  ],
                ),
                ...filteredData.map((task) {
                  String date = DateFormat('yyyy-MM-dd').format(task.createdAt);
                  String statusArabic =
                      task.taskStatus ? 'قيد الانتظار' : 'مكتمل';
                  String statusEnglish =
                      task.taskStatus ? 'Pending' : 'Completed';
                  String status = '$statusArabic\n$statusEnglish';

                  return pw.TableRow(
                    children: [
                      contentCellBilingual(cellPadding, date, contentTextStyle),
                      contentCellBilingual(
                        cellPadding,
                        task.taskTitle,
                        contentTextStyle,
                      ),
                      contentCellBilingual(
                        cellPadding,
                        task.appName,
                        contentTextStyle,
                      ),
                      contentCellBilingual(
                        cellPadding,
                        task.assignedTo,
                        contentTextStyle,
                      ),
                      contentCellBilingual(
                        cellPadding,
                        task.assignedBy,
                        contentTextStyle,
                      ),
                      contentCellBilingual(
                        cellPadding,
                        task.visitPlace,
                        contentTextStyle,
                      ),
                      contentCellBilingual(
                        cellPadding,
                        status,
                        contentTextStyle,
                      ),
                      contentCellBilingual(
                        cellPadding,
                        task.taskPriority,
                        contentTextStyle,
                      ),
                      contentCellBilingual(
                        cellPadding,
                        (task.isRemote ?? false) ? 'عن بعد' : 'موقع',
                        contentTextStyle,
                      ),
                      contentCellBilingual(
                        cellPadding,
                        task.coOperator
                            .toString()
                            .replaceAll('[', '')
                            .replaceAll(']', '')
                            .trim(),
                        contentTextStyle,
                      ),
                      contentCellBilingual(
                        cellPadding,
                        DateFormat(
                          'yyyy-MM-dd',
                        ).format(task.expectedCompletionDate),
                        contentTextStyle,
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text(
              'إجمالي السجلات - Total Records: ${filteredData.length}',
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

// Helper function to detect if text contains Arabic characters
bool _containsArabic(String text) {
  final arabicRegex = RegExp(r'[\u0600-\u06FF]');
  return arabicRegex.hasMatch(text);
}

pw.Padding contentCellBilingual(
  double cellPadding,
  String label,
  pw.TextStyle contentTextStyle,
) {
  // Determine text direction based on content
  bool hasArabic = _containsArabic(label);

  return pw.Padding(
    padding: pw.EdgeInsets.all(cellPadding),
    child: pw.Directionality(
      textDirection: hasArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      child: pw.Text(
        label,
        style: contentTextStyle,
        textAlign: hasArabic ? pw.TextAlign.right : pw.TextAlign.left,
      ),
    ),
  );
}

pw.Padding headerCellBilingual(
  String label,
  double cellPadding,
  pw.TextStyle headerTextStyle,
) {
  return pw.Padding(
    padding: pw.EdgeInsets.all(cellPadding),
    child: pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Text(
        label,
        style: headerTextStyle,
        textAlign: pw.TextAlign.center,
      ),
    ),
  );
}
