import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../services/auth_service.dart';
import 'quiz_screen.dart';

class MockTestSubjectScreen extends StatefulWidget {
  final String department;
  final int semester;
  const MockTestSubjectScreen({super.key, required this.department, required this.semester});

  @override
  State<MockTestSubjectScreen> createState() => _MockTestSubjectScreenState();
}

class _MockTestSubjectScreenState extends State<MockTestSubjectScreen> {
  List<String> _subjects = [];
  Map<String, int> _subjectCounts = {};
  bool _isLoading = true;
  String? _error;

  static const _accentColor = Color(0xFF8E82FF);

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final subjects = await auth.fetchMockTestSubjects(widget.department, widget.semester);
      final counts = await auth.fetchSubjectMockTestCounts(widget.department, widget.semester);
      if (mounted) {
        setState(() {
          _subjects = subjects;
          _subjectCounts = counts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startQuiz(String subject) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: _accentColor)),
    );

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final questionsData = await auth.fetchMockTestQuestions(widget.department, widget.semester, subject);
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (questionsData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No questions available for this subject yet.')),
        );
        return;
      }

      final questions = questionsData.map((q) => QuizQuestion(
        text: q['question_text'] as String,
        options: List<String>.from(q['options']),
        correctIndex: q['correct_index'] as int,
      )).toList();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizScreen(
            title: subject,
            questions: questions,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting quiz: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E1E1E);
    final textSecondary = isDark ? const Color(0xFF9AA0A6) : const Color(0xFF8E8E93);
    final bgPrimary = isDark ? const Color(0xFF0F1115) : const Color(0xFFF4F5F7);
    final cardBg = isDark ? const Color(0xFF171A21) : Colors.white;

    return Scaffold(
      backgroundColor: bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Semester ${widget.semester} Subjects',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _accentColor))
          : _error != null
              ? _buildError(textPrimary, textSecondary)
              : _subjects.isEmpty
                  ? _buildEmpty(textPrimary, textSecondary)
                  : RefreshIndicator(
                      onRefresh: _loadSubjects,
                      color: _accentColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: _subjects.length,
                        itemBuilder: (context, index) {
                          final subject = _subjects[index];
                          final count = _subjectCounts[subject] ?? 0;
                          return _buildSubjectCard(subject, count, isDark, textPrimary, textSecondary, cardBg);
                        },
                      ),
                    ),
    );
  }

  Widget _buildSubjectCard(String subject, int count, bool isDark, Color textP, Color textS, Color cardBg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF2A2F3A) : const Color(0xFFE6E8EC)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Iconsax.document_text, color: _accentColor, size: 24),
        ),
        title: Text(
          subject,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text('$count Questions Available', style: TextStyle(color: textS, fontSize: 12)),
        trailing: Icon(Iconsax.play_circle, color: _accentColor, size: 24),
        onTap: () => _startQuiz(subject),
      ),
    );
  }

  Widget _buildEmpty(Color textP, Color textS) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.note_remove, size: 64, color: textS.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('No subjects with quizzes', style: TextStyle(color: textP, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Try later for this semester', style: TextStyle(color: textS)),
        ],
      ),
    );
  }

  Widget _buildError(Color textP, Color textS) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Iconsax.warning_2, size: 48, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text('Failed to load subjects', style: TextStyle(color: textP, fontWeight: FontWeight.bold)),
          TextButton(onPressed: _loadSubjects, child: const Text('Retry', style: TextStyle(color: _accentColor))),
        ],
      ),
    );
  }
}
