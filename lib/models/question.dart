class Question {
  final String id;
  final String questionText;
  final bool correctAnswer;
  final int order;

  Question({
    required this.id,
    required this.questionText,
    required this.correctAnswer,
    required this.order,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionText': questionText,
      'correctAnswer': correctAnswer,
      'order': order,
    };
  }

  // Create from JSON (from Firestore)
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      questionText: json['questionText'] as String,
      correctAnswer: json['correctAnswer'] as bool,
      order: json['order'] as int,
    );
  }
}

