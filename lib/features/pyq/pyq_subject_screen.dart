import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../services/auth_service.dart';
import '../../core/widgets/dot_loading.dart';
import '../../core/widgets/shimmer_skeleton.dart';
import 'pyq_papers_screen.dart';
import '../../core/widgets/solid_folder.dart';

class PyqSubjectScreen extends StatefulWidget {
  final String department;
  final int semester;
  const PyqSubjectScreen(
      {super.key, required this.department, required this.semester});

  @override
  State<PyqSubjectScreen> createState() => _PyqSubjectScreenState();
}

class _PyqSubjectScreenState extends State<PyqSubjectScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _subjects =
      []; // Changed from List<String> to support paper_code
  Map<String, int> _paperCounts = {};
  bool _isLoading = true;
  String? _error;

  static const _accentLight = Color(0xFF5BAAEF);
  static const _accentDark = Color(0xFF7BC4FF);

  Color _bg(bool d) => d ? Colors.black : const Color(0xFFF8F6F1);
  Color _card(bool d) => d ? const Color(0xFF1C1C1E) : Colors.white;
  Color _textP(bool d) => d ? const Color(0xFFF5F6FA) : const Color(0xFF1E1E1E);
  Color _textS(bool d) => d ? const Color(0xFF9AA0A6) : const Color(0xFF8E8E93);
  Color _accent(bool d) => d ? _accentDark : _accentLight;

  static const _gradients = [
    [Color(0xFF5BAAEF), Color(0xFF7BC4FF)],
    [Color(0xFF8B7CF6), Color(0xFFA78BFA)],
    [Color(0xFFE88AA0), Color(0xFFF5A0B4)],
    [Color(0xFFF0A850), Color(0xFFFFBE6A)],
    [Color(0xFF34A875), Color(0xFF5BCC9A)],
    [Color(0xFF58C9B0), Color(0xFF76E4CA)],
    [Color(0xFFA07EF0), Color(0xFFB898FF)],
    [Color(0xFFE87878), Color(0xFFFF9A9A)],
    [Color(0xFF6CB4F0), Color(0xFF90CCFF)],
    [Color(0xFF8DD4A8), Color(0xFFA8ECC0)],
  ];

  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadSubjects();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final auth = Provider.of<AuthService>(context, listen: false);

      // Fetch subjects and paper counts in parallel
      final results = await Future.wait([
        auth.fetchDepartmentSubjects(widget.department, widget.semester),
        auth.fetchSubjectPyqCounts(widget.department, widget.semester),
      ]);

      if (mounted) {
        setState(() {
          _subjects = results[0] as List<Map<String, dynamic>>;
          _paperCounts = results[1] as Map<String, int>;
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
      body: _isLoading && _subjects.isEmpty
          ? _buildLoadingSkeleton(isDark)
          : _error != null
              ? _buildError(isDark, accent)
              : _subjects.isEmpty
                  ? _buildEmpty(isDark)
                  : RefreshIndicator(
                      color: accent,
                      onRefresh: _loadSubjects,
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                  children: [
                                    Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: accent.withOpacity(
                                              isDark ? 0.15 : 0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Sem ${widget.semester} · ${widget.department}',
                                          style: TextStyle(
                                              color: accent,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'NDOT'),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'PYQ Subjects',
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
                                      '${_subjects.length} subject${_subjects.length != 1 ? 's' : ''} available',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: _textS(isDark),
                                          fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
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
                                      final v = interval
                                          .transform(_staggerController.value);
                                      return Transform.translate(
                                        offset: Offset(0, 24 * (1 - v)),
                                        child:
                                            Opacity(opacity: v, child: child),
                                      );
                                    },
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12.0),
                                      child:
                                          _subjectTile(_subjects[i], i, isDark),
                                    ),
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
    final grad = _gradients[index % _gradients.length];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PyqPapersScreen(
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
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE6E8EC),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                height: 52,
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
                        color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Iconsax.archive_book,
                            size: 10,
                            color: isDark
                                ? const Color(0xFF9AA0A6)
                                : const Color(0xFF8E8E93)),
                        const SizedBox(width: 4),
                        Text(
                          '${_paperCounts[subject] ?? 0} Papers',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? const Color(0xFF9AA0A6)
                                : const Color(0xFF8E8E93),
                          ),
                        ),
                      ],
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
              color: _accent(isDark).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Iconsax.archive_book,
                size: 36, color: _accent(isDark).withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 20),
          Text('No subjects yet',
              style: TextStyle(
                  color: _textP(isDark),
                  fontSize: 17,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('PYQs will appear once uploaded',
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
              color: Colors.redAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Iconsax.warning_2,
                size: 36, color: Colors.redAccent.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 20),
          Text('Failed to load subjects',
              style: TextStyle(
                  color: _textP(isDark),
                  fontSize: 17,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _loadSubjects,
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
                  ShimmerSkeleton(width: 140, height: 14),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
