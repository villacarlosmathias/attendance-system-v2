import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/api_service.dart';

class EventDetailsPage extends StatefulWidget {
  final int eventId;

  const EventDetailsPage({super.key, required this.eventId});

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  final api = ApiService();

  bool loading = true;
  Map<String, dynamic>? event;
  List<dynamic> attendees = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void didUpdateWidget(covariant EventDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventId != widget.eventId) {
      loadData();
    }
  }

  Future<void> loadData() async {
    setState(() => loading = true);

    try {
      final eventData = await api.getEvent(widget.eventId);
      final attendeeData = await api.getAttendees(widget.eventId);

      if (!mounted) return;

      setState(() {
        event = eventData;
        attendees = attendeeData;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  String excelCell(List<dynamic> row, int index) {
    if (index >= row.length) return '';

    final cell = row[index];
    if (cell == null) return '';

    final value = cell.value;
    if (value == null) return '';

    final raw = value.toString();

    final match = RegExp(r'value:\s*([^,)]+)').firstMatch(raw);
    if (match != null) {
      return match.group(1)!.trim();
    }

    return raw
        .replaceAll('IntCellValue(', '')
        .replaceAll('DoubleCellValue(', '')
        .replaceAll('TextCellValue(', '')
        .replaceAll(')', '')
        .trim();
  }

  int? parseSeatNo(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned);
  }

  Future<void> importExcel() async {
    final input = html.FileUploadInputElement()..accept = '.xlsx';
    input.click();

    await input.onChange.first;

    final file = input.files?.first;
    if (file == null) return;

    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);

    await reader.onLoadEnd.first;

    final result = reader.result;
    if (result == null) return;

    final bytes = result is ByteBuffer
        ? Uint8List.view(result)
        : Uint8List.fromList(result as List<int>);

    final excel = xls.Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first];

    if (sheet == null) return;

    final imported = <Map<String, dynamic>>[];

    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];

      final seatNo = excelCell(row, 0);
      final studentNo = excelCell(row, 1);
      final fullName = excelCell(row, 2);
      final college = excelCell(row, 3);
      final program = excelCell(row, 4);
      final sport = excelCell(row, 5);

      if (studentNo.isEmpty || fullName.isEmpty) continue;

      imported.add({
        'seat_no': parseSeatNo(seatNo),
        'student_no': studentNo,
        'full_name': fullName,
        'college_school': college,
        'program': program,
        'college': college,
        'sport': sport,
      });
    }

    if (imported.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid students found in Excel file.')),
      );
      return;
    }

    final response = await api.importAttendees(widget.eventId, imported);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Imported ${response['imported']} students.')),
    );

    await loadData();
  }

  Future<void> addStudentDialog() async {
    final seatController = TextEditingController();
    final studentNoController = TextEditingController();
    final nameController = TextEditingController();
    final collegeController = TextEditingController();
    final programController = TextEditingController();
    final sportController = TextEditingController();

    final added = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Student'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: seatController,
                    decoration: const InputDecoration(labelText: 'Seat No.'),
                  ),
                  TextField(
                    controller: studentNoController,
                    decoration: const InputDecoration(labelText: 'Student No.'),
                  ),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                  ),
                  TextField(
                    controller: collegeController,
                    decoration: const InputDecoration(labelText: 'College'),
                  ),
                  TextField(
                    controller: programController,
                    decoration: const InputDecoration(labelText: 'Program'),
                  ),
                  TextField(
                    controller: sportController,
                    decoration: const InputDecoration(labelText: 'Sport'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await api.addAttendee(widget.eventId, {
                  'seat_no': parseSeatNo(seatController.text.trim()),
                  'student_no': studentNoController.text.trim(),
                  'full_name': nameController.text.trim(),
                  'college_school': collegeController.text.trim(),
                  'program': programController.text.trim(),
                  'college': collegeController.text.trim(),
                  'sport': sportController.text.trim(),
                });

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (added == true) {
      await loadData();
    }
  }

  String makeCsv(List<List<dynamic>> rows) {
    return rows
        .map((row) {
          return row
              .map((cell) {
                final value = cell.toString().replaceAll('"', '""');
                return '"$value"';
              })
              .join(',');
        })
        .join('\n');
  }

  Future<void> downloadReport() async {
    final rows = await api.getReport(widget.eventId);

    final csvRows = <List<dynamic>>[
      [
        'Seat No.',
        'Student No.',
        'Full Name',
        'College',
        'Program',
        'Sport',
        'Status',
        'Checked In At',
      ],
    ];

    for (final item in rows) {
      csvRows.add([
        item['seat_no'] ?? '',
        item['student_no'] ?? '',
        item['full_name'] ?? '',
        item['college'] ?? item['college_school'] ?? '',
        item['program'] ?? '',
        item['sport'] ?? '',
        item['status'] ?? '',
        item['checked_in_at'] ?? '',
      ]);
    }

    final csv = makeCsv(csvRows);
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute(
        'download',
        'attendance_report_event_${widget.eventId}.csv',
      )
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final checkedIn = attendees
        .where((a) => a['status'] == 'Checked In')
        .length;
    final pending = attendees.length - checkedIn;
    final registrationLink = '${Uri.base.origin}/?eventId=${widget.eventId}';

    return Scaffold(
      appBar: AppBar(
        title: Text(event?['title'] ?? 'Event Details'),
        actions: [
          IconButton(onPressed: loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      _statCard('Participants', attendees.length.toString()),
                      const SizedBox(width: 12),
                      _statCard('Checked In', checkedIn.toString()),
                      const SizedBox(width: 12),
                      _statCard('Pending', pending.toString()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: addStudentDialog,
                        icon: const Icon(Icons.person_add),
                        label: const Text('Add Student'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: importExcel,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Import Excel'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: downloadReport,
                        icon: const Icon(Icons.download),
                        label: const Text('Download Report'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            'Attendance QR Code',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          QrImageView(
                            data: registrationLink,
                            size: 220,
                            backgroundColor: Colors.white,
                          ),
                          const SizedBox(height: 12),
                          SelectableText(
                            registrationLink,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: attendees.isEmpty
                        ? const Center(child: Text('No students yet.'))
                        : ListView.separated(
                            itemCount: attendees.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final a = attendees[index];

                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Text('${a['seat_no'] ?? index + 1}'),
                                  ),
                                  title: Text(a['full_name'] ?? ''),
                                  subtitle: Text(
                                    '${a['student_no'] ?? '-'} • ${a['program'] ?? '-'} • ${a['sport'] ?? '-'}',
                                  ),
                                  trailing: Text(
                                    a['status'] ?? 'Pending',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: a['status'] == 'Checked In'
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _statCard(String title, String value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(title),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
