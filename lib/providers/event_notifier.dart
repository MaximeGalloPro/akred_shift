import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/event.dart';
import '../models/sector.dart';
import '../models/position.dart';
import '../models/shift.dart';
import '../utils/seed_generator.dart';


final eventProvider = StateNotifierProvider<EventNotifier, Event?>((ref) {
  return EventNotifier();
});

class EventNotifier extends StateNotifier<Event?> {
  EventNotifier() : super(null);

  final _uuid = const Uuid();

  void loadSeedData() {
    state = SeedGenerator.generateSeedEvent();
  }

  void initEvent(String uuid, DateTime startDate, DateTime endDate) {
    state = Event(
      uuid: uuid,
      startDate: startDate,
      endDate: endDate,
      sectors: [],
    );
  }

  void updateEventDates(DateTime startDate, DateTime endDate) {
    if (state == null) return;
    state = Event(
      uuid: state!.uuid,
      startDate: startDate,
      endDate: endDate,
      sectors: state!.sectors,
    );
  }

  void addSector(String name) {
    if (state == null) return;
    final newSector = Sector(
      id: _uuid.v4(),
      name: name,
      positions: [],
    );

    state = Event(
      uuid: state!.uuid,
      startDate: state!.startDate,
      endDate: state!.endDate,
      sectors: [...state!.sectors, newSector],
    );
  }

  void removeSector(String sectorId) {
    if (state == null) return;
    state = Event(
      uuid: state!.uuid,
      startDate: state!.startDate,
      endDate: state!.endDate,
      sectors: state!.sectors.where((s) => s.id != sectorId).toList(),
    );
  }

  void addPosition(String sectorId, String name) {
    if (state == null) return;

    final newPosition = Position(
      id: _uuid.v4(),
      name: name,
      shifts: [],
    );

    state = Event(
      uuid: state!.uuid,
      startDate: state!.startDate,
      endDate: state!.endDate,
      sectors: state!.sectors.map((sector) {
        if (sector.id == sectorId) {
          return Sector(
            id: sector.id,
            name: sector.name,
            positions: [...sector.positions, newPosition],
          );
        }
        return sector;
      }).toList(),
    );
  }

  void removePosition(String sectorId, String positionId) {
    if (state == null) return;

    state = Event(
      uuid: state!.uuid,
      startDate: state!.startDate,
      endDate: state!.endDate,
      sectors: state!.sectors.map((sector) {
        if (sector.id == sectorId) {
          return Sector(
            id: sector.id,
            name: sector.name,
            positions: sector.positions
                .where((p) => p.id != positionId)
                .toList(),
          );
        }
        return sector;
      }).toList(),
    );
  }

  void addShift(String sectorId,
      String positionId,
      String label,
      DateTime startTime,
      DateTime endTime,
      [Set<DateTime> excludedDates = const {}]) {
    if (state == null) return;

    final newShift = Shift(
      id: _uuid.v4(),
      label: label,
      startTime: startTime,
      endTime: endTime,
      excludedDates: excludedDates,
    );

    state = Event(
      uuid: state!.uuid,
      startDate: state!.startDate,
      endDate: state!.endDate,
      sectors: state!.sectors.map((sector) {
        if (sector.id == sectorId) {
          return Sector(
            id: sector.id,
            name: sector.name,
            positions: sector.positions.map((position) {
              if (position.id == positionId) {
                return Position(
                  id: position.id,
                  name: position.name,
                  shifts: [...position.shifts, newShift],
                );
              }
              return position;
            }).toList(),
          );
        }
        return sector;
      }).toList(),
    );
  }

  void removeShift(String sectorId, String positionId, String shiftId) {
    if (state == null) return;

    state = Event(
      uuid: state!.uuid,
      startDate: state!.startDate,
      endDate: state!.endDate,
      sectors: state!.sectors.map((sector) {
        if (sector.id == sectorId) {
          return Sector(
            id: sector.id,
            name: sector.name,
            positions: sector.positions.map((position) {
              if (position.id == positionId) {
                return Position(
                  id: position.id,
                  name: position.name,
                  shifts: position.shifts
                      .where((s) => s.id != shiftId)
                      .toList(),
                );
              }
              return position;
            }).toList(),
          );
        }
        return sector;
      }).toList(),
    );
  }
}