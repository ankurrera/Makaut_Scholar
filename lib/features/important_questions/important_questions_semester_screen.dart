import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/widgets/modern_folder.dart';
import 'important_questions_subject_screen.dart';

class ImportantQuestionsSemesterScreen extends StatelessWidget {
  final String department;
  const ImportantQuestionsSemesterScreen({super.key, required this.department});

  static const _folderColors = [
    Color(0xFF8B7CF6), // Purple
    Color(0xFF5BAAEF), // Blue
    Color(0xFF34A875), // Green
    Color(0xFFFF708D), // Pink
    Color(0xFFF0A850), // Amber
    Color(0xFF6BBAFF), // Sky
    Color(0xFFE88AA0), // Rose
    Color(0xFFA07EF0), // Violet
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1115) : const Color(0xFFF4F5F7),
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
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF171A21) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? const Color(0xFF2A2F3A) : const Color(0xFFE6E8EC)),
                        ),
                        child: Icon(Iconsax.arrow_left_2, size: 20, color: isDark ? Colors.white : Colors.black),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Exam Focus',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Select any Semester to View Repeated Questions',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? const Color(0xFF9AA0A6) : const Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final semester = index + 1;
                    final color = _folderColors[index % _folderColors.length];
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ImportantQuestionsSubjectScreen(
                                department: department,
                                semester: semester,
                              ),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF171A21) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? const Color(0xFF2A2F3A) : const Color(0xFFE6E8EC),
                              ),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 64,
                                  height: 52,
                                  child: ModernFolder(
                                    color: color,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Semester $semester',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Iconsax.arrow_right_3, size: 18, color: color.withValues(alpha: 0.5)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: 8,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}
