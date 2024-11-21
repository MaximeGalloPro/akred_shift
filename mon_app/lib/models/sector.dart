import 'position.dart';

class Sector {
  final String id;
  final String name;
  final List<Position> positions;

  const Sector({
    required this.id,
    required this.name,
    this.positions = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'positions': positions.map((p) => p.toJson()).toList(),
  };

  factory Sector.fromJson(Map<String, dynamic> json) => Sector(
    id: json['id'],
    name: json['name'],
    positions: (json['positions'] as List).map((p) => Position.fromJson(p as Map<String, dynamic>)).toList(),
  );
}