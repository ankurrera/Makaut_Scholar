import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'dart:async';

class QuizScreen extends StatefulWidget {
  final String title;
  final List<QuizQuestion> questions;

  const QuizScreen({
    super.key,
    required this.title,
    required this.questions,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedAnswerIndex;
  bool _isAnswered = false;
  late Timer _timer;
  int _remainingTime = 30; // 30 seconds per question

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _remainingTime = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() => _remainingTime--);
      } else {
        _submitAnswer(-1); // Time's up
      }
    });
  }

  void _submitAnswer(int index) {
    if (_isAnswered) return;
    _timer.cancel();

    setState(() {
      _selectedAnswerIndex = index;
      _isAnswered = true;
      if (index == widget.questions[_currentIndex].correctIndex) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswerIndex = null;
        _isAnswered = false;
      });
      _startTimer();
    } else {
      _showResults();
    }
  }

  void _showResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF171A21) 
          : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Quiz Completed!', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.award, color: Colors.amber, size: 64),
            const SizedBox(height: 16),
            Text(
              'Your Score: $_score / ${widget.questions.length}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _score >= widget.questions.length / 2 
                ? 'Great job, Scholar!' 
                : 'Keep practicing!',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit quiz
            },
            child: const Text('Return to Practice'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF8E82FF) : const Color(0xFF7C6FF6);
    final currentQuestion = widget.questions[_currentIndex];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1115) : const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.close_circle, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text(
                '$_remainingTime s',
                style: TextStyle(
                  color: _remainingTime < 10 ? Colors.red : primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / widget.questions.length,
                backgroundColor: primaryColor.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Question ${_currentIndex + 1} of ${widget.questions.length}',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              currentQuestion.text,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 32),
            ...List.generate(currentQuestion.options.length, (index) {
              return _buildOption(index, isDark, primaryColor);
            }),
            const Spacer(),
            if (_isAnswered)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _nextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    _currentIndex == widget.questions.length - 1 ? 'Finish Quiz' : 'Next Question',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(int index, bool isDark, Color primaryColor) {
    final isSelected = _selectedAnswerIndex == index;
    final isCorrect = index == widget.questions[_currentIndex].correctIndex;
    
    Color borderColor = isDark ? const Color(0xFF2A2F3A) : const Color(0xFFE6E8EC);
    Color? bgColor = isDark ? const Color(0xFF171A21) : Colors.white;

    if (_isAnswered) {
      if (isCorrect) {
        borderColor = Colors.green;
        bgColor = Colors.green.withValues(alpha: 0.1);
      } else if (isSelected) {
        borderColor = Colors.red;
        bgColor = Colors.red.withValues(alpha: 0.1);
      }
    } else if (isSelected) {
      borderColor = primaryColor;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _submitAnswer(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.questions[_currentIndex].options[index],
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (_isAnswered && isCorrect)
                const Icon(Icons.check_circle, color: Colors.green)
              else if (_isAnswered && isSelected && !isCorrect)
                const Icon(Icons.cancel, color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }
}

class QuizQuestion {
  final String text;
  final List<String> options;
  final int correctIndex;

  QuizQuestion({
    required this.text,
    required this.options,
    required this.correctIndex,
  });
}
