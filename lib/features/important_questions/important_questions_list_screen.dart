import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../services/offline_service.dart';
import '../../services/auth_service.dart';
import '../../services/cache_service.dart';
import '../../core/widgets/dot_loading.dart';
import '../../core/widgets/shimmer_skeleton.dart';
import '../../core/widgets/premium_route.dart';
import '../notes/pdf_viewer_screen.dart';
import '../premium/premium_checkout_screen.dart';

class ImportantQuestionsListScreen extends StatefulWidget {
  final String department;
  final int semester;
  final String subject;
  final String? paperCode;
  const ImportantQuestionsListScreen({
    super.key,
    required this.department,
    required this.semester,
    required this.subject,
    this.paperCode,
  });

  @override
  State<ImportantQuestionsListScreen> createState() =>
      _ImportantQuestionsListScreenState();
}

class _ImportantQuestionsListScreenState
    extends State<ImportantQuestionsListScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _questions = [];
  List<String> _purchasedItemIds = [];
  bool _isLoading = true;
  String? _error;
  late AnimationController _staggerController;

  final List<List<Color>> _gradients = [
    [const Color(0xFFFF708D), const Color(0xFFFF4D6D)],
    [const Color(0xFF8B7CF6), Color(0xFFA78BFA)],
    [const Color(0xFF5BAAEF), Color(0xFF7BC4FF)],
    [const Color(0xFF34A875), Color(0xFF5BCC9A)],
    [const Color(0xFFF0A850), Color(0xFFFFBE6A)],
    [const Color(0xFFE88AA0), Color(0xFFF5A0B4)],
    [const Color(0xFF58C9B0), Color(0xFF76E4CA)],
    [const Color(0xFFA07EF0), Color(0xFFB898FF)],
    [const Color(0xFFE87878), Color(0xFFFF9A9A)],
  ];

  Color _bg(bool d) => d ? const Color(0xFF000000) : const Color(0xFFF8F6F1);

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadQuestions();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _error = null;
    });
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      
      // 1. Check cache first
      final cacheKey = 'imp_questions_${widget.department}_${widget.semester}_${widget.subject}';
      final cachedData = CacheService().get(cacheKey);
      if (cachedData != null && cachedData is List) {
        setState(() {
          _questions = List<Map<String, dynamic>>.from(cachedData);
          _isLoading = false;
        });
        _staggerController.forward(from: 0);
      } else {
        setState(() => _isLoading = true);
      }
      final results = await Future.wait([
        auth.fetchImpQuestions(
            widget.department, widget.semester, widget.subject,
            paperCode: widget.paperCode),
        auth.fetchUserPurchases('important_questions'),
      ]);

      if (mounted) {
        setState(() {
          _questions = results[0] as List<Map<String, dynamic>>;
          _purchasedItemIds = results[1] as List<String>;
          _isLoading = false;
        });
        _staggerController.forward(from: 0);
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

  void _openPdf(String url, String title) {
    Navigator.push(
      context,
      PremiumPageRoute(page: PdfViewerScreen(url: url, title: title)),
    );
  }

  void _openCheckout(Map<String, dynamic> item) async {
    final result = await Navigator.push(
      context,
      PremiumPageRoute(
        page: PremiumCheckoutScreen(
          itemId: item['id'].toString(),
          itemType: 'important_questions',
          itemName: item['title'] ?? 'Important Questions',
          itemUrl: item['file_url'],
          price: (item['price'] as num?)?.toDouble() ?? 0.0,
        ),
      ),
    );

    // ALWAYS reload to update locked/unlocked state, regardless of outcome.
    if (mounted) {
      _loadQuestions();
      if (result is Map && result['success'] == true) {
        final String? itemUrl = result['itemUrl'] as String?;
        final String itemName = result['itemName'] as String? ?? 'Important Questions';
        if (itemUrl != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Content unlocked! ✨'),
              backgroundColor: Color(0xFFE5252A),
              duration: Duration(seconds: 2),
            ),
          );
          _openPdf(itemUrl, itemName);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFFFF708D) : const Color(0xFFFF4D6D);

    return Scaffold(
      backgroundColor: _bg(isDark),
      body: _isLoading && _questions.isEmpty
          ? _buildLoadingSkeleton(isDark)
          : _error != null
              ? Center(
                  child: Text('Error: $_error',
                      style: const TextStyle(color: Colors.red)))
              : _questions.isEmpty
                  ? _buildEmpty(isDark, accent)
                  : RefreshIndicator(
                      onRefresh: _loadQuestions,
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics()),
                        slivers: [
                          SliverAppBar(
                            backgroundColor: _bg(isDark),
                            elevation: 0,
                            pinned: true,
                            expandedHeight: 180,
                            leading: IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1C1C1E)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF2C2C2E)
                                          : const Color(0xFFE6E8EC)),
                                ),
                                child: Icon(Iconsax.arrow_left,
                                    color: isDark ? Colors.white : Colors.black,
                                    size: 18),
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            flexibleSpace: FlexibleSpaceBar(
                              background: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 100, 20, 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      widget.subject,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1E1E1E),
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                        fontFamily: 'NDOT',
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_questions.length} targeting sets available',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isDark
                                            ? const Color(0xFF9AA0A6)
                                            : const Color(0xFF8E8E93),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
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
                                        offset: Offset(0, 20 * (1 - v)),
                                        child:
                                            Opacity(opacity: v, child: child),
                                      );
                                    },
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: _questionTile(
                                          _questions[i], i, isDark),
                                    ),
                                  );
                                },
                                childCount: _questions.length,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _questionTile(Map<String, dynamic> item, int index, bool isDark) {
    final grad = _gradients[index % _gradients.length];
    final title = item['title'] as String;
    final fileUrl = item['file_url'] as String;
    final id = item['id'].toString();
    final isDownloaded = OfflineService().isDownloaded(id);
    final bool isPremium = item['is_premium'] ?? false;
    final bool isPurchased = _purchasedItemIds.contains(id);
    final bool isLocked = isPremium && !isPurchased;
    return PressableWidget(
      onTap: () {
        if (isLocked) {
          _openCheckout(item);
          return;
        }
        if (isDownloaded) {
          final resource = OfflineService().getResource(id);
          Navigator.push(
            context,
            PremiumPageRoute(
              page: PdfViewerScreen(
                filePath: resource!.localPath,
                title: title,
              ),
            ),
          );
        } else {
          _openPdf(fileUrl, title);
        }
      },
      child: CustomPaint(
        painter: isLocked ? _DottedBorderPainter(color: (isDark ? Colors.white : Colors.black).withOpacity(0.2)) : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: _bg(isDark),
                  border: isLocked ? null : Border.all(
                    color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE6E8EC),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isLocked
                            ? (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04))
                            : grad[0].withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: isLocked ? Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1), width: 0.5) : null,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                              isLocked ? Iconsax.lock_1 : Iconsax.document_text_1,
                              color: isLocked ? (isDark ? Colors.white : Colors.black).withOpacity(0.7) : grad[0],
                              size: 20),
                          if (isLocked)
                            Positioned(
                              bottom: 2,
                              child: Text(
                                'PRO',
                                style: TextStyle(
                                  fontFamily: 'NDOT',
                                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.4),
                                  fontSize: 5,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: isLocked 
                                  ? (isDark ? Colors.white : const Color(0xFF1E1E1E)).withOpacity(0.5)
                                  : (isDark ? Colors.white : const Color(0xFF1E1E1E)),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isLocked 
                                ? 'SPEC: Q-FILE // VAL: PREMIUM'
                                : 'PDF Document · ${DateTime.now().year}',
                            style: TextStyle(
                              fontFamily: isLocked ? 'NDOT' : null,
                              color: isLocked
                                  ? const Color(0xFFE5252A)
                                  : (isDark
                                      ? const Color(0xFF9AA0A6)
                                      : const Color(0xFF8E8E93)),
                              fontSize: isLocked ? 9 : 12,
                              fontWeight: isLocked ? FontWeight.w600 : FontWeight.normal,
                              letterSpacing: isLocked ? 0.5 : null,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                          ? () => _openCheckout(item)
                          : (isDownloaded
                              ? null
                              : () async {
                                  try {
                                    await OfflineService().downloadResource(
                                      id: id,
                                      title: title,
                                      url: fileUrl,
                                      category: ResourceCategory.EXAM_FOCUS,
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
          expandedHeight: 180,
          leading: IconButton(
            icon: const Icon(Iconsax.arrow_left),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: const FlexibleSpaceBar(
            background: Padding(
              padding: EdgeInsets.fromLTRB(20, 100, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(child: ShimmerSkeleton(width: 200, height: 24, isNdot: true)),
                  SizedBox(height: 8),
                  ShimmerSkeleton(width: 150, height: 14),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
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

  Widget _buildEmpty(bool isDark, Color accent) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.flash, size: 48, color: accent.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'No focus sets found',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1E1E1E),
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ready your focus for the exams!',
            style: TextStyle(
              color: isDark ? const Color(0xFF9AA0A6) : const Color(0xFF8E8E93),
              fontSize: 14,
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
        const Radius.circular(16),
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
