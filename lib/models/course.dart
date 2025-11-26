class Course {
  final String id;
  final String name;
  final String? imagePath;

  Course({
    required this.id,
    required this.name,
    this.imagePath,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imagePath': imagePath,
    };
  }

  // Create from JSON (from Firestore)
  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      name: json['name'] as String,
      imagePath: json['imagePath'] as String?,
    );
  }
}

