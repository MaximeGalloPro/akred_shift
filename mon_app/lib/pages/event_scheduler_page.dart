import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/event_notifier.dart';
import 'sector_page.dart';

class EventSchedulerPage extends ConsumerStatefulWidget {
  const EventSchedulerPage({super.key});

  @override
  ConsumerState<EventSchedulerPage> createState() => _EventSchedulerPageState();
}

class _EventSchedulerPageState extends ConsumerState<EventSchedulerPage> {
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  DateTime _focusedDay = DateTime.now();

  void _saveSelectedRange() {
    if (_rangeStart != null && _rangeEnd != null) {
      ref.read(eventProvider.notifier).updateEventDates(
        _rangeStart!,
        _rangeEnd!,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dates sauvegardées')),
      );
      
      // Naviguer vers la page des secteurs après la sauvegarde
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SectorPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = ref.watch(eventProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Scheduler'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_rangeStart != null && _rangeEnd != null)
            IconButton(
              onPressed: _saveSelectedRange,
              icon: const Icon(Icons.save),
            ),
        ],
      ),
      body: event == null
          ? Center(
              child: ElevatedButton(
                onPressed: () {
                  ref.read(eventProvider.notifier).initEvent(
                        'test-event',
                        DateTime.now(),
                        DateTime.now().add(const Duration(days: 7)),
                      );
                },
                child: const Text('Initialiser un événement'),
              ),
            )
          : Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.now().subtract(const Duration(days: 365)),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: _focusedDay,
                  rangeStartDay: _rangeStart,
                  rangeEndDay: _rangeEnd,
                  rangeSelectionMode: RangeSelectionMode.enforced,
                  onRangeSelected: (start, end, focusedDay) {
                    setState(() {
                      _rangeStart = start;
                      _rangeEnd = end;
                      _focusedDay = focusedDay;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                ),
                if (_rangeStart != null || _rangeEnd != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        if (_rangeStart != null)
                          Text(
                            'Date de début: ${_rangeStart?.toString().split(' ')[0]}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        const SizedBox(height: 8),
                        if (_rangeEnd != null)
                          Text(
                            'Date de fin: ${_rangeEnd?.toString().split(' ')[0]}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        const SizedBox(height: 16),
                        if (_rangeStart != null && _rangeEnd != null)
                          ElevatedButton(
                            onPressed: _saveSelectedRange,
                            child: const Text('Sauvegarder et continuer'),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}