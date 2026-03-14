import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/cache_service.dart';
import '../../core/widgets/dot_loading.dart';
import '../../core/widgets/shimmer_skeleton.dart';
import 'quiz_screen.dart';

class MockTestSubjectScreen extends StatefulWidget {
  final String department;
  final int semester;
  const MockTestSubjectScreen(
      {super.key, required this.department, required this.semester});

  @override
  State<MockTestSubjectScreen> createState() => _MockTestSubjectScreenState();
}

class _MockTestSubjectScreenState extends State<MockTestSubjectScreen> {
  List<String> _subjects = [];
  Map<String, int> _subjectCounts = {};
  bool _isLoading = true;
  String? _error;

  static const _accentColor = Color(0xFFE5252A);

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() {
      _error = null;
    });
    try {
      final auth = Provider.of<AuthService>(context, listen: false);

      // 1. Try to load from cache
      final subjKey = 'mock_test_subjects_${widget.department}_${widget.semester}';
      final countsKey = 'mock_test_counts_${widget.department}_${widget.semester}';
      
      final cachedSubjs = CacheService().get(subjKey);
      final cachedCounts = CacheService().get(countsKey);

      if (cachedSubjs != null && cachedSubjs is List && cachedCounts != null && cachedCounts is Map) {
        setState(() {
          _subjects = List<String>.from(cachedSubjs);
          _subjectCounts = Map<String, int>.from(cachedCounts);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = true);
      }

      final subjects =
          await auth.fetchMockTestSubjects(widget.department, widget.semester);
      final counts = await auth.fetchSubjectMockTestCounts(
          widget.department, widget.semester);
      if (mounted) {
        setState(() {
          _subjects = subjects;
          _subjectCounts = counts;
          _isLoading = false;
        });
        
        // Update cache
        CacheService().set(subjKey, subjects);
        CacheService().set(countsKey, counts);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF191919);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ShimmerSkeleton(width: 64, height: 64, borderRadius: BorderRadius.all(Radius.circular(32))),
              const SizedBox(height: 16),
              Text('PREPARING QUIZ',
                  style: TextStyle(
                      fontFamily: 'NDOT',
                      color: textPrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0)),
            ],
          ),
        ),
      ),
    );

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final questionsData = await auth.fetchMockTestQuestions(
          widget.department, widget.semester, subject);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (questionsData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No questions available for this subject yet.')),
        );
        return;
      }

      final questions = questionsData
          .map((q) => QuizQuestion(
                text: q['question_text'] as String,
                options: List<String>.from(q['options']),
                correctIndex: q['correct_index'] as int,
              ))
          .toList();

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
    final textSecondary =
        isDark ? const Color(0xFF9AA0A6) : const Color(0xFF8E8E93);
    final bgPrimary =
        isDark ? const Color(0xFF121512) : const Color(0xFFF8F6F1);
    final cardBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return Scaffold(
      backgroundColor: bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'SEMESTER ${widget.semester} SUBJECTS',
          style: TextStyle(
              fontFamily: 'NDOT',
              color: textPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              fontSize: 18),
        ),
      ),
      body: _isLoading && _subjects.isEmpty
          ? _buildLoadingSkeleton(isDark)
          : _error != null
              ? _buildError(textPrimary, textSecondary)
              : _subjects.isEmpty
                  ? _buildEmpty(textPrimary, textSecondary)
                  : RefreshIndicator(
                      onRefresh: _loadSubjects,
                      color: _accentColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        itemCount: _subjects.length,
                        itemBuilder: (context, index) {
                          final subject = _subjects[index];
                          final count = _subjectCounts[subject] ?? 0;
                          return _buildSubjectCard(subject, count, isDark,
                              textPrimary, textSecondary, cardBg);
                        },
                      ),
                    ),
    );
  }

  Widget _buildSubjectCard(String subject, int count, bool isDark, Color textP,
      Color textS, Color cardBg) {
    final borderColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F2);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _startQuiz(subject),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Iconsax.document_text, color: textP, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: textP, fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text('$count Questions Available',
                          style: TextStyle(color: textS, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Iconsax.play_circle, color: _accentColor, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(Color textP, Color textS) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.note_remove,
              size: 64, color: textS.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text('NO SUBJECTS WITH QUIZZES',
              style: TextStyle(
                  fontFamily: 'NDOT',
                  color: textP, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
          const SizedBox(height: 8),
          Text('Try later for this semester', style: TextStyle(color: textS, fontWeight: FontWeight.w500)),
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
          Text('FAILED TO LOAD SUBJECTS',
              style: TextStyle(fontFamily: 'NDOT', color: Colors.redAccent, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
          const SizedBox(height: 12),
          GestureDetector(
                onTap: _loadSubjects,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: _accentColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('RETRY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: 6,
      itemBuilder: (context, index) => ShimmerSkeleton.listTile(isDark: isDark),
    );
  }
}
