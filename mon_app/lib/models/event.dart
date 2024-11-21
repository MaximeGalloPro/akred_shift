import 'sector.dart';

class Event {
  final String uuid;
  final DateTime startDate;
  final DateTime endDate;
  final List<Sector> sectors;

  const Event({
    required this.uuid,
    required this.startDate,
    required this.endDate,
    this.sectors = const [],
  });

  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'sectors': sectors.map((s) => s.toJson()).toList(),
  };

  factory Event.fromJson(Map<String, dynamic> json) => Event(
    uuid: json['uuid'],
    startDate: DateTime.parse(json['startDate']),
    endDate: DateTime.parse(json['endDate']),
    sectors: (json['sectors'] as List).map((s) => Sector.fromJson(s as Map<String, dynamic>)).toList(),
  );
}