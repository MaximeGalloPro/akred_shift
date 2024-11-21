import 'employee.dart';

class Shift {
  final String id;
  final String label;
  final DateTime startTime;
  final DateTime endTime;
  final Employee? assignedEmployee;
  final Set<DateTime> excludedDates;

  const Shift({
    required this.id,
    required this.label,
    required this.startTime,
    required this.endTime,
    this.assignedEmployee,
    this.excludedDates = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'assignedEmployee': assignedEmployee?.toJson(),
    'excludedDates': excludedDates.map((date) => date.toIso8601String()).toList(),
  };

  factory Shift.fromJson(Map<String, dynamic> json) => Shift(
    id: json['id'],
    label: json['label'],
    startTime: DateTime.parse(json['startTime']),
    endTime: DateTime.parse(json['endTime']),
    assignedEmployee: json['assignedEmployee'] != null 
      ? Employee.fromJson(json['assignedEmployee']) 
      : null,
    excludedDates: (json['excludedDates'] as List?)
        ?.map((date) => DateTime.parse(date))
        ?.toSet() ?? {},
  );
}