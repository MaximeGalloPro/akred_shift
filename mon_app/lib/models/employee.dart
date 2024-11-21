class Employee {
  final String uuid;
  final String firstName;
  final String lastName;

  const Employee({
    required this.uuid,
    required this.firstName,
    required this.lastName,
  });

  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'firstName': firstName,
    'lastName': lastName,
  };

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
    uuid: json['uuid'],
    firstName: json['firstName'],
    lastName: json['lastName'],
  );
}