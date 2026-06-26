import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  final Function(int)? onOpenEvent;

  const DashboardPage({super.key, this.onOpenEvent});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          children: [
            _card(
              icon: Icons.event,
              title: "Events",
              color: Colors.blue,
              onTap: () {
                onOpenEvent?.call(1);
              },
            ),
            _card(
              icon: Icons.people,
              title: "Participants",
              color: Colors.green,
            ),
            _card(
              icon: Icons.qr_code_scanner,
              title: "QR Attendance",
              color: Colors.orange,
            ),
            _card(
              icon: Icons.insert_chart,
              title: "Reports",
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required String title,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: color),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
