import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/monetization_service.dart';
import 'notes_viewer_screen.dart';
import '../premium/premium_checkout_screen.dart';

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
  Map<String, dynamic> _bundleInfo = {'bundle_price': 0.0, 'has_access': false};
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
      final mon = Provider.of<MonetizationService>(context, listen: false);
      
      // Fetch subjects, unit counts, and bundle info in parallel
      final results = await Future.wait([
        auth.fetchDepartmentSubjects(widget.department, widget.semester),
        auth.fetchSubjectUnitCounts(widget.department, widget.semester),
        mon.getSemesterBundleInfo(widget.department, widget.semester),
      ]);

      if (mounted) {
        setState(() { 
          _subjects = results[0] as List<String>;
          _unitCounts = results[1] as Map<String, int>;
          _bundleInfo = results[2] as Map<String, dynamic>;
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
                      child: Stack(
                        children: [
                          CustomScrollView(
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
                                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120), // Clear the frosted bar
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
                          
                          // ── Tier 3 Frosted Glass Bottom Bar ──
                          if ((_bundleInfo['bundle_price'] as double) > 0 && _bundleInfo['has_access'] == false)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: _buildFrostedBundleBar(isDark),
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

  Widget _buildFrostedBundleBar(bool isDark) {
    const Color orangeAccent = Color(0xFFFFB347);
    final double price = _bundleInfo['bundle_price'] as double;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottomPadding),
          decoration: BoxDecoration(
            color: isDark 
                ? const Color(0xFF1E1E1E).withValues(alpha: 0.7) 
                : Colors.white.withValues(alpha: 0.7),
            border: Border(
              top: BorderSide(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.08) 
                    : Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: orangeAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.star_1, color: orangeAccent, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Semester Bundle",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      "Unlock all subjects instantly",
                      style: TextStyle(
                        fontSize: 12,
                        color: _textS(isDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ScaleButton(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PremiumCheckoutScreen(
                        itemId: 'bundle_${widget.department}_${widget.semester}',
                        itemType: 'semester_bundle',
                        itemName: 'Sem ${widget.semester} Complete Bundle',
                        price: price,
                      ),
                    ),
                  ).then((result) {
                    if (result != null && result is Map && result['success'] == true) {
                       _loadSubjects(); // Reload to hide bar if purchase successful
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB347), Color(0xFFFFCC33)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: orangeAccent.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "₹${price.toStringAsFixed(0)}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Iconsax.arrow_right_3, color: Colors.white, size: 14),
                    ],
                  ),
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

class ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const ScaleButton({super.key, required this.child, required this.onTap});

  @override
  State<ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<ScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}
