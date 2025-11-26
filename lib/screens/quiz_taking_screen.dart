import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../models/quiz.dart';
import '../models/student_session.dart';
import '../providers/student_provider.dart';
import '../providers/auth_provider.dart';
import 'courses_screen.dart';

class QuizTakingScreen extends StatefulWidget {
  final Quiz quiz;
  final StudentSession session;

  const QuizTakingScreen({
    Key? key,
    required this.quiz,
    required this.session,
  }) : super(key: key);

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  int _currentQuestionIndex = 0;
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  bool _isQuizCompleted = false;
  Map<String, bool> _answers = {};

  @override
  void initState() {
    super.initState();
    _currentQuestionIndex = widget.session.currentQuestionIndex;
    _answers = Map<String, bool>.from(widget.session.answers);
    
    // Calculate remaining time
    final elapsed = DateTime.now().difference(widget.session.startTime);
    final totalDuration = Duration(minutes: widget.quiz.durationInMinutes);
    _remainingTime = totalDuration - elapsed;
    
    if (_remainingTime.isNegative) {
      _remainingTime = Duration.zero;
      _autoSubmitQuiz();
    } else {
      _startTimer();
    }

    // Listen to session updates
    final provider = Provider.of<StudentProvider>(context, listen: false);
    provider.listenToSession(widget.session.id);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingTime.inSeconds > 0) {
            _remainingTime = Duration(seconds: _remainingTime.inSeconds - 1);
          } else {
            timer.cancel();
            _autoSubmitQuiz();
          }
        });
      }
    });
  }

  void _autoSubmitQuiz() {
    if (_isQuizCompleted) return;
    
    _isQuizCompleted = true;
    _timer?.cancel();
    
    final provider = Provider.of<StudentProvider>(context, listen: false);
    provider.completeQuiz(widget.session.id, quit: false);
    
    if (mounted) {
      _showCompletionDialog(false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _selectAnswer(bool answer) {
    setState(() {
      _answers[widget.quiz.questions[_currentQuestionIndex].id] = answer;
    });

    final provider = Provider.of<StudentProvider>(context, listen: false);
    provider.updateAnswer(
      widget.session.id,
      widget.quiz.questions[_currentQuestionIndex].id,
      answer,
    );
  }

  void _navigateToQuestion(int index) {
    if (index >= 0 && index < widget.quiz.questions.length) {
      setState(() {
        _currentQuestionIndex = index;
      });

      final provider = Provider.of<StudentProvider>(context, listen: false);
      provider.updateQuestionIndex(widget.session.id, index);
    }
  }

  Future<void> _submitQuiz({bool quit = false}) async {
    if (_isQuizCompleted) return;

    _isQuizCompleted = true;
    _timer?.cancel();

    final provider = Provider.of<StudentProvider>(context, listen: false);
    await provider.completeQuiz(widget.session.id, quit: quit);

    if (mounted) {
      _showCompletionDialog(quit);
    }
  }

  void _showCompletionDialog(bool quit) {
    final provider = Provider.of<StudentProvider>(context, listen: false);
    final session = provider.currentSession;
    final score = session?.finalScore ?? 0;
    final totalQuestions = widget.quiz.questions.length;
    final canShowScore = widget.quiz.showFinalScore;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(quit ? 'Quiz Quit' : 'Quiz Completed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (quit)
              const Text('You quit the quiz. Your score is 0.')
            else if (canShowScore)
              Column(
                children: [
                  Text(
                    'Your Score: $score/$totalQuestions',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${((score / totalQuestions) * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              )
            else
              const Text('Quiz completed! Your score will be available later.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const CoursesScreen()),
                (route) => false,
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.quiz.questions[_currentQuestionIndex];
    final currentAnswer = _answers[question.id];
    final isLastQuestion = _currentQuestionIndex == widget.quiz.questions.length - 1;
    final isFirstQuestion = _currentQuestionIndex == 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldQuit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Quit Quiz?'),
            content: const Text(
              'If you quit now, your score will be 0. Are you sure?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Quit'),
              ),
            ],
          ),
        );

        if (shouldQuit == true) {
          _submitQuiz(quit: true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.quiz.quizName),
          centerTitle: true,
          automaticallyImplyLeading: false,
          actions: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _remainingTime.inMinutes < 1
                    ? Colors.red
                    : Colors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(_remainingTime),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Progress indicator
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue[50],
              child: Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (_currentQuestionIndex + 1) / widget.quiz.questions.length,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${_currentQuestionIndex + 1}/${widget.quiz.questions.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Question
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question ${_currentQuestionIndex + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      question.questionText,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildAnswerButton(true, currentAnswer == true),
                    const SizedBox(height: 16),
                    _buildAnswerButton(false, currentAnswer == false),
                  ],
                ),
              ),
            ),

            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: isFirstQuestion ? null : () => _navigateToQuestion(_currentQuestionIndex - 1),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: isLastQuestion
                        ? () => _submitQuiz(quit: false)
                        : () => _navigateToQuestion(_currentQuestionIndex + 1),
                    icon: Icon(isLastQuestion ? Icons.check : Icons.arrow_forward),
                    label: Text(isLastQuestion ? 'Submit' : 'Next'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerButton(bool isTrue, bool isSelected) {
    return InkWell(
      onTap: () => _selectAnswer(isTrue),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[100] : Colors.grey[100],
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey,
                  width: 2,
                ),
                color: isSelected ? Colors.blue : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 16),
            Text(
              isTrue ? 'True' : 'False',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.blue[900] : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

