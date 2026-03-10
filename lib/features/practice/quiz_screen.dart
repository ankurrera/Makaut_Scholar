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
  late List<int?> _selectedAnswers;
  late List<int> _remainingTimes; // Track time per question
  late List<QuizQuestion> _shuffledQuestions;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _shuffledQuestions = widget.questions.map((q) {
      // Remove prefixes like A., B), (C), d. etc.
      String cleanOption(String opt) {
        return opt
            .replaceAll(RegExp(r'^([A-Da-d][\.\)]|\([A-Da-d]\))\s*'), '')
            .trim();
      }

      final List<String> cleanOptions = q.options.map(cleanOption).toList();
      final String correctOption = cleanOptions[q.correctIndex];

      final List<String> options = List.from(cleanOptions);
      options.shuffle();

      return QuizQuestion(
        text: q.text,
        options: options,
        correctIndex: options.indexOf(correctOption),
      );
    }).toList();
    _selectedAnswers = List.filled(_shuffledQuestions.length, null);
    _remainingTimes = List.filled(_shuffledQuestions.length, 30);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (_selectedAnswers[_currentIndex] != null) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTimes[_currentIndex] > 0) {
        setState(() => _remainingTimes[_currentIndex]--);
      } else {
        _submitAnswer(-1); // Time's up
      }
    });
  }

  void _submitAnswer(int index) {
    if (_selectedAnswers[_currentIndex] != null) return;
    _timer?.cancel();

    setState(() {
      _selectedAnswers[_currentIndex] = index;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _shuffledQuestions.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _startTimer();
    } else {
      _showResults();
    }
  }

  void _prevQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _startTimer();
    }
  }

  void _showResults() {
    int totalScore = 0;
    for (int i = 0; i < _shuffledQuestions.length; i++) {
      if (_selectedAnswers[i] == _shuffledQuestions[i].correctIndex) {
        totalScore++;
      }
    }

    final double percentage = (totalScore / _shuffledQuestions.length) * 100;

    // Achievement Badge Logic
    IconData badgeIcon;
    Color badgeColor;
    String badgeTitle;
    String feedback;

    if (percentage >= 90) {
      badgeIcon = Iconsax.crown;
      badgeColor = Colors.amber;
      badgeTitle = 'Grand Scholar';
      feedback = 'Outstanding! You have mastered this subject.';
    } else if (percentage >= 60) {
      badgeIcon = Iconsax.award;
      badgeColor = Colors.blueGrey;
      badgeTitle = 'Ace Researcher';
      feedback = 'Great job! You have a solid understanding.';
    } else {
      badgeIcon = Iconsax.book;
      badgeColor = Colors.brown;
      badgeTitle = 'Rising Learner';
      feedback = 'Keep grinding! Consistency is the key to mastery.';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1C2020)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(badgeIcon, color: badgeColor, size: 64),
            ),
            const SizedBox(height: 16),
            Text(
              badgeTitle,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: badgeColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your Score: $totalScore / ${_shuffledQuestions.length}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Text(
              feedback,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, height: 1.4),
            ),
            const SizedBox(height: 24),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Exit quiz
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: badgeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Return to Practice',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        isDark ? const Color(0xFFE5252A) : const Color(0xFFE5252A);
    final currentQuestion = _shuffledQuestions[_currentIndex];
    final isAnswered = _selectedAnswers[_currentIndex] != null;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121512) : const Color(0xFFF8F6F1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.close_circle,
              color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
              color: isDark ? Colors.white : Colors.black, fontSize: 18),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text(
                '${_remainingTimes[_currentIndex]} s',
                style: TextStyle(
                  color: _remainingTimes[_currentIndex] < 10
                      ? Colors.red
                      : primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (_currentIndex + 1) / _shuffledQuestions.length,
                      backgroundColor: primaryColor.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Question ${_currentIndex + 1} of ${_shuffledQuestions.length}',
                    style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.grey,
                        fontSize: 14),
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
                ],
              ),
            ),
          ),
          _buildNavigation(isDark, primaryColor),
        ],
      ),
    );
  }

  Widget _buildNavigation(bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2020) : Colors.white,
        border: Border(
            top: BorderSide(
                color: isDark
                    ? const Color(0xFF2A3030)
                    : const Color(0xFFE6E8EC))),
      ),
      child: Row(
        children: [
          if (_currentIndex > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _prevQuestion,
                icon: const Icon(Iconsax.arrow_left_2),
                label: const Text('Previous'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          if (_currentIndex > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _nextQuestion,
              icon: Icon(_currentIndex == _shuffledQuestions.length - 1
                  ? Iconsax.tick_circle
                  : Iconsax.arrow_right_3),
              label: Text(_currentIndex == _shuffledQuestions.length - 1
                  ? 'Finish'
                  : 'Next'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(int index, bool isDark, Color primaryColor) {
    final selectedAnswer = _selectedAnswers[_currentIndex];
    final isSelected = selectedAnswer == index;
    final isCorrect = index == _shuffledQuestions[_currentIndex].correctIndex;
    final isAnswered = selectedAnswer != null;

    Color borderColor =
        isDark ? const Color(0xFF2A3030) : const Color(0xFFE6E8EC);
    Color? bgColor = isDark ? const Color(0xFF1C2020) : Colors.white;

    if (isAnswered) {
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
                  _shuffledQuestions[_currentIndex].options[index],
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (isAnswered && isCorrect)
                const Icon(Icons.check_circle, color: Colors.green)
              else if (isAnswered && isSelected && !isCorrect)
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
