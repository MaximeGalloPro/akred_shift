import 'shift.dart';

class Position {
  final String id;
  final String name;
  final List<Shift> shifts;

  const Position({
    required this.id,
    required this.name,
    this.shifts = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'shifts': shifts.map((s) => s.toJson()).toList(),
  };

  factory Position.fromJson(Map<String, dynamic> json) => Position(
    id: json['id'],
    name: json['name'],
    shifts: (json['shifts'] as List).map((s) => Shift.fromJson(s as Map<String, dynamic>)).toList(),
  );
}