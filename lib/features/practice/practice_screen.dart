import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'cgpa_calculator_screen.dart';
import 'quiz_screen.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Palette (aligned with home_screen.dart)
    final Color bgPrimary = isDark ? const Color(0xFF0F1115) : const Color(0xFFF4F5F7);
    final Color textPrimary = isDark ? const Color(0xFFF5F6FA) : const Color(0xFF1E1E1E);
    final Color textSecondary = isDark ? const Color(0xFF9AA0A6) : const Color(0xFF8E8E93);

    return Scaffold(
      backgroundColor: bgPrimary,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Practice',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Sharpen your skills & calculate results',
                      style: TextStyle(
                        fontSize: 16,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _PracticeCard(
                    title: 'Mock Tests',
                    subtitle: 'Test your knowledge with subject-specific quizzes based on PYQs.',
                    icon: Iconsax.task_square,
                    color: const Color(0xFF8E82FF),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(
                            title: 'Sample Mock Test',
                            questions: [
                              QuizQuestion(
                                text: 'What is the full form of MAKAUT?',
                                options: [
                                  'Maulana Abul Kalam Azad University of Technology',
                                  'Maharashtra University of Technology',
                                  'Madras University of Technology',
                                  'None of the above'
                                ],
                                correctIndex: 0,
                              ),
                              QuizQuestion(
                                text: 'Which of the following is a core subject in Computer Science?',
                                options: [
                                  'Civil Engineering',
                                  'Data Structures',
                                  'Botany',
                                  'Zoology'
                                ],
                                correctIndex: 1,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    isDark: isDark,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PracticeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _PracticeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF171A21) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? const Color(0xFF2A2F3A) : const Color(0xFFE6E8EC),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? const Color(0xFF9AA0A6) : const Color(0xFF8E8E93),
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
}
