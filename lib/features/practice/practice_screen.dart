import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
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

  static const _accentColor = Color(0xFF8E82FF);

  @override
  void initState() {
    super.initState();
    _loadSemesters();
  }

  Future<void> _loadSemesters() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
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

    // Palette
    final Color bgPrimary = isDark ? const Color(0xFF0F1115) : const Color(0xFFF4F5F7);
    final Color textPrimary = isDark ? const Color(0xFFF5F6FA) : const Color(0xFF1E1E1E);
    final Color textSecondary = isDark ? const Color(0xFF9AA0A6) : const Color(0xFF8E8E93);
    final Color cardBg = isDark ? const Color(0xFF171A21) : Colors.white;

    return Scaffold(
      backgroundColor: bgPrimary,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadSemesters,
          color: _accentColor,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
                        'Sharpen your skills with mock tests',
                        style: TextStyle(
                          fontSize: 16,
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

  Widget _buildContentSliver(bool isDark, Color textPrimary, Color textSecondary, Color cardBg) {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(color: _accentColor)),
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
                Icon(Iconsax.profile_delete, size: 64, color: textSecondary.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text('Department Required', style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  'Please update your department in the Profile section to practice quizzes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textSecondary, height: 1.4),
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
              Text('Failed to load quizzes', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextButton(onPressed: _loadSemesters, child: const Text('Retry', style: TextStyle(color: _accentColor))),
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
              Icon(Iconsax.document_filter, size: 64, color: textSecondary.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text('No quizzes available', style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Try later for ${_userDepartment ?? 'your department'}', style: TextStyle(color: textSecondary)),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final semester = _semesters[index];
            return _buildSemesterCard(semester, isDark, textPrimary, textSecondary, cardBg);
          },
          childCount: _semesters.length,
        ),
      ),
    );
  }

  Widget _buildSemesterCard(int semester, bool isDark, Color textPrimary, Color textSecondary, Color cardBg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF2A2F3A) : const Color(0xFFE6E8EC)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Iconsax.book_1, color: _accentColor, size: 24),
        ),
        title: Text(
          'Semester $semester',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text('Select to view subjects', style: TextStyle(color: textSecondary, fontSize: 13)),
        trailing: Icon(Iconsax.arrow_right_3, color: textSecondary, size: 18),
        onTap: () {
          if (_userDepartment != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MockTestSubjectScreen(
                  department: _userDepartment!,
                  semester: semester,
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
