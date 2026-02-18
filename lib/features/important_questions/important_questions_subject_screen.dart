import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../services/auth_service.dart';
import '../../core/widgets/modern_folder.dart';
import 'important_questions_list_screen.dart';

class ImportantQuestionsSubjectScreen extends StatefulWidget {
  final String department;
  final int semester;

  const ImportantQuestionsSubjectScreen({
    super.key,
    required this.department,
    required this.semester,
  });

  @override
  State<ImportantQuestionsSubjectScreen> createState() => _ImportantQuestionsSubjectScreenState();
}

class _ImportantQuestionsSubjectScreenState extends State<ImportantQuestionsSubjectScreen>
    with SingleTickerProviderStateMixin {
  List<String> _subjects = [];
  Map<String, int> _impCounts = {};
  bool _isLoading = true;
  String? _error;
  late AnimationController _staggerController;

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
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadData();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final results = await Future.wait([
        auth.fetchDepartmentSubjects(widget.department, widget.semester),
        auth.fetchSubjectImpCounts(widget.department, widget.semester),
      ]);

      if (mounted) {
        setState(() {
          _subjects = results[0] as List<String>;
          _impCounts = results[1] as Map<String, int>;
          _isLoading = false;
        });
        _staggerController.forward();
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
                          border: Border.all(
                            color: isDark ? const Color(0xFF2A2F3A) : const Color(0xFFE6E8EC),
                          ),
                        ),
                        child: Icon(Iconsax.arrow_left_2, size: 20, color: isDark ? Colors.white : Colors.black),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Subjects',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Semester ${widget.semester} · ${widget.department}',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? const Color(0xFF9AA0A6) : const Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                ),
              )
            else if (_subjects.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Text('No subjects found'),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final interval = Interval(
                        (i * 0.1).clamp(0.0, 0.5),
                        ((i * 0.1) + 0.5).clamp(0.0, 1.0),
                        curve: Curves.easeOutCubic,
                      );
                      return AnimatedBuilder(
                        animation: _staggerController,
                        builder: (context, child) {
                          final v = interval.transform(_staggerController.value);
                          return Transform.translate(
                            offset: Offset(0, 24 * (1 - v)),
                            child: Opacity(opacity: v, child: child),
                          );
                        },
                        child: _subjectTile(_subjects[i], i, isDark),
                      );
                    },
                    childCount: _subjects.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _subjectTile(String subject, int index, bool isDark) {
    final color = _folderColors[index % _folderColors.length];
    final count = _impCounts[subject] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ImportantQuestionsListScreen(
                department: widget.department,
                semester: widget.semester,
                subject: subject,
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
                  width: 56,
                  height: 48,
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
                        subject,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$count Focus Unit${count == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: color,
                            letterSpacing: 0.5,
                          ),
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
  }
}
