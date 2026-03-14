import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/cache_service.dart';
import '../../core/widgets/solid_folder.dart';
import '../../core/widgets/dot_loading.dart';
import '../../core/widgets/shimmer_skeleton.dart';
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
  State<ImportantQuestionsSubjectScreen> createState() =>
      _ImportantQuestionsSubjectScreenState();
}

class _ImportantQuestionsSubjectScreenState
    extends State<ImportantQuestionsSubjectScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _subjects = []; // Changed from List<String>
  Map<String, int> _impCounts = {};
  bool _isLoading = true;
  String? _error;
  late AnimationController _staggerController;

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
    setState(() {
      _error = null;
    });
    try {
      final auth = Provider.of<AuthService>(context, listen: false);

      // 1. Try to load from cache
      final subjKey = 'imp_subjects_${widget.department}_${widget.semester}';
      final countsKey = 'imp_unit_counts_${widget.department}_${widget.semester}';
      
      final cachedSubjs = CacheService().get(subjKey);
      final cachedCounts = CacheService().get(countsKey);

      if (cachedSubjs != null && cachedSubjs is List && cachedCounts != null && cachedCounts is Map) {
        setState(() {
          _subjects = List<Map<String, dynamic>>.from(cachedSubjs);
          _impCounts = Map<String, int>.from(cachedCounts);
          _isLoading = false;
        });
        _staggerController.forward();
      } else {
        setState(() => _isLoading = true);
      }

      final results = await Future.wait([
        auth.fetchDepartmentSubjects(widget.department, widget.semester),
        auth.fetchSubjectImpCounts(widget.department, widget.semester),
      ]);

      if (mounted) {
        setState(() {
          _subjects = results[0] as List<Map<String, dynamic>>;
          _impCounts = results[1] as Map<String, int>;
          _isLoading = false;
        });
        _staggerController.forward();
        
        // Update cache
        CacheService().set(subjKey, results[0]);
        CacheService().set(countsKey, results[1]);
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
      backgroundColor: isDark ? Colors.black : const Color(0xFFF8F6F1),
      body: _isLoading && _subjects.isEmpty
          ? _buildLoadingSkeleton(isDark)
          : SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1C1C1E)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF2C2C2E)
                                          : const Color(0xFFE6E8EC),
                                    ),
                                  ),
                                  child: Icon(Iconsax.arrow_left_2,
                                      size: 20,
                                      color:
                                          isDark ? Colors.white : Colors.black),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Exam Focus',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E1E1E),
                              letterSpacing: -0.5,
                              fontFamily: 'NDOT',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Semester ${widget.semester} · ${widget.department}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'NDOT',
                              color: isDark
                                  ? const Color(0xFF9AA0A6)
                                  : const Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_error != null)
                    SliverFillRemaining(
                      child: Center(
                        child: Text('Error: $_error',
                            style: const TextStyle(color: Colors.red)),
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
                          final v =
                              interval.transform(_staggerController.value);
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

  Widget _subjectTile(
      Map<String, dynamic> subjectData, int index, bool isDark) {
    final String subject = subjectData['subject'];
    final String? paperCode = subjectData['paper_code'];
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
                paperCode: paperCode,
              ),
            ),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE6E8EC),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  height: 48,
                  child: SolidFolder(
                    color: isDark ? Colors.white : const Color(0xFFF2F0EF),
                    borderColor:
                        isDark ? Colors.transparent : const Color(0xFFE5E5EA),
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
                          color:
                              isDark ? Colors.white : const Color(0xFF1E1E1E),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$count Focus Unit${count == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF9AA0A6)
                              : const Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton(bool isDark) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Iconsax.arrow_left),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const ShimmerSkeleton(width: 180, height: 28, isNdot: true),
                const SizedBox(height: 8),
                const ShimmerSkeleton(width: 140, height: 14),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => ShimmerSkeleton.listTile(isDark: isDark),
              childCount: 6,
            ),
          ),
        ),
      ],
    );
  }
}
