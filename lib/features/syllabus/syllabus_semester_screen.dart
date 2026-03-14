import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../services/auth_service.dart';
import '../../core/widgets/dot_loading.dart';
import '../../core/widgets/solid_folder.dart';
import '../../core/widgets/shimmer_skeleton.dart';
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

  static const _accentLight = Color(0xFFFF3B30); // iOS Red
  static const _accentDark = Color(0xFFFF453A); // iOS Dark Red

  Color _bg(bool d) => d ? Colors.black : const Color(0xFFF8F6F1);
  Color _card(bool d) => d ? const Color(0xFF1C1C1E) : Colors.white;
  Color _textP(bool d) => d ? const Color(0xFFF5F6FA) : const Color(0xFF1E1E1E);
  Color _textS(bool d) => d ? const Color(0xFF9AA0A6) : const Color(0xFF8E8E93);
  Color _accent(bool d) => d ? _accentDark : _accentLight;

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
    setState(() {
      _isLoading = true;
      _error = null;
    });
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
        setState(() {
          _semesters = semesters;
          _isLoading = false;
        });
        _staggerController.forward(from: 0);
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _accent(isDark);

    return Scaffold(
      backgroundColor: _bg(isDark),
      body: _isLoading && _semesters.isEmpty
          ? _buildLoadingSkeleton(isDark)
          : _error != null
              ? _buildError(isDark, accent)
              : _semesters.isEmpty
                  ? _buildEmpty(isDark)
                  : RefreshIndicator(
                      color: accent,
                      onRefresh: _loadSemesters,
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics()),
                        slivers: [
                          SliverAppBar(
                            backgroundColor: _bg(isDark),
                            elevation: 0,
                            scrolledUnderElevation: 0,
                            pinned: true,
                            expandedHeight: MediaQuery.of(context).padding.top +
                                kToolbarHeight +
                                80,
                            leading: IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _card(isDark),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF2C2C2E)
                                        : const Color(0xFFF2F2F2),
                                  ),
                                ),
                                child: Icon(Iconsax.arrow_left,
                                    color: _textP(isDark), size: 18),
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            flexibleSpace: FlexibleSpaceBar(
                              background: Padding(
                                padding: EdgeInsets.fromLTRB(
                                    20,
                                    MediaQuery.of(context).padding.top +
                                        kToolbarHeight +
                                        8,
                                    20,
                                    0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF2C2C2E)
                                              : const Color(0xFFE6E8EC),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _userDepartment,
                                          style: TextStyle(
                                              color: _textS(isDark),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Syllabus',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _textP(isDark),
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.5,
                                        fontFamily: 'NDOT',
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Course outline & topics by semester',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: _textS(isDark), fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                            sliver: SliverList.builder(
                              itemCount: _semesters.length,
                              itemBuilder: (context, i) {
                                final interval = Interval(
                                  (i * 0.1).clamp(0.0, 0.5),
                                  ((i * 0.1) + 0.5).clamp(0.0, 1.0),
                                  curve: Curves.easeOutCubic,
                                );
                                return AnimatedBuilder(
                                  animation: _staggerController,
                                  builder: (context, child) {
                                    final v = interval
                                        .transform(_staggerController.value);
                                    return Transform.translate(
                                      offset: Offset(0, 24 * (1 - v)),
                                      child: Opacity(opacity: v, child: child),
                                    );
                                  },
                                  child:
                                      _semesterTile(_semesters[i], i, isDark),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _semesterTile(int semester, int index, bool isDark) {
    final tileBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final tileBorder =
        isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F2);
    final textPrimary = isDark ? Colors.white : const Color(0xFF111111);
    final textSecondary =
        isDark ? const Color(0xFF8E8E93) : const Color(0xFF888888);

    // Arrow colors matching 1st pic but in Red theme
    final arrowBg = isDark ? const Color(0xFF3A2A2A) : const Color(0xFFFFE5E5);
    final arrowColor =
        isDark ? const Color(0xFFFF6961) : const Color(0xFFFF3B30);

    // Folder icon colors - Proper white for dark mode, off-white for light mode
    final folderClr = isDark ? Colors.white : const Color(0xFFF2F0EF);
    final folderBorder = isDark ? Colors.transparent : const Color(0xFFE5E5EA);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SyllabusSubjectScreen(
              department: _userDepartment,
              semester: semester,
            ),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: tileBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tileBorder, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                height: 52,
                child: SolidFolder(
                  color: folderClr,
                  borderColor: folderBorder,
                  tabHeight: 10,
                ),
              ),
              const SizedBox(width: 20),
              // 2. Texts
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Semester $semester',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _accent(isDark).withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Iconsax.book_1,
                size: 36, color: _accent(isDark).withOpacity(0.4)),
          ),
          const SizedBox(height: 20),
          Text('No syllabus available',
              style: TextStyle(
                  color: _textP(isDark),
                  fontSize: 17,
                  fontWeight: FontWeight.w600)),
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
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Iconsax.warning_2,
                size: 36, color: Colors.redAccent.withOpacity(0.5)),
          ),
          const SizedBox(height: 20),
          Text('Something went wrong',
              style: TextStyle(
                  color: _textP(isDark),
                  fontSize: 17,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _loadSemesters,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: accent.withOpacity(isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.refresh, size: 16, color: accent),
                  const SizedBox(width: 8),
                  Text('Retry',
                      style: TextStyle(
                          color: accent,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton(bool isDark) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: _bg(isDark),
          elevation: 0,
          pinned: true,
          expandedHeight:
              MediaQuery.of(context).padding.top + kToolbarHeight + 80,
          leading: IconButton(
            icon: const Icon(Iconsax.arrow_left),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Padding(
              padding: EdgeInsets.fromLTRB(
                  20, MediaQuery.of(context).padding.top + kToolbarHeight + 8, 20, 0),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(child: ShimmerSkeleton(width: 120, height: 20)),
                  SizedBox(height: 10),
                  ShimmerSkeleton(width: 180, height: 28, isNdot: true),
                  SizedBox(height: 8),
                  ShimmerSkeleton(width: 220, height: 14),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
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
