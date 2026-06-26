import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EventsPage extends StatefulWidget {
  final Function(int)? onOpenEvent;

  const EventsPage({super.key, this.onOpenEvent});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final api = ApiService();
  bool loading = true;
  List<dynamic> events = [];

  @override
  void initState() {
    super.initState();
    loadEvents();
  }

  Future<void> loadEvents() async {
    setState(() => loading = true);

    try {
      events = await api.getEvents();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> createEventDialog() async {
    final titleController = TextEditingController();
    final venueController = TextEditingController();
    final dateController = TextEditingController();
    final startController = TextEditingController();
    final endController = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create Event'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Event Title'),
              ),
              TextField(
                controller: venueController,
                decoration: const InputDecoration(labelText: 'Venue'),
              ),
              TextField(
                controller: dateController,
                decoration: const InputDecoration(labelText: 'Date YYYY-MM-DD'),
              ),
              TextField(
                controller: startController,
                decoration: const InputDecoration(
                  labelText: 'Start Time HH:MM',
                ),
              ),
              TextField(
                controller: endController,
                decoration: const InputDecoration(labelText: 'End Time HH:MM'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await api.createEvent({
                'title': titleController.text.trim(),
                'venue': venueController.text.trim(),
                'event_date': dateController.text.trim(),
                'start_time': startController.text.trim(),
                'end_time': endController.text.trim(),
              });

              if (!mounted) return;
              Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (created == true) {
      await loadEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          IconButton(onPressed: createEventDialog, icon: const Icon(Icons.add)),
          IconButton(onPressed: loadEvents, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : events.isEmpty
          ? const Center(child: Text('No events yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: events.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final event = events[index];

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(18),
                    title: Text(
                      event['title'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      '${event['venue'] ?? '-'}\n'
                      '${event['event_date'] ?? '-'} • ${event['start_time'] ?? '-'} - ${event['end_time'] ?? '-'}',
                    ),
                    isThreeLine: true,
                    trailing: ElevatedButton(
                      onPressed: () {
                        widget.onOpenEvent?.call(event['id']);
                      },
                      child: const Text('Open'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
