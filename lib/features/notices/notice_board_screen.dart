import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/supabase_client.dart';
import 'package:url_launcher/url_launcher.dart';

class NoticeBoardScreen extends StatefulWidget {
  const NoticeBoardScreen({super.key});

  @override
  State<NoticeBoardScreen> createState() => _NoticeBoardScreenState();
}

class _NoticeBoardScreenState extends State<NoticeBoardScreen> {
  final _client = SupabaseClientService.client;
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
        _markNoticesAsRead();
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

  Future<void> _markNoticesAsRead() async {
    // Optional: Update 'is_new' to false locally for UI, 
    // real app might track this per-user in a separate table.
  }

  Future<void> _openLink(String urlStr) async {
    try {
      final url = Uri.parse(urlStr);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open the link.')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid link.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF8E82FF) : const Color(0xFF7C6FF6);
    final bgPrimary = isDark ? const Color(0xFF0F1115) : const Color(0xFFF4F5F7);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E1E1E);
    final textSecondary = isDark ? const Color(0xFF9AA0A6) : const Color(0xFF8E8E93);
    final cardBg = isDark ? const Color(0xFF171A21) : Colors.white;

    return Scaffold(
      backgroundColor: bgPrimary,
      appBar: AppBar(
        title: const Text('Official Notices', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: () => _fetchNotices(),
          )
        ],
      ),
      body: _buildBody(primaryColor, textPrimary, textSecondary, cardBg, isDark),
    );
  }

  Widget _buildBody(Color primaryColor, Color textPrimary, Color textSecondary, Color cardBg, bool isDark) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: primaryColor));
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
            Icon(Iconsax.document_filter, size: 64, color: textSecondary.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('No official notices yet', style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
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
            onTap: () => _openLink(notice['link']),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? const Color(0xFF2A2F3A) : const Color(0xFFE6E8EC)),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(catIcon, color: catColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A2F3A) : const Color(0xFFF4F5F7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isNew)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('NEW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notice['title'],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
