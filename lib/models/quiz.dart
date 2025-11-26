import 'question.dart';

class Quiz {
  final String id;
  final String courseId;
  final String courseName;
  final String quizName;
  final DateTime quizDate;
  final int durationInMinutes;
  final bool showFinalScore;
  final List<Question> questions;

  Quiz({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.quizName,
    required this.quizDate,
    required this.durationInMinutes,
    required this.showFinalScore,
    required this.questions,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'courseName': courseName,
      'quizName': quizName,
      'quizDate': quizDate.toIso8601String(),
      'durationInMinutes': durationInMinutes,
      'showFinalScore': showFinalScore,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }

  // Create from JSON (from Firestore)
  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] as String,
      courseId: json['courseId'] as String,
      courseName: json['courseName'] as String,
      quizName: json['quizName'] as String,
      quizDate: DateTime.parse(json['quizDate'] as String),
      durationInMinutes: json['durationInMinutes'] as int,
      showFinalScore: json['showFinalScore'] as bool,
      questions: (json['questions'] as List)
          .map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }
}

