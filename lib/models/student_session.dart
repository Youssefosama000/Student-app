class StudentSession {
  final String id;
  final String studentName;
  final String quizId;
  final int currentQuestionIndex;
  final Map<String, bool> answers;
  final DateTime startTime;
  final DateTime? endTime;
  final int? finalScore;
  final String status;

  StudentSession({
    required this.id,
    required this.studentName,
    required this.quizId,
    this.currentQuestionIndex = 0,
    Map<String, bool>? answers,
    required this.startTime,
    this.endTime,
    this.finalScore,
    this.status = 'active',
  }) : answers = answers ?? {};

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentName': studentName,
      'quizId': quizId,
      'currentQuestionIndex': currentQuestionIndex,
      'answers': answers,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'finalScore': finalScore,
      'status': status,
    };
  }

  // Create from JSON (from Firestore)
  factory StudentSession.fromJson(Map<String, dynamic> json) {
    return StudentSession(
      id: json['id'] as String,
      studentName: json['studentName'] as String,
      quizId: json['quizId'] as String,
      currentQuestionIndex: json['currentQuestionIndex'] as int? ?? 0,
      answers: (json['answers'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value as bool),
      ) ?? {},
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null 
          ? DateTime.parse(json['endTime'] as String)
          : null,
      finalScore: json['finalScore'] as int?,
      status: json['status'] as String? ?? 'active',
    );
  }
}

