import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/position.dart';
import '../providers/event_notifier.dart';
import '../models/shift.dart';

// Si vous utilisez d'autres modèles, ajoutez leurs imports ici
import '../models/event.dart';
import '../models/sector.dart';

class DateSelector extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final VoidCallback onToggle;

  const DateSelector({
    required this.date,
    required this.isSelected,
    required this.onToggle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected 
            ? Theme.of(context).primaryColor 
            : Theme.of(context).disabledColor.withOpacity(0.2),
        ),
        child: Center(
          child: Text(
            '${date.day}/${date.month}',
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class ShiftManagementPage extends ConsumerStatefulWidget {
  final String sectorId;
  final Position position;

  const ShiftManagementPage({
    required this.sectorId,
    required this.position,
    super.key,
  });

  @override
  ConsumerState<ShiftManagementPage> createState() => _ShiftManagementPageState();
}

class _ShiftManagementPageState extends ConsumerState<ShiftManagementPage> {
  final _labelController = TextEditingController();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  Set<DateTime> _excludedDates = {};

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  List<DateTime> _getEventDates() {
    final event = ref.read(eventProvider);
    if (event == null) return [];

    final dates = <DateTime>[];
    var currentDate = DateTime(
      event.startDate.year,
      event.startDate.month,
      event.startDate.day,
    );
    final endDate = DateTime(
      event.endDate.year,
      event.endDate.month,
      event.endDate.day,
    );

    while (!currentDate.isAfter(endDate)) {
      dates.add(currentDate);
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return dates;
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _toggleDate(DateTime date) {
    setState(() {
      if (_excludedDates.contains(date)) {
        _excludedDates.remove(date);
      } else {
        _excludedDates.add(date);
      }
    });
  }

  void _addShift() {
    final eventDates = _getEventDates();
    if (eventDates.isEmpty) return;

    if (_labelController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un label pour le shift')),
      );
      return;
    }

    final referenceDate = eventDates.firstWhere(
      (date) => !_excludedDates.contains(date),
      orElse: () => eventDates.first,
    );

    final startDateTime = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    final endDateTime = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('L\'heure de fin doit être après l\'heure de début'),
        ),
      );
      return;
    }

    ref.read(eventProvider.notifier).addShift(
          widget.sectorId,
          widget.position.id,
          _labelController.text,
          startDateTime,
          endDateTime,
          _excludedDates,
        );

    setState(() {
      _labelController.clear();
      _excludedDates = {};
    });
  }

  String _formatIncludedDates(List<DateTime> allDates, Set<DateTime> excludedDates) {
    final includedDates = allDates.where((date) => !excludedDates.contains(date)).toList();
    return includedDates.map((date) => '${date.day}/${date.month}').join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final event = ref.watch(eventProvider);
    if (event == null) return const SizedBox.shrink();

    final currentSector = event.sectors.firstWhere(
      (s) => s.id == widget.sectorId,
    );
    final currentPosition = currentSector.positions.firstWhere(
      (p) => p.id == widget.position.id,
    );

    final eventDates = _getEventDates();

    return Scaffold(
      appBar: AppBar(
        title: Text('Shifts - ${currentPosition.name}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Label du shift',
                border: OutlineInputBorder(),
                hintText: 'Ex: Matin, Après-midi, Soirée...',
              ),
            ),
          ),
          Container(
            height: 80,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: eventDates.map((date) {
                  return DateSelector(
                    date: date,
                    isSelected: !_excludedDates.contains(date),
                    onToggle: () => _toggleDate(date),
                  );
                }).toList(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ListTile(
                  title: Text('Heure de début: ${_startTime.format(context)}'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () => _selectTime(context, true),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: Text('Heure de fin: ${_endTime.format(context)}'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () => _selectTime(context, false),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _addShift,
                  child: const Text('Ajouter un shift'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: currentPosition.shifts.length,
              itemBuilder: (context, index) {
                final shift = currentPosition.shifts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: ListTile(
                    title: Row(
                      children: [
                        Text(shift.label),
                        const SizedBox(width: 8),
                        Text(
                          '${TimeOfDay.fromDateTime(shift.startTime).format(context)} - '
                          '${TimeOfDay.fromDateTime(shift.endTime).format(context)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    subtitle: Text(
                      'Dates : ${_formatIncludedDates(eventDates, shift.excludedDates)}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        ref.read(eventProvider.notifier).removeShift(
                              widget.sectorId,
                              widget.position.id,
                              shift.id,
                            );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}