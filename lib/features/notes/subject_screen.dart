import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../services/auth_service.dart';
import 'notes_viewer_screen.dart';

class SubjectScreen extends StatefulWidget {
  final String department;
  final int semester;
  const SubjectScreen({super.key, required this.department, required this.semester});

  @override
  State<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends State<SubjectScreen> with TickerProviderStateMixin {
  List<String> _subjects = [];
  Map<String, int> _unitCounts = {};
  bool _isLoading = true;
  String? _error;

  // ── Palette ──
  static const _accentLight = Color(0xFF7C6FF6);
  static const _accentDark = Color(0xFF8E82FF);

  Color _bg(bool d) => d ? const Color(0xFF0F1115) : const Color(0xFFF4F5F7);
  Color _card(bool d) => d ? const Color(0xFF181B22) : Colors.white;
  Color _textP(bool d) => d ? const Color(0xFFF5F6FA) : const Color(0xFF1E1E1E);
  Color _textS(bool d) => d ? const Color(0xFF9AA0A6) : const Color(0xFF8E8E93);
  Color _accent(bool d) => d ? _accentDark : _accentLight;

  // Gradient pairs per subject — vibrant in both modes
  static const _gradients = [
    [Color(0xFF8B7CF6), Color(0xFFA78BFA)], // purple
    [Color(0xFF5BAAEF), Color(0xFF7BC4FF)], // blue
    [Color(0xFF4FC9A8), Color(0xFF6DE8C8)], // mint
    [Color(0xFFE88AA0), Color(0xFFF5A0B4)], // rose
    [Color(0xFFF0A850), Color(0xFFFFBE6A)], // amber
    [Color(0xFF58C9B0), Color(0xFF76E4CA)], // teal
    [Color(0xFFA07EF0), Color(0xFFB898FF)], // lavender
    [Color(0xFFE87878), Color(0xFFFF9A9A)], // coral
    [Color(0xFF6CB4F0), Color(0xFF90CCFF)], // sky
    [Color(0xFF8DD4A8), Color(0xFFA8ECC0)], // sage
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
    setState(() { _isLoading = true; _error = null; });
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      
      // Fetch subjects and unit counts in parallel
      final results = await Future.wait([
        auth.fetchDepartmentSubjects(widget.department, widget.semester),
        auth.fetchSubjectUnitCounts(widget.department, widget.semester),
      ]);

      if (mounted) {
        setState(() { 
          _subjects = results[0] as List<String>;
          _unitCounts = results[1] as Map<String, int>;
          _isLoading = false; 
        });
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
                  Text('Loading subjects...', style: TextStyle(color: _textS(isDark), fontSize: 13)),
                ],
              ),
            )
          : _error != null
              ? _buildError(isDark, accent)
              : _subjects.isEmpty
                  ? _buildEmpty(isDark)
                  : RefreshIndicator(
                      color: accent,
                      onRefresh: _loadSubjects,
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        slivers: [
                          // ── Header ──
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
                                        'Sem ${widget.semester} · ${widget.department}',
                                        style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Subjects',
                                      style: TextStyle(
                                        color: _textP(isDark),
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_subjects.length} subject${_subjects.length != 1 ? 's' : ''} available',
                                      style: TextStyle(color: _textS(isDark), fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // ── Subject cards ──
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, i) {
                                  final interval = Interval(
                                    (i * 0.08).clamp(0.0, 0.5),
                                    ((i * 0.08) + 0.5).clamp(0.0, 1.0),
                                    curve: Curves.easeOutCubic,
                                  );
                                  return AnimatedBuilder(
                                    animation: _staggerController,
                                    builder: (context, child) {
                                      final v = interval.transform(_staggerController.value);
                                      return Transform.translate(
                                        offset: Offset(0, 20 * (1 - v)),
                                        child: Opacity(opacity: v, child: child),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 14),
                                      child: _subjectTile(_subjects[i], i, isDark, accent),
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

  Widget _subjectTile(String subject, int index, bool isDark, Color accent) {
    final grad = _gradients[index % _gradients.length];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NotesViewerScreen(
              department: widget.department,
              semester: widget.semester,
              subject: subject,
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: _card(isDark),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // ── Gradient icon container ──
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: grad,
                    ),
                    borderRadius: BorderRadius.circular(16),

                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // ── Subject text ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject,
                        style: TextStyle(
                          color: _textP(isDark),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: grad[0],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_unitCounts[subject] ?? 0} Units',
                            style: TextStyle(color: _textS(isDark), fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Arrow ──
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark
                        ? grad[0].withValues(alpha: 0.12)
                        : grad[0].withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Iconsax.arrow_right_3,
                    color: grad[0],
                    size: 16,
                  ),
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
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _accent(isDark).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Iconsax.book, size: 36, color: _accent(isDark).withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 20),
          Text('No subjects yet',
              style: TextStyle(color: _textP(isDark), fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Notes will appear once uploaded',
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
            child: Icon(Iconsax.warning_2, size: 36, color: Colors.redAccent.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 20),
          Text('Failed to load subjects',
              style: TextStyle(color: _textP(isDark), fontSize: 17, fontWeight: FontWeight.w600)),
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
