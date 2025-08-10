class Department {
  final String id;
  final String name;
  final String hod; // Head of Department - Faculty ID

  Department({
    required this.id,
    required this.name,
    required this.hod,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'],
      name: json['name'],
      hod: json['hod'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'hod': hod,
      };
} 