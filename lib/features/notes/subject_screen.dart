import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/widgets/dot_loading.dart';
import '../../core/widgets/solid_folder.dart';
import '../../core/widgets/shimmer_skeleton.dart';
import '../../core/widgets/premium_route.dart';
import '../../services/auth_service.dart';
import '../../services/cache_service.dart';
import '../../services/monetization_service.dart';
import 'notes_viewer_screen.dart';
import '../premium/premium_checkout_screen.dart';

class SubjectScreen extends StatefulWidget {
  final String department;
  final int semester;
  const SubjectScreen(
      {super.key, required this.department, required this.semester});

  @override
  State<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends State<SubjectScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _subjects =
      []; // Changed from List<String> to support paper_code
  Map<String, int> _unitCounts = {};
  Map<String, dynamic> _bundleInfo = {'bundle_price': 0.0, 'has_access': false};
  bool _isLoading = true;
  String? _error;

  // ── Palette ──
  static const _accentLight = Color(0xFF111111);
  static const _accentDark = Colors.white;

  Color _bg(bool d) => d ? const Color(0xFF000000) : const Color(0xFFF8F6F1);
  Color _card(bool d) => d ? const Color(0xFF181B22) : Colors.white;
  Color _textP(bool d) => d ? const Color(0xFFF5F6FA) : const Color(0xFF1E1E1E);
  Color _textS(bool d) => d ? const Color(0xFF9AA0A6) : const Color(0xFF8E8E93);
  Color _accent(bool d) => d ? _accentDark : _accentLight;

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
      _error = null;
    });
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final mon = Provider.of<MonetizationService>(context, listen: false);

      // 1. Try to load from cache first
      final subjKey = 'subjects_${widget.department}_${widget.semester}';
      final countsKey = 'unit_counts_${widget.department}_${widget.semester}';
      
      final cachedSubjs = CacheService().get(subjKey);
      final cachedCounts = CacheService().get(countsKey);

      if (cachedSubjs != null && cachedSubjs is List && cachedCounts != null && cachedCounts is Map) {
        setState(() {
          _subjects = List<Map<String, dynamic>>.from(cachedSubjs);
          _unitCounts = Map<String, int>.from(cachedCounts);
          _isLoading = false;
        });
        _staggerController.forward(from: 0);
      } else {
        setState(() => _isLoading = true);
      }

      // Fetch subjects, unit counts, and bundle info in parallel
      final results = await Future.wait([
        auth.fetchDepartmentSubjects(widget.department, widget.semester),
        auth.fetchSubjectUnitCounts(widget.department, widget.semester),
        mon.getSemesterBundleInfo(widget.department, widget.semester),
      ]);

      if (mounted) {
        setState(() {
          _subjects = results[0] as List<Map<String, dynamic>>;
          _unitCounts = results[1] as Map<String, int>;
          _bundleInfo = results[2] as Map<String, dynamic>;
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
                      child: Stack(
                        children: [
                          CustomScrollView(
                            physics: const BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics()),
                            slivers: [
                              // ── Header ──
                              SliverAppBar(
                                backgroundColor: _bg(isDark),
                                elevation: 0,
                                scrolledUnderElevation: 0,
                                pinned: true,
                                expandedHeight:
                                    MediaQuery.of(context).padding.top +
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
                                              color: accent.withValues(
                                                  alpha: isDark ? 0.15 : 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Sem ${widget.semester} · ${widget.department}',
                                              style: TextStyle(
                                                  color: accent,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Subjects',
                                          textAlign: TextAlign.center,
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

                              // ── Subject cards ──
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                    20, 8, 20, 120), // Clear the frosted bar
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
                                          final v = interval.transform(
                                              _staggerController.value);
                                          return Transform.translate(
                                            offset: Offset(0, 20 * (1 - v)),
                                            child: Opacity(
                                                opacity: v, child: child),
                                          );
                                        },
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 14),
                                          child: _subjectTile(
                                              _subjects[i], i, isDark, accent),
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
                          if ((_bundleInfo['bundle_price'] as double) > 0 &&
                              _bundleInfo['has_access'] == false)
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

  Widget _subjectTile(
      Map<String, dynamic> subjectData, int index, bool isDark, Color accent) {
    final String subject = subjectData['subject'];
    final String? paperCode = subjectData['paper_code'];

    return PressableWidget(
      onTap: () => Navigator.push(
        context,
        PremiumPageRoute(
          page: NotesViewerScreen(
            department: widget.department,
            semester: widget.semester,
            subject: subject,
            paperCode: paperCode,
          ),
        ),
      ),
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
            // ── Solid Folder Icon ──
            SizedBox(
              width: 64,
              height: 52,
              child: SolidFolder(
                color: isDark ? Colors.white : const Color(0xFFF2F0EF),
                borderColor:
                    isDark ? Colors.transparent : const Color(0xFFE5E5EA),
                tabHeight: 8,
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
                        '${_unitCounts[subject] ?? 0} Units',
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
    );
  }

  Widget _buildFrostedBundleBar(bool isDark) {
    final Color brandRed = const Color(0xFFE5252A);
    final double price = _bundleInfo['bundle_price'] as double;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
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
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: brandRed.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Iconsax.star_1, color: brandRed, size: 24),
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
                   PressableWidget(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        PremiumPageRoute(
                          page: PremiumCheckoutScreen(
                            itemId:
                                'bundle_${widget.department}_${widget.semester}',
                            itemType: 'semester_bundle',
                            itemName: 'Sem ${widget.semester} Complete Bundle',
                            price: price,
                          ),
                        ),
                      );
                      if (mounted) _loadSubjects();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE5252A), Color(0xFFFF4D4D)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: brandRed.withValues(alpha: 0.3),
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
                          const Icon(Iconsax.arrow_right_3,
                              color: Colors.white, size: 14),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
            child: Icon(Iconsax.book,
                size: 36, color: _accent(isDark).withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 20),
          Text('No subjects yet',
              style: TextStyle(
                  color: _textP(isDark),
                  fontSize: 17,
                  fontWeight: FontWeight.w600)),
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
          expandedHeight: MediaQuery.of(context).padding.top + kToolbarHeight + 80,
          leading: IconButton(
            icon: const Icon(Iconsax.arrow_left),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Padding(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + kToolbarHeight + 8, 20, 0),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerSkeleton(width: 100, height: 20),
                  SizedBox(height: 10),
                  ShimmerSkeleton(width: 180, height: 28),
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
