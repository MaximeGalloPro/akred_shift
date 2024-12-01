import 'package:uuid/uuid.dart';
import '../models/event.dart';
import '../models/sector.dart';
import '../models/position.dart';
import '../models/shift.dart';
import '../models/employee.dart';

class SeedGenerator {
  static const _uuid = Uuid();
  
  static Event generateSeedEvent() {
    final startDate = DateTime.now();
    final endDate = startDate.add(const Duration(days: 7));
    
    return Event(
      uuid: 'seed-event-${_uuid.v4()}',
      startDate: startDate,
      endDate: endDate,
      sectors: [
        _generateBar(),
        _generateSecurity(),
        _generateStage(),
      ],
    );
  }
  
  static Sector _generateBar() {
    return Sector(
      id: 'bar-${_uuid.v4()}',
      name: 'Bar',
      positions: [
        Position(
          id: 'bartender-${_uuid.v4()}',
          name: 'Bartender',
          shifts: _generateShifts('Bartender', ['Ouverture', 'Après-midi', 'Soirée']),
        ),
        Position(
          id: 'runner-${_uuid.v4()}',
          name: 'Runner',
          shifts: _generateShifts('Runner', ['Matin', 'Soir']),
        ),
      ],
    );
  }
  
  static Sector _generateSecurity() {
    return Sector(
      id: 'security-${_uuid.v4()}',
      name: 'Sécurité',
      positions: [
        Position(
          id: 'entrance-${_uuid.v4()}',
          name: 'Entrée principale',
          shifts: _generateShifts('Sécurité', ['Jour', 'Nuit']),
        ),
        Position(
          id: 'vip-${_uuid.v4()}',
          name: 'Zone VIP',
          shifts: _generateShifts('VIP', ['Soirée']),
        ),
      ],
    );
  }
  
  static Sector _generateStage() {
    return Sector(
      id: 'stage-${_uuid.v4()}',
      name: 'Scène',
      positions: [
        Position(
          id: 'tech-${_uuid.v4()}',
          name: 'Technicien son',
          shifts: _generateShifts('Tech', ['Installation', 'Event', 'Démontage']),
        ),
        Position(
          id: 'light-${_uuid.v4()}',
          name: 'Technicien lumière',
          shifts: _generateShifts('Light', ['Installation', 'Event', 'Démontage']),
        ),
      ],
    );
  }
  
  static List<Shift> _generateShifts(String prefix, List<String> labels) {
    final baseDate = DateTime.now();
    final shifts = <Shift>[];
    
    for (final label in labels) {
      // Créer des shifts pour chaque jour de l'événement
      for (var i = 0; i < 7; i++) {
        final shiftDate = baseDate.add(Duration(days: i));
        final startTime = _getStartTimeForLabel(label, shiftDate);
        final endTime = _getEndTimeForLabel(label, shiftDate);
        
        shifts.add(Shift(
          id: '$prefix-$label-${_uuid.v4()}',
          label: label,
          startTime: startTime,
          endTime: endTime,
          excludedDates: {},  // Optionnel : ajouter des dates exclues aléatoires
        ));
      }
    }
    
    return shifts;
  }
  
  static DateTime _getStartTimeForLabel(String label, DateTime date) {
    switch (label.toLowerCase()) {
      case 'ouverture':
        return DateTime(date.year, date.month, date.day, 8, 0);
      case 'après-midi':
        return DateTime(date.year, date.month, date.day, 14, 0);
      case 'soirée':
        return DateTime(date.year, date.month, date.day, 19, 0);
      case 'matin':
        return DateTime(date.year, date.month, date.day, 9, 0);
      case 'soir':
        return DateTime(date.year, date.month, date.day, 18, 0);
      case 'jour':
        return DateTime(date.year, date.month, date.day, 8, 0);
      case 'nuit':
        return DateTime(date.year, date.month, date.day, 20, 0);
      case 'installation':
        return DateTime(date.year, date.month, date.day, 8, 0);
      case 'event':
        return DateTime(date.year, date.month, date.day, 14, 0);
      case 'démontage':
        return DateTime(date.year, date.month, date.day, 22, 0);
      default:
        return DateTime(date.year, date.month, date.day, 9, 0);
    }
  }
  
  static DateTime _getEndTimeForLabel(String label, DateTime date) {
    switch (label.toLowerCase()) {
      case 'ouverture':
        return DateTime(date.year, date.month, date.day, 14, 0);
      case 'après-midi':
        return DateTime(date.year, date.month, date.day, 19, 0);
      case 'soirée':
        return DateTime(date.year, date.month, date.day, 2, 0).add(const Duration(days: 1));
      case 'matin':
        return DateTime(date.year, date.month, date.day, 14, 0);
      case 'soir':
        return DateTime(date.year, date.month, date.day, 23, 0);
      case 'jour':
        return DateTime(date.year, date.month, date.day, 20, 0);
      case 'nuit':
        return DateTime(date.year, date.month, date.day, 8, 0).add(const Duration(days: 1));
      case 'installation':
        return DateTime(date.year, date.month, date.day, 14, 0);
      case 'event':
        return DateTime(date.year, date.month, date.day, 22, 0);
      case 'démontage':
        return DateTime(date.year, date.month, date.day, 4, 0).add(const Duration(days: 1));
      default:
        return DateTime(date.year, date.month, date.day, 17, 0);
    }
  }
}