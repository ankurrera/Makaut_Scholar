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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Achievement Badge Logic
    IconData badgeIcon;
    Color badgeColor;
    String badgeTitle;
    String feedback;

    if (percentage >= 90) {
      badgeIcon = Iconsax.crown;
      badgeColor = Colors.amber;
      badgeTitle = 'GRAND SCHOLAR';
      feedback = 'Outstanding! You have mastered this subject.';
    } else if (percentage >= 60) {
      badgeIcon = Iconsax.award;
      badgeColor = Colors.redAccent;
      badgeTitle = 'ACE RESEARCHER';
      feedback = 'Great job! You have a solid understanding.';
    } else {
      badgeIcon = Iconsax.book;
      badgeColor = isDark ? Colors.white54 : Colors.black54;
      badgeTitle = 'RISING LEARNER';
      feedback = 'Keep grinding! Consistency is the key to mastery.';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
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
                fontFamily: 'NDOT',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'SCORE: $totalScore / ${_shuffledQuestions.length}',
              style: TextStyle(
                fontFamily: 'NDOT',
                fontSize: 16, 
                fontWeight: FontWeight.w700,
                color: badgeColor,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              feedback,
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, height: 1.4, fontWeight: FontWeight.w500),
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
                backgroundColor: isDark ? Colors.white : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('RETURN TO PRACTICE',
                  style: TextStyle(fontFamily: 'NDOT', fontWeight: FontWeight.w800, letterSpacing: 1.0)),
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
    final primaryColor = const Color(0xFFE5252A);
    final currentQuestion = _shuffledQuestions[_currentIndex];
    final isAnswered = _selectedAnswers[_currentIndex] != null;
    final textPrimary = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121512) : const Color(0xFFF8F6F1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.close_circle,
              color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          widget.title.toUpperCase(),
          style: TextStyle(
              fontFamily: 'NDOT',
              color: textPrimary, 
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_remainingTimes[_currentIndex]}s',
                  style: TextStyle(
                    fontFamily: 'NDOT',
                    color: _remainingTimes[_currentIndex] < 10
                        ? Colors.red
                        : textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
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
                      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'QUESTION ${_currentIndex + 1} OF ${_shuffledQuestions.length}',
                    style: TextStyle(
                        fontFamily: 'NDOT',
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentQuestion.text,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
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
          _buildNavigation(isDark, primaryColor, textPrimary),
        ],
      ),
    );
  }

  Widget _buildNavigation(bool isDark, Color primaryColor, Color textPrimary) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        border: Border(
            top: BorderSide(
                color: isDark
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFF2F2F2))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Row(
            children: [
              if (_currentIndex > 0)
                Expanded(
                  child: GestureDetector(
                    onTap: _prevQuestion,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.arrow_left_2,
                              color: textPrimary, size: 18),
                          const SizedBox(width: 8),
                          Text('PREVIOUS',
                              style: TextStyle(
                                  fontFamily: 'NDOT',
                                  color: textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  letterSpacing: 1.0)),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_currentIndex > 0) const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: _nextQuestion,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : Colors.black,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentIndex == _shuffledQuestions.length - 1
                              ? 'FINISH'
                              : 'NEXT',
                          style: TextStyle(
                            fontFamily: 'NDOT',
                            color: isDark ? Colors.black : Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentIndex == _shuffledQuestions.length - 1
                              ? Iconsax.tick_circle
                              : Iconsax.arrow_right_3,
                          color: isDark ? Colors.black : Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(int index, bool isDark, Color primaryColor) {
    final selectedAnswer = _selectedAnswers[_currentIndex];
    final isSelected = selectedAnswer == index;
    final isCorrect = index == _shuffledQuestions[_currentIndex].correctIndex;
    final isAnswered = selectedAnswer != null;

    Color borderColor =
        isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F2);
    Color? bgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    Color textColor = isDark ? Colors.white : Colors.black;

    if (isAnswered) {
      if (isCorrect) {
        borderColor = Colors.green;
        bgColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green;
      } else if (isSelected) {
        borderColor = Colors.red;
        bgColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red;
      }
    } else if (isSelected) {
      borderColor = isDark ? Colors.white : Colors.black;
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
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _shuffledQuestions[_currentIndex].options[index],
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                    fontWeight:
                        isSelected ? FontWeight.w800 : FontWeight.w600,
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
