import 'dart:io';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import '../models/trip.dart';
import '../services/database_service.dart';

class ExportService {
  static final ExportService instance = ExportService._init();
  ExportService._init();

  // 運行記録をPDFでエクスポート
  Future<String> exportTripToPdf(Trip trip) async {
    final pdf = pw.Document();
    
    // データベースから関連データを取得
    final fuelRecords = await DatabaseService.instance.getFuelRecordsByTrip(trip.id!);
    final breakRecords = await DatabaseService.instance.getBreakRecordsByTrip(trip.id!);
    final cargoRecords = await DatabaseService.instance.getCargoRecordsByTrip(trip.id!);
    final expenseRecords = await DatabaseService.instance.getExpenseRecordsByTrip(trip.id!);
    final summary = await DatabaseService.instance.getTripSummary(trip.id!);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // ヘッダー
            pw.Header(
              level: 0,
              child: pw.Text(
                '運行記録レポート',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),

            // 基本情報
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '基本情報',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text('目的地: ${trip.destination}'),
                  pw.Text('開始日時: ${DateFormat('yyyy/MM/dd HH:mm').format(trip.startTime)}'),
                  if (trip.endTime != null)
                    pw.Text('終了日時: ${DateFormat('yyyy/MM/dd HH:mm').format(trip.endTime!)}'),
                  pw.Text('運行時間: ${trip.formattedDuration}'),
                  if (trip.startLocation != null)
                    pw.Text('出発地: ${trip.startLocation}'),
                  if (trip.endLocation != null)
                    pw.Text('到着地: ${trip.endLocation}'),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // サマリー
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'サマリー',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text('給油回数: ${summary['fuel_count']}回'),
                  pw.Text('総給油量: ${(summary['total_liters'] as double).toStringAsFixed(1)}L'),
                  pw.Text('燃料費: ${NumberFormat('#,###').format(summary['total_fuel_cost'])}円'),
                  pw.Text('総経費: ${NumberFormat('#,###').format(summary['total_expense'])}円'),
                  pw.Text('休憩回数: ${summary['break_count']}回'),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // 給油記録
            if (fuelRecords.isNotEmpty) ...[
              pw.Text(
                '給油記録',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('日時', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('給油量(L)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('金額(円)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('場所', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...fuelRecords.map((record) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(DateFormat('MM/dd HH:mm').format(record.timestamp)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(record.liters.toStringAsFixed(1)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(NumberFormat('#,###').format(record.amount)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(record.location ?? ''),
                      ),
                    ],
                  )),
                ],
              ),
              pw.SizedBox(height: 20),
            ],

            // 休憩記録
            if (breakRecords.isNotEmpty) ...[
              pw.Text(
                '休憩記録',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('種類', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('開始時刻', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('終了時刻', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('時間', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...breakRecords.map((record) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(record.breakType.displayName),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(DateFormat('MM/dd HH:mm').format(record.startTime)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(record.endTime != null 
                            ? DateFormat('MM/dd HH:mm').format(record.endTime!) 
                            : '進行中'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(record.formattedDuration),
                      ),
                    ],
                  )),
                ],
              ),
              pw.SizedBox(height: 20),
            ],

            // 経費記録
            if (expenseRecords.isNotEmpty) ...[
              pw.Text(
                '経費記録',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('日時', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('カテゴリ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('金額(円)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('説明', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...expenseRecords.map((record) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(DateFormat('MM/dd HH:mm').format(record.timestamp)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(record.category.displayName),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(NumberFormat('#,###').format(record.amount)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(record.description ?? ''),
                      ),
                    ],
                  )),
                ],
              ),
            ],
          ];
        },
      ),
    );

    // ファイル保存
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'trip_report_${trip.id}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  // 運行記録をCSVでエクスポート
  Future<String> exportTripToCsv(Trip trip) async {
    final fuelRecords = await DatabaseService.instance.getFuelRecordsByTrip(trip.id!);
    final breakRecords = await DatabaseService.instance.getBreakRecordsByTrip(trip.id!);
    final expenseRecords = await DatabaseService.instance.getExpenseRecordsByTrip(trip.id!);

    List<List<dynamic>> csvData = [];

    // ヘッダー
    csvData.add([
      '種類',
      '日時',
      '詳細1',
      '詳細2',
      '詳細3',
      '場所',
      '備考'
    ]);

    // 基本情報
    csvData.add([
      '運行開始',
      DateFormat('yyyy/MM/dd HH:mm').format(trip.startTime),
      trip.destination,
      trip.startLocation ?? '',
      '',
      '',
      ''
    ]);

    if (trip.endTime != null) {
      csvData.add([
        '運行終了',
        DateFormat('yyyy/MM/dd HH:mm').format(trip.endTime!),
        trip.endLocation ?? '',
        trip.formattedDuration,
        '',
        '',
        ''
      ]);
    }

    // 給油記録
    for (final record in fuelRecords) {
      csvData.add([
        '給油',
        DateFormat('yyyy/MM/dd HH:mm').format(record.timestamp),
        '${record.liters.toStringAsFixed(1)}L',
        '${NumberFormat('#,###').format(record.amount)}円',
        '${record.pricePerLiter.toStringAsFixed(1)}円/L',
        record.location ?? '',
        ''
      ]);
    }

    // 休憩記録
    for (final record in breakRecords) {
      csvData.add([
        '休憩',
        DateFormat('yyyy/MM/dd HH:mm').format(record.startTime),
        record.breakType.displayName,
        record.endTime != null 
            ? DateFormat('yyyy/MM/dd HH:mm').format(record.endTime!)
            : '進行中',
        record.formattedDuration,
        record.location ?? '',
        ''
      ]);
    }

    // 経費記録
    for (final record in expenseRecords) {
      csvData.add([
        '経費',
        DateFormat('yyyy/MM/dd HH:mm').format(record.timestamp),
        record.category.displayName,
        '${NumberFormat('#,###').format(record.amount)}円',
        '',
        '',
        record.description ?? ''
      ]);
    }

    // CSV文字列に変換
    String csvString = const ListToCsvConverter().convert(csvData);

    // ファイル保存
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'trip_data_${trip.id}_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csvString, encoding: utf8);

    return file.path;
  }

  // ファイルを共有
  Future<void> shareFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await Share.shareXFiles([XFile(filePath)]);
    } else {
      throw Exception('ファイルが見つかりません: $filePath');
    }
  }

  // 月次レポートをPDFで生成
  Future<String> generateMonthlyReport(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);
    
    final trips = await DatabaseService.instance.getAllTrips();
    final monthlyTrips = trips.where((trip) => 
        trip.startTime.isAfter(startDate) && 
        trip.startTime.isBefore(endDate.add(const Duration(days: 1)))
    ).toList();

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '${year}年${month}月 運行レポート',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('運行回数: ${monthlyTrips.length}回'),
              pw.Text('期間: ${DateFormat('yyyy/MM/dd').format(startDate)} - ${DateFormat('yyyy/MM/dd').format(endDate)}'),
              pw.SizedBox(height: 20),
              
              // 運行一覧
              if (monthlyTrips.isNotEmpty) ...[
                pw.Text(
                  '運行一覧',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('日付', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('目的地', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('運行時間', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('状態', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    ...monthlyTrips.map((trip) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(DateFormat('MM/dd').format(trip.startTime)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(trip.destination),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(trip.formattedDuration),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(trip.isCompleted ? '完了' : '進行中'),
                        ),
                      ],
                    )),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );

    // ファイル保存
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'monthly_report_${year}_${month.toString().padLeft(2, '0')}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }
}

