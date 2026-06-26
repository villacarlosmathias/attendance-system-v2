import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StudentRegistrationPage extends StatefulWidget {
  const StudentRegistrationPage({super.key});

  @override
  State<StudentRegistrationPage> createState() =>
      _StudentRegistrationPageState();
}

class _StudentRegistrationPageState extends State<StudentRegistrationPage> {
  final api = ApiService();

  late final TextEditingController eventIdController;
  final studentNoController = TextEditingController();

  bool loading = false;
  String? errorMessage;
  Map<String, dynamic>? result;

  @override
  void initState() {
    super.initState();
    eventIdController = TextEditingController(
      text: Uri.base.queryParameters['eventId'] ?? '1',
    );
  }

  Future<void> register() async {
    final eventId = int.tryParse(eventIdController.text.trim());
    final studentNo = studentNoController.text.trim();

    if (eventId == null || studentNo.isEmpty) {
      setState(() => errorMessage = 'Please enter your student number.');
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
      result = null;
    });

    try {
      final data = await api.registerStudent(eventId, studentNo);
      setState(() => result = data);
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() => loading = false);
    }
  }

  void reset() {
    setState(() {
      studentNoController.clear();
      result = null;
      errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('Student Registration')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: result == null ? _formCard() : _successCard(),
          ),
        ),
      ),
    );
  }

  Widget _formCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_2, size: 64, color: Color(0xFF2563EB)),
            const SizedBox(height: 16),
            const Text(
              'Confirm Attendance',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your student number to register your attendance.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: eventIdController,
              decoration: const InputDecoration(
                labelText: 'Event ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: studentNoController,
              decoration: const InputDecoration(
                labelText: 'Student Number',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => register(),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 14),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: loading ? null : register,
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(loading ? 'Registering...' : 'Register'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _successCard() {
    final data = result!;
    final seatNo = data['seat_no'];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 42,
              backgroundColor: Color(0xFFDCFCE7),
              child: Icon(Icons.check, size: 54, color: Color(0xFF16A34A)),
            ),
            const SizedBox(height: 18),
            Text(
              data['message'] ?? 'Attendance confirmed.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF16A34A),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              data['full_name'] ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  const Text(
                    'YOUR SEAT NUMBER',
                    style: TextStyle(
                      color: Color(0xFF1D4ED8),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    seatNo == null ? 'No seat assigned' : seatNo.toString(),
                    style: const TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            OutlinedButton.icon(
              onPressed: reset,
              icon: const Icon(Icons.person_add),
              label: const Text('Register another'),
            ),
          ],
        ),
      ),
    );
  }
}
