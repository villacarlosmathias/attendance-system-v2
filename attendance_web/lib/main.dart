import 'package:flutter/material.dart';

import 'pages/dashboard_page.dart';
import 'pages/events_page.dart';
import 'pages/event_details_page.dart';
import 'pages/student_registration_page.dart';

void main() {
  runApp(const EventAttendanceApp());
}

class EventAttendanceApp extends StatelessWidget {
  const EventAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final hasEventId = Uri.base.queryParameters.containsKey('eventId');

    return MaterialApp(
      title: 'Event Smart Attendance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: hasEventId ? const StudentRegistrationPage() : const AdminShell(),
    );
  }
}

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int selectedIndex = 0;
  int selectedEventId = 1;

  void openEvent(int id) {
    setState(() {
      selectedEventId = id;
      selectedIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(onOpenEvent: openEvent),
      EventsPage(onOpenEvent: openEvent),
      EventDetailsPage(eventId: selectedEventId),
      const StudentRegistrationPage(),
    ];

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              setState(() => selectedIndex = index);
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text("Dashboard"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.event),
                label: Text("Events"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.qr_code),
                label: Text("Event Details"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text("Registration"),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: pages[selectedIndex]),
        ],
      ),
    );
  }
}
