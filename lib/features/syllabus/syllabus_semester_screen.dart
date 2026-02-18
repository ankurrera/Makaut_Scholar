import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../services/auth_service.dart';
import 'syllabus_subject_screen.dart';

class SyllabusSemesterScreen extends StatefulWidget {
  final String department;
  const SyllabusSemesterScreen({super.key, required this.department});

  @override
  State<SyllabusSemesterScreen> createState() => _SyllabusSemesterScreenState();
}

class _SyllabusSemesterScreenState extends State<SyllabusSemesterScreen>
    with SingleTickerProviderStateMixin {
  List<int> _semesters = [];
  bool _isLoading = true;
  String? _error;

  /// The department fetched from the user's profile; overrides widget.department.
  late String _userDepartment;

  static const _accentLight = Color(0xFF34A875);
  static const _accentDark = Color(0xFF4FC9A8);

  Color _bg(bool d) => d ? const Color(0xFF0F1115) : const Color(0xFFF4F5F7);
  Color _card(bool d) => d ? const Color(0xFF181B22) : Colors.white;
  Color _textP(bool d) => d ? const Color(0xFFF5F6FA) : const Color(0xFF1E1E1E);
  Color _textS(bool d) => d ? const Color(0xFF9AA0A6) : const Color(0xFF8E8E93);
  Color _accent(bool d) => d ? _accentDark : _accentLight;

  static const _gradients = [
    [Color(0xFF34A875), Color(0xFF5BCC9A)], // green
    [Color(0xFF5BAAEF), Color(0xFF7BC4FF)], // blue
    [Color(0xFF8B7CF6), Color(0xFFA78BFA)], // purple
    [Color(0xFFE88AA0), Color(0xFFF5A0B4)], // rose
    [Color(0xFFF0A850), Color(0xFFFFBE6A)], // amber
    [Color(0xFF58C9B0), Color(0xFF76E4CA)], // teal
    [Color(0xFFA07EF0), Color(0xFFB898FF)], // lavender
    [Color(0xFFE87878), Color(0xFFFF9A9A)], // coral
  ];

  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _userDepartment = widget.department;
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadSemesters();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _loadSemesters() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final auth = Provider.of<AuthService>(context, listen: false);

      // Always fetch the user's profile department to ensure correctness
      final profile = await auth.getProfile();
      final profileDept = profile?['department'] as String?;
      if (profileDept != null && profileDept.isNotEmpty) {
        _userDepartment = profileDept;
      }

      final semesters = await auth.fetchSyllabusSemesters(_userDepartment);
      if (mounted) {
        setState(() { _semesters = semesters; _isLoading = false; });
        _staggerController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _accent(isDark);

    return Scaffold(
      backgroundColor: _bg(isDark),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: accent, strokeWidth: 2.5),
                  const SizedBox(height: 16),
                  Text('Loading semesters...', style: TextStyle(color: _textS(isDark), fontSize: 13)),
                ],
              ),
            )
          : _error != null
              ? _buildError(isDark, accent)
              : _semesters.isEmpty
                  ? _buildEmpty(isDark)
                  : RefreshIndicator(
                      color: accent,
                      onRefresh: _loadSemesters,
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        slivers: [
                          SliverAppBar(
                            backgroundColor: _bg(isDark),
                            elevation: 0,
                            scrolledUnderElevation: 0,
                            pinned: true,
                            expandedHeight: MediaQuery.of(context).padding.top + kToolbarHeight + 80,
                            leading: IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _card(isDark),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Iconsax.arrow_left, color: _textP(isDark), size: 18),
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            flexibleSpace: FlexibleSpaceBar(
                              background: Padding(
                                padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + kToolbarHeight + 8, 20, 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: accent.withValues(alpha: isDark ? 0.15 : 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _userDepartment,
                                        style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Syllabus',
                                      style: TextStyle(
                                        color: _textP(isDark),
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Select a semester',
                                      style: TextStyle(color: _textS(isDark), fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                            sliver: SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 1.1,
                              ),
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
                                    child: _semesterTile(_semesters[i], i, isDark),
                                  );
                                },
                                childCount: _semesters.length,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _semesterTile(int semester, int index, bool isDark) {
    final grad = _gradients[index % _gradients.length];
    return Container(
      decoration: BoxDecoration(
        color: _card(isDark),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SyllabusSubjectScreen(
                department: _userDepartment,
                semester: semester,
              ),
            ),
          ),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: grad,
                    ),
                    borderRadius: BorderRadius.circular(14),

                  ),
                  child: const Center(
                    child: Icon(Iconsax.book_1, color: Colors.white, size: 22),
                  ),
                ),
                const Spacer(),
                Text(
                  'Semester $semester',
                  style: TextStyle(
                    color: _textP(isDark),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'View syllabus',
                  style: TextStyle(color: _textS(isDark), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: _accent(isDark).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Iconsax.book_1, size: 36, color: _accent(isDark).withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 20),
          Text('No syllabus available',
              style: TextStyle(color: _textP(isDark), fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Syllabus will appear once uploaded',
              style: TextStyle(color: _textS(isDark), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildError(bool isDark, Color accent) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Iconsax.warning_2, size: 36, color: Colors.redAccent.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 20),
          Text('Something went wrong',
              style: TextStyle(color: _textP(isDark), fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _loadSemesters,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.refresh, size: 16, color: accent),
                  const SizedBox(width: 8),
                  Text('Retry', style: TextStyle(color: accent, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
