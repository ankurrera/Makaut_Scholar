import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/cache_service.dart';
import '../../services/offline_service.dart';
import '../../core/widgets/dot_loading.dart';
import '../../core/widgets/shimmer_skeleton.dart';
import '../../core/widgets/premium_route.dart';
import '../notes/pdf_viewer_screen.dart';
import '../premium/premium_checkout_screen.dart';

class PyqPapersScreen extends StatefulWidget {
  final String department;
  final int semester;
  final String subject;
  final String? paperCode;
  const PyqPapersScreen({
    super.key,
    required this.department,
    required this.semester,
    required this.subject,
    this.paperCode,
  });

  @override
  State<PyqPapersScreen> createState() => _PyqPapersScreenState();
}

class _PyqPapersScreenState extends State<PyqPapersScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _papers = [];
  List<String> _purchasedItemIds = [];
  bool _isLoading = true;
  String? _error;

  static const _accentLight = Color(0xFF5BAAEF);
  static const _accentDark = Color(0xFF7BC4FF);

  Color _bg(bool d) => d ? const Color(0xFF000000) : const Color(0xFFF8F6F1);
  Color _card(bool d) => d ? const Color(0xFF0A0A0A) : Colors.white;
  Color _textP(bool d) => d ? const Color(0xFFF5F6FA) : const Color(0xFF1E1E1E);
  Color _textS(bool d) => d ? const Color(0xFF9AA0A6) : const Color(0xFF8E8E93);
  Color _accent(bool d) => d ? _accentDark : _accentLight;

  static const _gradients = [
    [Color(0xFF5BAAEF), Color(0xFF7BC4FF)],
    [Color(0xFF8B7CF6), Color(0xFFA78BFA)],
    [Color(0xFFF0A850), Color(0xFFFFBE6A)],
    [Color(0xFFE88AA0), Color(0xFFF5A0B4)],
    [Color(0xFF34A875), Color(0xFF5BCC9A)],
    [Color(0xFF58C9B0), Color(0xFF76E4CA)],
    [Color(0xFFA07EF0), Color(0xFFB898FF)],
    [Color(0xFFE87878), Color(0xFFFF9A9A)],
  ];

  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadPapers();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _loadPapers() async {
    setState(() {
      _error = null;
    });
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      
      // 1. Check cache first
      final cacheKey = 'pyq_papers_${widget.department}_${widget.semester}_${widget.subject}';
      final cachedData = CacheService().get(cacheKey);
      if (cachedData != null && cachedData is List) {
        setState(() {
          _papers = List<Map<String, dynamic>>.from(cachedData);
          _isLoading = false;
        });
        _staggerController.forward(from: 0);
      } else {
        setState(() => _isLoading = true);
      }
      final results = await Future.wait([
        auth.fetchPyqPapers(widget.department, widget.semester, widget.subject,
            paperCode: widget.paperCode),
        auth.fetchUserPurchases('pyq'),
      ]);

      if (mounted) {
        setState(() {
          _papers = results[0] as List<Map<String, dynamic>>;
          _purchasedItemIds = results[1] as List<String>;
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

  void _openPdf({String? url, String? filePath, required String title}) {
    Navigator.push(
      context,
      PremiumPageRoute(
        page: PdfViewerScreen(url: url, filePath: filePath, title: title),
      ),
    );
  }

  void _openCheckout(Map<String, dynamic> paper) async {
    final result = await Navigator.push(
      context,
      PremiumPageRoute(
        page: PremiumCheckoutScreen(
          itemId: paper['id'].toString(),
          itemType: 'pyq',
          itemName: '${widget.subject} – ${paper['year']}',
          itemUrl: paper['file_url'],
          price: (paper['price'] as num?)?.toDouble() ?? 0.0,
        ),
      ),
    );

    // ALWAYS reload to update locked/unlocked state, regardless of outcome.
    if (mounted) {
      _loadPapers();
      if (result is Map && result['success'] == true) {
        final String? itemUrl = result['itemUrl'] as String?;
        final String itemName = result['itemName'] as String? ?? 'PYQ Paper';
        if (itemUrl != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Content unlocked! ✨'),
              backgroundColor: Color(0xFF5BAAEF),
              duration: Duration(seconds: 2),
            ),
          );
          _openPdf(url: itemUrl, title: itemName);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _accent(isDark);

    return Scaffold(
      backgroundColor: _bg(isDark),
      body: _isLoading && _papers.isEmpty
          ? _buildLoadingSkeleton(isDark)
          : _error != null
              ? _buildError(isDark, accent)
              : _papers.isEmpty
                  ? _buildEmpty(isDark)
                  : RefreshIndicator(
                      color: accent,
                      onRefresh: _loadPapers,
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
                                90,
                            leading: IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _card(isDark),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF2C2C2E)
                                        : const Color(0xFFE6E8EC),
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
                                          color: accent.withValues(
                                              alpha: isDark ? 0.15 : 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Sem ${widget.semester} · ${widget.department}',
                                          style: TextStyle(
                                              color: accent,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              overflow: TextOverflow.ellipsis,
                                              fontFamily: 'NDOT'),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      widget.subject,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _textP(isDark),
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.5,
                                        fontFamily: 'NDOT',
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_papers.length} paper${_papers.length != 1 ? 's' : ''} available',
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
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
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
                                      final v = interval
                                          .transform(_staggerController.value);
                                      return Transform.translate(
                                        offset: Offset(0, 20 * (1 - v)),
                                        child:
                                            Opacity(opacity: v, child: child),
                                      );
                                    },
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 14),
                                      child: _paperTile(_papers[i], i, isDark),
                                    ),
                                  );
                                },
                                childCount: _papers.length,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _paperTile(Map<String, dynamic> paper, int index, bool isDark) {
    final grad = _gradients[index % _gradients.length];
    final year = paper['year'] as String;
    final fileUrl = paper['file_url'] as String;
    final id = paper['id'].toString();
    final isDownloaded = OfflineService().isDownloaded(id);
    final title = '${widget.subject} – $year';
    final bool isPremium = paper['is_premium'] ?? false;
    final bool isPurchased = _purchasedItemIds.contains(id);
    final bool isLocked = isPremium && !isPurchased;

    return PressableWidget(
      onTap: () {
        if (isLocked) {
          _openCheckout(paper);
          return;
        }
        if (isDownloaded) {
          final resource = OfflineService().getResource(id);
          _openPdf(filePath: resource!.localPath, title: title);
        } else {
          _openPdf(url: fileUrl, title: title);
        }
      },
      child: CustomPaint(
        painter: isLocked ? _DottedBorderPainter(color: (isDark ? Colors.white : Colors.black).withOpacity(0.2)) : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: _card(isDark),
                  border: isLocked ? null : Border.all(
                    color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F2),
                    width: 1.0,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Year badge
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isLocked
                            ? (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04))
                            : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F2)),
                        borderRadius: BorderRadius.circular(16),
                        border: isLocked ? Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1), width: 0.5) : null,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(isLocked ? Iconsax.lock_1_copy : Iconsax.document_text_1,
                              color: isDark ? Colors.white : Colors.black,
                              size: 22),
                          if (isLocked)
                            Positioned(
                              bottom: 4,
                              child: Text(
                                'PRO',
                                style: TextStyle(
                                  fontFamily: 'NDOT',
                                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.4),
                                  fontSize: 6,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.department} • SEM ${widget.semester}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'NDOT',
                              color: (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                year,
                                style: TextStyle(
                                  color: isLocked 
                                      ? _textP(isDark).withOpacity(0.5)
                                      : _textP(isDark),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Iconsax.archive_book,
                                  size: 12,
                                  color: isDownloaded
                                      ? Colors.green
                                      : _textS(isDark)),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  isLocked 
                                      ? 'SPEC: PYQ-ARCHIVE // VAL: PREMIUM'
                                      : (isDownloaded
                                          ? 'Offline Access Enabled'
                                          : widget.subject),
                                  style: TextStyle(
                                      fontFamily: isLocked ? 'NDOT' : null,
                                      color: isDownloaded
                                          ? Colors.green
                                          : (isLocked ? const Color(0xFFE5252A) : _textS(isDark)),
                                      fontSize: isLocked ? 9 : 11,
                                      letterSpacing: isLocked ? 0.5 : null,
                                      fontWeight: isLocked ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Download Toggle
                    IconButton(
                      icon: isLocked
                          ? Icon(Iconsax.lock,
                              color: (isDark ? Colors.white : Colors.black).withOpacity(0.4), size: 20)
                          : (isDownloaded
                              ? const Icon(Iconsax.tick_circle,
                                  color: Colors.green, size: 20)
                              : Image.asset(
                                  'assets/icons/down_to_line.png',
                                  width: 20,
                                  height: 20,
                                  color: isDark ? Colors.white : Colors.black,
                                )),
                      onPressed: isLocked
                          ? () => _openCheckout(paper)
                          : (isDownloaded
                              ? null
                              : () async {
                                  try {
                                    await OfflineService().downloadResource(
                                      id: id,
                                      title: title,
                                      url: fileUrl,
                                      category: ResourceCategory.PYQ,
                                    );
                                    if (mounted) setState(() {});
                                  } catch (e) {
                                    if (mounted)
                                      ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(e.toString())));
                                  }
                                }),
                    ),
                  ],
                ),
              ),
              if (isLocked)
                Positioned.fill(
                  child: IgnorePointer(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                      child: Container(
                        color: (isDark ? Colors.black : Colors.white).withOpacity(0.05),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
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
          expandedHeight: MediaQuery.of(context).padding.top + kToolbarHeight + 90,
          leading: IconButton(
            icon: const Icon(Iconsax.arrow_left),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Padding(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + kToolbarHeight + 8, 20, 0),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(child: ShimmerSkeleton(width: 100, height: 20)),
                  SizedBox(height: 10),
                  ShimmerSkeleton(width: 200, height: 28, isNdot: true),
                  SizedBox(height: 8),
                  ShimmerSkeleton(width: 140, height: 14),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
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
          Text('No papers yet',
              style: TextStyle(
                  color: _textP(isDark),
                  fontSize: 17,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('PYQ papers will appear once uploaded',
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
          Text('Failed to load papers',
              style: TextStyle(
                  color: _textP(isDark),
                  fontSize: 17,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _loadPapers,
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
}

class _DottedBorderPainter extends CustomPainter {
  final Color color;
  _DottedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(20),
      ));

    final dashPath = _dashPath(path, 4, 4);
    canvas.drawPath(dashPath, paint);
  }

  Path _dashPath(Path source, double dashWidth, double dashSpace) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final len = draw ? dashWidth : dashSpace;
        if (draw) {
          dest.addPath(metric.extractPath(distance, distance + len), Offset.zero);
        }
        distance += len;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
