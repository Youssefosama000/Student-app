import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/course.dart';
import '../models/quiz.dart';
import '../models/student_session.dart';

class StudentProvider extends ChangeNotifier {
  final Uuid _uuid = const Uuid();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Firestore collection references
  final CollectionReference _coursesCollection = 
      FirebaseFirestore.instance.collection('courses');
  final CollectionReference _quizzesCollection = 
      FirebaseFirestore.instance.collection('quizzes');
  final CollectionReference _studentSessionsCollection = 
      FirebaseFirestore.instance.collection('studentSessions');
  
  // Local lists (updated by real-time listeners)
  final List<Course> _courses = [];
  final List<Quiz> _quizzes = [];
  StudentSession? _currentSession;

  List<Course> get courses => _courses;
  List<Quiz> get quizzes => _quizzes;
  StudentSession? get currentSession => _currentSession;

  StudentProvider() {
    _setupListeners();
  }

  // Set up real-time listeners
  void _setupListeners() {
    // Listen to courses
    _coursesCollection.snapshots().listen((snapshot) {
      _courses.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          _courses.add(Course.fromJson(data));
        }
      }
      notifyListeners();
    });

    // Listen to quizzes
    _quizzesCollection.snapshots().listen((snapshot) {
      _quizzes.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          _quizzes.add(Quiz.fromJson(data));
        }
      }
      notifyListeners();
    });
  }

  // Listen to current session
  void listenToSession(String sessionId) {
    _studentSessionsCollection.doc(sessionId).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>?;
        if (data != null) {
          _currentSession = StudentSession.fromJson(data);
          notifyListeners();
        }
      }
    });
  }

  List<Quiz> getQuizzesByCourse(String courseId) {
    return _quizzes.where((quiz) => quiz.courseId == courseId).toList();
  }

  List<Quiz> searchQuizzesByDate(DateTime date) {
    return _quizzes.where((quiz) {
      return quiz.quizDate.year == date.year &&
             quiz.quizDate.month == date.month &&
             quiz.quizDate.day == date.day;
    }).toList();
  }

  // Check if student can join quiz (2-student limit + one-time attempt)
  Future<bool> canStudentJoinQuiz(String quizId, String studentName) async {
    // Check if student already took this quiz
    final existingSessions = await _studentSessionsCollection
        .where('quizId', isEqualTo: quizId)
        .where('studentName', isEqualTo: studentName)
        .get();
    
    if (existingSessions.docs.isNotEmpty) {
      return false; // Student already took this quiz
    }
    
    // Check if quiz has less than 2 active students
    final activeSessions = await _studentSessionsCollection
        .where('quizId', isEqualTo: quizId)
        .where('status', isEqualTo: 'active')
        .get();
    
    return activeSessions.docs.length < 2;
  }

  // Start quiz session
  Future<StudentSession?> startQuiz(String quizId, String studentName) async {
    // Check if can join
    final canJoin = await canStudentJoinQuiz(quizId, studentName);
    if (!canJoin) {
      return null;
    }

    final session = StudentSession(
      id: _uuid.v4(),
      studentName: studentName,
      quizId: quizId,
      startTime: DateTime.now(),
      currentQuestionIndex: 0,
      status: 'active',
    );

    // Save to Firestore
    await _studentSessionsCollection.doc(session.id).set(session.toJson());
    
    // Start listening to this session
    listenToSession(session.id);
    
    _currentSession = session;
    notifyListeners();
    
    return session;
  }

  // Update student answer
  Future<void> updateAnswer(String sessionId, String questionId, bool answer) async {
    final sessionDoc = _studentSessionsCollection.doc(sessionId);
    final sessionDocSnapshot = await sessionDoc.get();
    
    if (sessionDocSnapshot.exists) {
      final data = sessionDocSnapshot.data() as Map<String, dynamic>?;
      if (data == null) return;
      
      final session = StudentSession.fromJson(data);
      final updatedAnswers = Map<String, bool>.from(session.answers);
      updatedAnswers[questionId] = answer;
      
      final updatedSession = StudentSession(
        id: session.id,
        studentName: session.studentName,
        quizId: session.quizId,
        currentQuestionIndex: session.currentQuestionIndex,
        answers: updatedAnswers,
        startTime: session.startTime,
        endTime: session.endTime,
        finalScore: session.finalScore,
        status: session.status,
      );
      
      await sessionDoc.update(updatedSession.toJson());
    }
  }

  // Update current question index
  Future<void> updateQuestionIndex(String sessionId, int questionIndex) async {
    final sessionDoc = _studentSessionsCollection.doc(sessionId);
    final sessionDocSnapshot = await sessionDoc.get();
    
    if (sessionDocSnapshot.exists) {
      final data = sessionDocSnapshot.data() as Map<String, dynamic>?;
      if (data == null) return;
      
      final session = StudentSession.fromJson(data);
      
      final updatedSession = StudentSession(
        id: session.id,
        studentName: session.studentName,
        quizId: session.quizId,
        currentQuestionIndex: questionIndex,
        answers: session.answers,
        startTime: session.startTime,
        endTime: session.endTime,
        finalScore: session.finalScore,
        status: session.status,
      );
      
      await sessionDoc.update(updatedSession.toJson());
    }
  }

  // Calculate final score
  int calculateFinalScore(String quizId, Map<String, bool> answers) {
    final quiz = _quizzes.firstWhere((q) => q.id == quizId);
    int correctCount = 0;
    
    for (var question in quiz.questions) {
      final studentAnswer = answers[question.id];
      if (studentAnswer != null && studentAnswer == question.correctAnswer) {
        correctCount++;
      }
    }
    return correctCount;
  }

  // Complete quiz
  Future<void> completeQuiz(String sessionId, {bool quit = false}) async {
    final sessionDoc = _studentSessionsCollection.doc(sessionId);
    final sessionDocSnapshot = await sessionDoc.get();
    
    if (sessionDocSnapshot.exists) {
      final data = sessionDocSnapshot.data() as Map<String, dynamic>?;
      if (data == null) return;
      
      final session = StudentSession.fromJson(data);
      final quiz = _quizzes.firstWhere((q) => q.id == session.quizId);
      
      int score = 0;
      if (!quit) {
        score = calculateFinalScore(session.quizId, session.answers);
      }
      
      final completedSession = StudentSession(
        id: session.id,
        studentName: session.studentName,
        quizId: session.quizId,
        currentQuestionIndex: session.currentQuestionIndex,
        answers: session.answers,
        startTime: session.startTime,
        endTime: DateTime.now(),
        finalScore: score,
        status: 'completed',
      );
      
      await sessionDoc.update(completedSession.toJson());
      // Keep current session so UI can read the finalScore immediately
      _currentSession = completedSession;
      notifyListeners();
    }
  }

  // Get quiz by ID
  Quiz? getQuizById(String quizId) {
    try {
      return _quizzes.firstWhere((quiz) => quiz.id == quizId);
    } catch (e) {
      return null;
    }
  }
}

