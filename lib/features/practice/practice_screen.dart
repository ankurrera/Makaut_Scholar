import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/cache_service.dart';
import '../../core/widgets/dot_loading.dart';
import '../../core/widgets/shimmer_skeleton.dart';
import '../../core/widgets/premium_route.dart';
import 'mock_test_subject_screen.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  List<int> _semesters = [];
  bool _isLoading = true;
  String? _error;
  String? _userDepartment;

  static const _accentColor = Color(0xFFE5252A);

  @override
  void initState() {
    super.initState();
    _loadSemesters();
  }

  Future<void> _loadSemesters() async {
    setState(() {
      _error = null;
    });

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      
      // 1. Try to load from cache first
      final cachedSems = CacheService().get('mock_test_semesters');
      if (cachedSems != null && cachedSems is List) {
        setState(() {
          _semesters = List<int>.from(cachedSems);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = true);
      }
      final profile = await auth.getProfile();
      if (profile?['department'] != null) {
        _userDepartment = profile!['department'];
      }

      if (_userDepartment == null || _userDepartment!.isEmpty) {
        if (mounted) {
          setState(() {
            _error = 'department_missing';
            _isLoading = false;
          });
        }
        return;
      }

      final semesters = await auth.fetchMockTestSemesters(_userDepartment!);
      
      // Update cache
      CacheService().set('mock_test_semesters', semesters);

      if (mounted) {
        setState(() {
          _semesters = semesters;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgPrimary =
        isDark ? const Color(0xFF121512) : const Color(0xFFF8F6F1);
    final Color textPrimary =
        isDark ? Colors.white : const Color(0xFF1E1E1E);
    final Color textSecondary =
        isDark ? const Color(0xFF9AA0A6) : const Color(0xFF8E8E93);
    final Color cardBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return Scaffold(
      backgroundColor: bgPrimary,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadSemesters,
          color: _accentColor,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'PRACTICE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: textPrimary,
                          letterSpacing: 2.0,
                          fontFamily: 'NDOT',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sharpen your skills with mock tests',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildContentSliver(isDark, textPrimary, textSecondary, cardBg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentSliver(
      bool isDark, Color textPrimary, Color textSecondary, Color cardBg) {
    if (_isLoading && _semesters.isEmpty) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => ShimmerSkeleton.listTile(isDark: isDark),
          childCount: 6,
        ),
      );
    }

    if (_error == 'department_missing') {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.profile_delete,
                    size: 64, color: textSecondary.withValues(alpha: 0.1)),
                const SizedBox(height: 16),
                Text('DEPARTMENT REQUIRED',
                    style: TextStyle(
                        fontFamily: 'NDOT',
                        color: textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0)),
                const SizedBox(height: 8),
                Text(
                  'Please update your department in the Profile section to practice quizzes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textSecondary, height: 1.4, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Iconsax.warning_2, size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text('FAILED TO LOAD QUIZZES',
                  style: TextStyle(
                      fontFamily: 'NDOT',
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _loadSemesters,
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
        ),
      );
    }

    if (_semesters.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Iconsax.document_filter,
                  size: 64, color: textSecondary.withValues(alpha: 0.1)),
              const SizedBox(height: 16),
              Text('NO QUIZZES AVAILABLE',
                  style: TextStyle(
                      fontFamily: 'NDOT',
                      color: textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0)),
              const SizedBox(height: 8),
              Text('Try later for ${_userDepartment ?? 'your department'}',
                  style: TextStyle(color: textSecondary, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final semester = _semesters[index];
            return _buildSemesterCard(
                semester, isDark, textPrimary, textSecondary, cardBg);
          },
          childCount: _semesters.length,
        ),
      ),
    );
  }

  Widget _buildSemesterCard(int semester, bool isDark, Color textPrimary,
      Color textSecondary, Color cardBg) {
    final borderColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F2);
    
    return PressableWidget(
      onTap: () {
        if (_userDepartment != null) {
          Navigator.push(
            context,
            PremiumPageRoute(
              page: MockTestSubjectScreen(
                department: _userDepartment!,
                semester: semester,
              ),
            ),
          );
        }
      },
      child: Container(
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Iconsax.book_1, color: textPrimary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SEMESTER $semester',
                    style: TextStyle(
                        fontFamily: 'NDOT',
                        color: textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 2),
                  Text('Select to view subjects',
                      style: TextStyle(color: textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.arrow_right_3, color: textSecondary, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}
