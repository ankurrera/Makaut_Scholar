import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/offline_service.dart';
import 'pdf_viewer_screen.dart';
import '../premium/premium_checkout_screen.dart';

class NotesViewerScreen extends StatefulWidget {
  final String department;
  final int semester;
  final String subject;
  const NotesViewerScreen({
    super.key,
    required this.department,
    required this.semester,
    required this.subject,
  });

  @override
  State<NotesViewerScreen> createState() => _NotesViewerScreenState();
}

class _NotesViewerScreenState extends State<NotesViewerScreen> {
  List<Map<String, dynamic>> _notes = [];
  List<String> _purchasedItemIds = [];
  bool _isLoading = true;
  String? _error;

  // ── Palette ──
  static const _accentLight = Color(0xFF7C6FF6);
  static const _accentDark = Color(0xFF8E82FF);

  Color _bg(bool d) => d ? const Color(0xFF0F1115) : const Color(0xFFF4F5F7);
  static const _card = Colors.white;
  Color _textP(bool d) => d ? const Color(0xFFF5F6FA) : const Color(0xFF1E1E1E);
  Color _textS(bool d) => d ? const Color(0xFF9AA0A6) : const Color(0xFF8E8E93);
  Color _border(bool d) => d ? const Color(0xFF2A2F3A) : const Color(0xFFE6E8EC);
  Color _accent(bool d) => d ? _accentDark : _accentLight;

  // Fixed dark text for white cards
  static const _cardTextP = Color(0xFF1E1E1E);
  static const _cardTextS = Color(0xFF8E8E93);

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final results = await Future.wait([
        auth.fetchNotes(widget.department, widget.semester, widget.subject),
        auth.fetchUserPurchases('notes'),
      ]);
      
      if (mounted) {
        setState(() { 
          _notes = results[0] as List<Map<String, dynamic>>;
          _purchasedItemIds = results[1] as List<String>;
          _isLoading = false; 
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _openPdf({String? url, String? filePath, required String title}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(url: url, filePath: filePath, title: title),
      ),
    );
  }

  void _openCheckout(Map<String, dynamic> note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PremiumCheckoutScreen(
          itemId: note['id'].toString(),
          itemType: 'notes',
          itemName: note['title'] ?? 'Academic Note',
          price: (note['price'] as num?)?.toDouble() ?? 0.0,
        ),
      ),
    ).then((_) => _loadNotes()); // Reload to catch new purchase
  }

  /// Group notes by unit number
  Map<int, List<Map<String, dynamic>>> _groupByUnit() {
    final map = <int, List<Map<String, dynamic>>>{};
    for (final n in _notes) {
      final unit = n['unit'] as int;
      map.putIfAbsent(unit, () => []).add(n);
    }
    return Map.fromEntries(map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _accent(isDark);

    return Scaffold(
      backgroundColor: _bg(isDark),
      appBar: AppBar(
        backgroundColor: _bg(isDark),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left, color: _textP(isDark)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(widget.subject,
                style: TextStyle(color: _textP(isDark), fontSize: 18, fontWeight: FontWeight.w600)),
            Text('Sem ${widget.semester} · ${widget.department}',
                style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accent))
          : _error != null
              ? _buildError(isDark, accent)
              : _notes.isEmpty
                  ? _buildEmpty(isDark)
                  : RefreshIndicator(
                      color: accent,
                      onRefresh: _loadNotes,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                        children: _buildUnitSections(isDark, accent),
                      ),
                    ),
    );
  }

  List<Widget> _buildUnitSections(bool isDark, Color accent) {
    final grouped = _groupByUnit();
    final widgets = <Widget>[];

    for (final entry in grouped.entries) {
      // Unit header
      widgets.add(Padding(
        padding: EdgeInsets.only(top: widgets.isEmpty ? 0 : 24, bottom: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Unit ${entry.key}',
                  style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Divider(color: _border(isDark).withValues(alpha: 0.4))),
          ],
        ),
      ));

      // Note cards for this unit
      for (final note in entry.value) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _noteCard(note, isDark, accent),
        ));
      }
    }

    return widgets;
  }

  Widget _noteCard(Map<String, dynamic> note, bool isDark, Color accent) {
    final id = note['id'].toString();
    final isDownloaded = OfflineService().isDownloaded(id);
    final title = note['title'] ?? 'Untitled';
    final url = note['file_url'];
    final isPremium = note['is_premium'] == true;
    final isPurchased = _purchasedItemIds.contains(id);
    final isLocked = isPremium && !isPurchased;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLocked ? Colors.orange.withValues(alpha: 0.3) : _border(isDark).withValues(alpha: 0.4),
          width: isLocked ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                if (isLocked) {
                  _openCheckout(note);
                } else if (isDownloaded) {
                  final resource = OfflineService().getResource(id);
                  _openPdf(filePath: resource!.localPath, title: title);
                } else {
                  _openPdf(url: url, title: title);
                }
              },
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isLocked 
                          ? Colors.orange.withValues(alpha: 0.1)
                          : accent.withValues(alpha: isDark ? 0.12 : 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isLocked ? Iconsax.lock : Iconsax.document_text, 
                      color: isLocked ? Colors.orange : accent, 
                      size: 20
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(color: _cardTextP, fontSize: 14, fontWeight: FontWeight.w500),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isPremium)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isPurchased ? 'UNLOCKED' : 'PREMIUM',
                                  style: const TextStyle(color: Colors.orange, fontSize: 9, fontWeight: FontWeight.w700),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isLocked 
                              ? 'Premium Content · ₹${note['price']}' 
                              : (isDownloaded ? 'Offline Access Enabled' : 'PDF · Tap to open'),
                          style: TextStyle(
                            color: isLocked ? Colors.orange : (isDownloaded ? Colors.green : _cardTextS), 
                            fontSize: 11
                          )
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isLocked)
            IconButton(
              icon: Icon(
                isDownloaded ? Iconsax.tick_circle : Iconsax.document_download,
                color: isDownloaded ? Colors.green : _cardTextS,
                size: 20,
              ),
              onPressed: isDownloaded ? null : () async {
                try {
                  await OfflineService().downloadResource(
                    id: id,
                    title: title,
                    url: url,
                    category: ResourceCategory.NOTES,
                  );
                  if (mounted) setState(() {});
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
            ),
          if (!isLocked) ...[
            const SizedBox(width: 4),
            Icon(Iconsax.export_1, color: _cardTextS, size: 18),
          ] else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Iconsax.shopping_cart, color: Colors.orange, size: 18),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.document, size: 48, color: _textS(isDark).withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('No notes available yet',
              style: TextStyle(color: _textS(isDark), fontSize: 15, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text('Notes will appear here once uploaded',
              style: TextStyle(color: _textS(isDark).withValues(alpha: 0.6), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildError(bool isDark, Color accent) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.warning_2, size: 44, color: Colors.redAccent.withValues(alpha: 0.6)),
          const SizedBox(height: 14),
          Text('Failed to load notes', style: TextStyle(color: _textP(isDark), fontSize: 15, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _loadNotes,
            icon: Icon(Iconsax.refresh, size: 16, color: accent),
            label: Text('Retry', style: TextStyle(color: accent, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
