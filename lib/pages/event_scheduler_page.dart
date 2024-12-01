import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../providers/event_notifier.dart';
import '../services/ai_service_manager.dart';
import 'sector_page.dart';
import '../widgets/contextual_ai_interface.dart';

class EventSchedulerPage extends ConsumerStatefulWidget {
  const EventSchedulerPage({super.key});

  @override
  ConsumerState<EventSchedulerPage> createState() => _EventSchedulerPageState();
}

class _EventSchedulerPageState extends ConsumerState<EventSchedulerPage> {
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  DateTime _focusedDay = DateTime.now();
  bool _showAIInterface = false;

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

  void _onAICommandProcessed(Map<String, dynamic> response) {
    switch (response['action']) {
      case 'create_event':
        final data = response['data'];
        final startDate = DateTime.parse(data['startDate']);
        final endDate = DateTime.parse(data['endDate']);

        ref.read(eventProvider.notifier).initEvent(
          'ai-event-${const Uuid().v4()}',
          startDate,
          endDate,
        );

        // Ajouter les secteurs si présents
        if (data.containsKey('sectors')) {
          for (final sectorData in data['sectors']) {
            ref.read(eventProvider.notifier).addSector(sectorData['name']);

            final updatedEvent = ref.read(eventProvider);
            if (updatedEvent == null) continue;

            final sector = updatedEvent.sectors.lastWhere(
                  (s) => s.name == sectorData['name'],
            );

            // Ajouter les positions
            for (final positionData in sectorData['positions']) {
              ref.read(eventProvider.notifier).addPosition(
                sector.id,
                positionData['name'],
              );

              final currentEvent = ref.read(eventProvider);
              if (currentEvent == null) continue;

              final currentSector = currentEvent.sectors.firstWhere((s) => s.id == sector.id);
              final position = currentSector.positions.lastWhere(
                    (p) => p.name == positionData['name'],
              );

              // Ajouter les shifts
              for (final shift in positionData['shifts']) {
                final startTime = TimeOfDay.fromDateTime(
                    DateFormat('HH:mm').parse(shift['startTime'])
                );
                final endTime = TimeOfDay.fromDateTime(
                    DateFormat('HH:mm').parse(shift['endTime'])
                );

                ref.read(eventProvider.notifier).addShift(
                  sector.id,
                  position.id,
                  shift['label'],
                  DateTime(
                    startDate.year,
                    startDate.month,
                    startDate.day,
                    startTime.hour,
                    startTime.minute,
                  ),
                  DateTime(
                    startDate.year,
                    startDate.month,
                    startDate.day,
                    endTime.hour,
                    endTime.minute,
                  ),
                );
              }
            }
          }
        }

        setState(() {
          _rangeStart = startDate;
          _rangeEnd = endDate;
          _focusedDay = startDate;
          _showAIInterface = false;
        });

        break;

      case 'update_event_dates':
        final data = response['data'];
        final startDate = DateTime.parse(data['startDate']);
        final endDate = DateTime.parse(data['endDate']);

        setState(() {
          _rangeStart = startDate;
          _rangeEnd = endDate;
          _focusedDay = startDate;
          _showAIInterface = false;
        });

        ref.read(eventProvider.notifier).updateEventDates(startDate, endDate);
        break;
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
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: () {
              setState(() => _showAIInterface = !_showAIInterface);
            },
          ),
          if (_rangeStart != null && _rangeEnd != null)
            IconButton(
              onPressed: _saveSelectedRange,
              icon: const Icon(Icons.save),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (_showAIInterface)
              ContextualAIInterface(
                aiContext: AIContext.eventCreation,
                contextData: event != null ? {
                  'startDate': event.startDate.toIso8601String(),
                  'endDate': event.endDate.toIso8601String(),
                } : null,
                onCommandProcessed: _onAICommandProcessed,
                hintText: event == null
                    ? 'Décrivez votre événement...'
                    : 'Modifiez les dates de l\'événement...',
                testCommand: "Crée un événement du 25 au 26 Janvier 2025 avec un secteur bar qui contient un poste de barman avec des shifts de matin de 9h à 17h et de soir de 17h à 23h",
              ),
            if (event == null)
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        ref.read(eventProvider.notifier).initEvent(
                          'test-event',
                          DateTime.now(),
                          DateTime.now().add(const Duration(days: 7)),
                        );
                      },
                      child: const Text('Initialiser un événement'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(eventProvider.notifier).loadSeedData();
                      },
                      child: const Text('Charger données de test'),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  // Afficher les informations de l'événement actuel
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Column(
                      children: [
                        Text(
                          'Événement actuel',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Du: ${event.startDate.toString().split(' ')[0]}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Au: ${event.endDate.toString().split(' ')[0]}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        if (event.sectors.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('${event.sectors.length} secteur(s)'),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SectorPage(),
                                ),
                              );
                            },
                            child: const Text('Gérer les secteurs'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Divider(),
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
                              'Nouvelle date de début: ${_rangeStart?.toString().split(' ')[0]}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          const SizedBox(height: 8),
                          if (_rangeEnd != null)
                            Text(
                              'Nouvelle date de fin: ${_rangeEnd?.toString().split(' ')[0]}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          const SizedBox(height: 16),
                          if (_rangeStart != null && _rangeEnd != null)
                            ElevatedButton(
                              onPressed: _saveSelectedRange,
                              child: const Text('Mettre à jour les dates'),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}