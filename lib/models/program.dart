class Program {
  final String id;
  final String name;
  final String departmentId;

  Program({
    required this.id,
    required this.name,
    required this.departmentId,
  });

  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      id: json['id'],
      name: json['name'],
      departmentId: json['department_id'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'department_id': departmentId,
      };
} 