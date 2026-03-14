import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../notes/pdf_viewer_screen.dart';
import '../../core/widgets/dot_loading.dart';

class NoticeBoardScreen extends StatefulWidget {
  const NoticeBoardScreen({super.key});

  @override
  State<NoticeBoardScreen> createState() => _NoticeBoardScreenState();
}

class _NoticeBoardScreenState extends State<NoticeBoardScreen> {
  SupabaseClient get _client => SupabaseClientService.client;
  List<Map<String, dynamic>> _notices = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchNotices();
  }

  Future<void> _fetchNotices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Ensure Supabase is ready
      await SupabaseClientService.init();
      if (!SupabaseClientService.isInitialized) {
        throw Exception(
            'Supabase is not initialized. Please check your connection.');
      }

      final response = await _client
          .from('official_notifications')
          .select()
          .order('date_posted', ascending: false)
          .limit(50);

      if (mounted) {
        setState(() {
          _notices = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load notices: \${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openLink(String urlStr, String title) async {
    if (urlStr.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(
          url: urlStr,
          title: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        isDark ? const Color(0xFFE5252A) : const Color(0xFFE5252A);
    final bgPrimary =
        isDark ? Colors.black : const Color(0xFFF8F6F1);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E1E1E);
    final textSecondary =
        isDark ? const Color(0xFF9AA0A6) : const Color(0xFF8E8E93);
    final cardBg = isDark ? const Color(0xFF1C2020) : Colors.white;

    return Scaffold(
      backgroundColor: bgPrimary,
      appBar: AppBar(
        title: const Text('Official Notices',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: () => _fetchNotices(),
          )
        ],
      ),
      body:
          _buildBody(primaryColor, textPrimary, textSecondary, cardBg, isDark),
    );
  }

  Widget _buildBody(Color primaryColor, Color textPrimary, Color textSecondary,
      Color cardBg, bool isDark) {
    if (_isLoading && _notices.isEmpty) {
      return const Center(child: DotLoadingIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.warning_2, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: textPrimary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchNotices,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_notices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.document_filter,
                size: 64, color: textSecondary.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('No official notices yet',
                style: TextStyle(
                    color: textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchNotices,
      color: primaryColor,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _notices.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final notice = _notices[index];
          return _NoticeCard(
            notice: notice,
            primaryColor: primaryColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            cardBg: cardBg,
            isDark: isDark,
            onTap: () => _openLink(notice['link'], notice['title']),
          );
        },
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final Map<String, dynamic> notice;
  final Color primaryColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBg;
  final bool isDark;
  final VoidCallback onTap;

  const _NoticeCard({
    required this.notice,
    required this.primaryColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBg,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = notice['date_posted'] as String;
    final isNew = notice['is_new'] as bool? ?? false;
    final category = notice['category'] as String? ?? 'General';

    IconData catIcon;
    Color catColor;

    if (category.contains('Result')) {
      catIcon = Iconsax.receipt_2_1;
      catColor = Colors.green;
    } else if (category.contains('Exam')) {
      catIcon = Iconsax.edit_2;
      catColor = Colors.orange;
    } else if (category.contains('Academic')) {
      catIcon = Iconsax.calendar_1;
      catColor = primaryColor;
    } else {
      catIcon = Iconsax.notification;
      catColor = isDark ? Colors.blue.shade300 : Colors.blue.shade700;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? const Color(0xFF2A3030) : const Color(0xFFE6E8EC),
            width: 1,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Category Indicator (Vertical Pill)
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: catColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),

              // Notification Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(catIcon, color: catColor, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w800,
                            color: catColor,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 10,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      notice['title'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                        height: 1.3,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Deep Blue Arrow or New Indicator
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isNew)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.redAccent, blurRadius: 4),
                          ]),
                    )
                  else
                    Icon(
                      Iconsax.arrow_right_3,
                      size: 16,
                      color: textSecondary.withOpacity(0.5),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
