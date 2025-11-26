import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/course.dart';
import '../models/quiz.dart';
import '../providers/student_provider.dart';
import '../providers/auth_provider.dart';
import 'quiz_taking_screen.dart';

class QuizListScreen extends StatefulWidget {
  final Course course;

  const QuizListScreen({Key? key, required this.course}) : super(key: key);

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  DateTime? _selectedDate;
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.name),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _selectedDate = null;
                }
              });
            },
          ),
        ],
      ),
      body: Consumer<StudentProvider>(
        builder: (context, provider, child) {
          List<Quiz> quizzes = provider.getQuizzesByCourse(widget.course.id);
          
          // Filter by date if searching
          if (_isSearching && _selectedDate != null) {
            quizzes = provider.searchQuizzesByDate(_selectedDate!);
            quizzes = quizzes.where((q) => q.courseId == widget.course.id).toList();
          }

          return Column(
            children: [
              if (_isSearching)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue[50],
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                _selectedDate = picked;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedDate == null
                                      ? 'Select date to search'
                                      : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_selectedDate != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _selectedDate = null;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              if (quizzes.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isSearching && _selectedDate != null
                              ? Icons.search_off
                              : Icons.quiz,
                          size: 100,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _isSearching && _selectedDate != null
                              ? 'No quizzes found for this date'
                              : 'No quizzes available',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: quizzes.length,
                    itemBuilder: (context, index) {
                      Quiz quiz = quizzes[index];
                      return _buildQuizCard(context, quiz, provider);
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuizCard(BuildContext context, Quiz quiz, StudentProvider provider) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _handleQuizTap(context, quiz, provider),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      quiz.quizName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${quiz.questions.length} Questions',
                      style: TextStyle(
                        color: Colors.blue[900],
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    dateFormat.format(quiz.quizDate),
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                  const SizedBox(width: 20),
                  Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${quiz.durationInMinutes} min',
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleQuizTap(
    BuildContext context,
    Quiz quiz,
    StudentProvider provider,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final studentName = authProvider.getStudentName();

    // Check if student can join
    final canJoin = await provider.canStudentJoinQuiz(quiz.id, studentName);
    
    if (!canJoin) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cannot join quiz. Either you already took it or 2 students are already taking it.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Start quiz
    final session = await provider.startQuiz(quiz.id, studentName);
    
    if (session != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizTakingScreen(quiz: quiz, session: session),
        ),
      );
    }
  }
}

