import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../services/auth_service.dart';
import '../../core/widgets/dot_loading.dart';
import 'mock_test_subject_screen.dart';

class MockTestSemesterScreen extends StatefulWidget {
  final String department;
  const MockTestSemesterScreen({super.key, required this.department});

  @override
  State<MockTestSemesterScreen> createState() => _MockTestSemesterScreenState();
}

class _MockTestSemesterScreenState extends State<MockTestSemesterScreen>
    with SingleTickerProviderStateMixin {
  List<int> _semesters = [];
  bool _isLoading = true;
  String? _error;
  late String _userDepartment;

  static const _accentColor = Color(0xFFE5252A);

  @override
  void initState() {
    super.initState();
    _userDepartment = widget.department;
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
      final semesters = await auth.fetchMockTestSemesters(_userDepartment);
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
          'MOCK TESTS',
          style: TextStyle(
            fontFamily: 'NDOT',
            color: textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
          ),
        ),
      ),
      body: _isLoading && _semesters.isEmpty
          ? _buildLoadingSkeleton(isDark)
          : _error != null
              ? _buildError(isDark, textPrimary, textSecondary)
              : _semesters.isEmpty
                  ? _buildEmpty(isDark, textPrimary, textSecondary)
                  : RefreshIndicator(
                      onRefresh: _loadSemesters,
                      color: _accentColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        itemCount: _semesters.length,
                        itemBuilder: (context, index) {
                          final semester = _semesters[index];
                          return _buildSemesterCard(semester, isDark,
                              textPrimary, textSecondary, cardBg);
                        },
                      ),
                    ),
    );
  }

  Widget _buildSemesterCard(int semester, bool isDark, Color textPrimary,
      Color textSecondary, Color cardBg) {
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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MockTestSubjectScreen(
                  department: _userDepartment,
                  semester: semester,
                ),
              ),
            );
          },
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
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isDark, Color textPrimary, Color textSecondary) {
    return Center(
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
          Text('Try later for this department',
              style: TextStyle(color: textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildError(bool isDark, Color textPrimary, Color textSecondary) {
    return Center(
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
