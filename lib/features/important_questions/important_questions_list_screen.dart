import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../services/offline_service.dart';
import '../../services/auth_service.dart';
import '../notes/pdf_viewer_screen.dart';
import '../premium/premium_checkout_screen.dart';

class ImportantQuestionsListScreen extends StatefulWidget {
  final String department;
  final int semester;
  final String subject;

  const ImportantQuestionsListScreen({
    super.key,
    required this.department,
    required this.semester,
    required this.subject,
  });

  @override
  State<ImportantQuestionsListScreen> createState() => _ImportantQuestionsListScreenState();
}

class _ImportantQuestionsListScreenState extends State<ImportantQuestionsListScreen>
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
  ];

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
    setState(() { _isLoading = true; _error = null; });
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final results = await Future.wait([
        auth.fetchImpQuestions(widget.department, widget.semester, widget.subject),
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
      MaterialPageRoute(builder: (_) => PdfViewerScreen(url: url, title: title)),
    );
  }

  void _openCheckout(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PremiumCheckoutScreen(
          itemId: item['id'].toString(),
          itemType: 'important_questions',
          itemName: item['title'] ?? 'Important Questions',
          itemUrl: item['file_url'],
          price: (item['price'] as num?)?.toDouble() ?? 0.0,
        ),
      ),
    ).then((result) {
      if (result != null && result is Map && result['success'] == true) {
        final String? itemUrl = result['itemUrl'];
        final String itemName = result['itemName'] ?? 'Important Questions';
        if (itemUrl != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unlock Successful! ✨ Preparing your content...'),
              backgroundColor: Color(0xFF8E82FF),
              duration: Duration(seconds: 2),
            ),
          );
          _openPdf(itemUrl, itemName);
        }
        _loadQuestions();
      } else {
        _loadQuestions();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFFFF708D) : const Color(0xFFFF4D6D);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1115) : const Color(0xFFF4F5F7),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
              : _questions.isEmpty
                  ? _buildEmpty(isDark, accent)
                  : RefreshIndicator(
                      onRefresh: _loadQuestions,
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        slivers: [
                          SliverAppBar(
                            backgroundColor: isDark ? const Color(0xFF0F1115) : const Color(0xFFF4F5F7),
                            elevation: 0,
                            pinned: true,
                            expandedHeight: 180,
                            leading: IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF171A21) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isDark ? const Color(0xFF2A2F3A) : const Color(0xFFE6E8EC)),
                                ),
                                child: Icon(Iconsax.arrow_left, color: isDark ? Colors.white : Colors.black, size: 18),
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            flexibleSpace: FlexibleSpaceBar(
                              background: Padding(
                                padding: const EdgeInsets.fromLTRB(20, 100, 20, 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.subject,
                                      style: TextStyle(
                                        color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_questions.length} targeting sets available',
                                      style: TextStyle(
                                        color: isDark ? const Color(0xFF9AA0A6) : const Color(0xFF8E8E93),
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
                                      final v = interval.transform(_staggerController.value);
                                      return Transform.translate(
                                        offset: Offset(0, 20 * (1 - v)),
                                        child: Opacity(opacity: v, child: child),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _questionTile(_questions[i], i, isDark),
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isLocked) {
            _openCheckout(item);
            return;
          }
          if (isDownloaded) {
            final resource = OfflineService().getResource(id);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PdfViewerScreen(
                  filePath: resource!.localPath,
                  title: title,
                ),
              ),
            );
          } else {
            _openPdf(fileUrl, title);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 44,
                decoration: BoxDecoration(
                  color: isLocked 
                      ? Colors.orange.withAlpha(25)
                      : grad[0].withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    isLocked ? Iconsax.lock : Iconsax.document_text_1, 
                    color: isLocked ? Colors.orange : grad[0], 
                    size: 20
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isPremium) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isPurchased ? Colors.green.withAlpha(25) : Colors.orange.withAlpha(25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isPurchased ? 'UNLOCKED' : 'PREMIUM',
                              style: TextStyle(
                                color: isPurchased ? Colors.green : Colors.orange,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'PDF Document · ${DateTime.now().year}',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF9AA0A6) : const Color(0xFF8E8E93),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isLocked 
                      ? Iconsax.lock 
                      : (isDownloaded ? Iconsax.tick_circle : Iconsax.document_download),
                  color: isLocked 
                      ? Colors.orange.withAlpha(150)
                      : (isDownloaded ? Colors.green : (isDark ? const Color(0xFF3A3F4B) : const Color(0xFFE0E0E0))),
                  size: 20,
                ),
                onPressed: isLocked ? () => _openCheckout(item) : (isDownloaded ? null : () async {
                  try {
                    await OfflineService().downloadResource(
                      id: id,
                      title: title,
                      url: fileUrl,
                      category: ResourceCategory.EXAM_FOCUS,
                    );
                    if (mounted) setState(() {});
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }),
              ),
              const SizedBox(width: 8),
              Icon(Iconsax.arrow_right_3, color: isDark ? const Color(0xFF3A3F4B) : const Color(0xFFE0E0E0), size: 16),
            ],
          ),
        ),
      ),
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
