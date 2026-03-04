import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../services/auth_service.dart';
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

  static const _accentColor = Color(0xFF8E82FF);

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
          'Mock Tests',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _accentColor))
          : _error != null
              ? _buildError(isDark, textPrimary, textSecondary)
              : _semesters.isEmpty
                  ? _buildEmpty(isDark, textPrimary, textSecondary)
                  : RefreshIndicator(
                      onRefresh: _loadSemesters,
                      color: _accentColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: _semesters.length,
                        itemBuilder: (context, index) {
                          final semester = _semesters[index];
                          return _buildSemesterCard(semester, isDark, textPrimary, textSecondary, cardBg);
                        },
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
      ),
    );
  }

  Widget _buildEmpty(bool isDark, Color textPrimary, Color textSecondary) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.document_filter, size: 64, color: textSecondary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('No quizzes available', style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Try later for this department', style: TextStyle(color: textSecondary)),
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
          Text('Failed to load quizzes', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextButton(onPressed: _loadSemesters, child: const Text('Retry', style: TextStyle(color: _accentColor))),
        ],
      ),
    );
  }
}
