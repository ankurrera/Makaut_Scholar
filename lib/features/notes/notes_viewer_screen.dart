import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/offline_service.dart';
import 'pdf_viewer_screen.dart';
import '../premium/premium_checkout_screen.dart';
import '../../services/monetization_service.dart';

class NotesViewerScreen extends StatefulWidget {
  final String department;
  final int semester;
  final String subject;
  final String? paperCode;
  const NotesViewerScreen({
    super.key,
    required this.department,
    required this.semester,
    required this.subject,
    this.paperCode,
  });

  @override
  State<NotesViewerScreen> createState() => _NotesViewerScreenState();
}

class _NotesViewerScreenState extends State<NotesViewerScreen> {
  List<Map<String, dynamic>> _notes = [];
  bool _hasAccess = false;              // Full subject/bundle access
  Map<int, double> _unitPrices = {};   // unit → price (from unit_prices table)
  Set<int> _unlockedUnits = {};        // units the user has individually purchased
  Map<String, dynamic> _pricing = {};
  bool _isLoading = true;
  String? _error;

  // ── Palette ──
  static const _accentLight = Color(0xFF7C6FF6);
  static const _accentDark = Color(0xFF8E82FF);

  Color _bg(bool d) => d ? const Color(0xFF0F1115) : const Color(0xFFF4F5F7);
  Color _card(bool d) => d ? const Color(0xFF181B22) : Colors.white;
  Color _textP(bool d) => d ? const Color(0xFFF5F6FA) : const Color(0xFF1E1E1E);
  Color _textS(bool d) => d ? const Color(0xFF9AA0A6) : const Color(0xFF8E8E93);
  Color _border(bool d) => d ? const Color(0xFF2A2F3A) : const Color(0xFFE6E8EC);
  Color _accent(bool d) => d ? _accentDark : _accentLight;

  // ── Luxury Palette ──
  static const _goldGradient = [Color(0xFFFDB931), Color(0xFFFDC958)];
  static const _premiumGold = Color(0xFFFDB931);

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final mon = Provider.of<MonetizationService>(context, listen: false);

      // ── 1. Fetch notes (must succeed, this is the core data) ──
      final notes = await auth.fetchNotes(
        widget.department, widget.semester, widget.subject,
        paperCode: widget.paperCode,
      );

      // ── 2. Derive unit prices directly from notes (no separate table) ──
      final Map<int, double> unitPrices = <int, double>{};
      for (final note in notes) {
        if (note['is_premium'] == true) {
          final int unit = (note['unit'] as num?)?.toInt() ?? 0;
          final double price = (note['price'] as num?)?.toDouble() ?? 0.0;
          if (unit > 0 && price > 0 && !unitPrices.containsKey(unit)) {
            unitPrices[unit] = price;
          }
        }
      }

      // ── 3. Check access (graceful fallback to false) ──
      bool hasFullAccess = false;
      try {
        hasFullAccess = await mon.checkSubjectAccess(
          widget.department, widget.semester, widget.subject);
      } catch (e) {
        if (kDebugMode) print('checkSubjectAccess error (defaulting to locked): $e');
      }

      // ── 4. Fetch pricing details (graceful fallback) ──
      Map<String, dynamic> pricing = <String, dynamic>{'subject_price': 0.0};
      try {
        pricing = await mon.getPricingDetails(
          widget.department, widget.semester, widget.subject);
      } catch (e) {
        if (kDebugMode) print('getPricingDetails error (defaulting to empty): $e');
      }

      // ── 5. Check per-unit access ──
      final Set<int> unlockedUnits = {};
      if (!hasFullAccess && unitPrices.isNotEmpty) {
        await Future.wait(unitPrices.keys.map((unit) async {
          try {
            final hasUnit = await mon.checkUnitAccess(
              widget.department, widget.semester, widget.subject, unit);
            if (hasUnit) unlockedUnits.add(unit);
          } catch (_) {}
        }));
      }

      if (mounted) {
        setState(() {
          _notes = notes;
          _hasAccess = hasFullAccess;
          _pricing = pricing;
          _unitPrices = unitPrices;
          _unlockedUnits = unlockedUnits;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _openPdf({String? url, String? filePath, required String title}) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(url: url, filePath: filePath, title: title),
      ),
    );
    
    // Flow 2: Behavioral Nudging
    if (!_hasAccess) {
      final mon = Provider.of<MonetizationService>(context, listen: false);
      bool shouldNudge = await mon.recordInteraction();
      if (shouldNudge && mounted) {
        _showNudgeModal();
      }
    }
  }

  void _showNudgeModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.star_1, color: Colors.orange, size: 48),
            const SizedBox(height: 16),
            Text("Ready to master ${widget.subject}?", 
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text("You've viewed some great preview content! Unlock the full subject to continue your learning journey without limits.",
              style: TextStyle(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: const Color(0xFF8E82FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                if (_notes.isNotEmpty) {
                  _openCheckout(_notes.firstWhere((n) => n['is_premium'] == true, orElse: () => _notes.first));
                }
              },
              child: const Text("Unlock Full Access", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  void _openCheckout(Map<String, dynamic> note, {int? unitOverride}) {
    final int unit = unitOverride ?? (note['unit'] as int? ?? 1);
    final double unitPrice = _unitPrices[unit] ?? 0.0;
    final double subjectPrice = (_pricing['subject_price'] as num?)?.toDouble() ?? 0.0;
    final double bundlePrice = (_pricing['bundle_price'] as num?)?.toDouble() ?? 0.0;
    final int boughtCount = (_pricing['purchased_subjects_count'] as int?) ?? 0;

    // Determine which tier to offer
    double finalPrice;
    String finalItemId;
    String finalItemType;
    String finalItemName;

    if (unitPrice > 0) {
      // Offer unit access first (cheapest option)
      finalPrice = unitPrice;
      finalItemId = 'unit_${widget.department}_${widget.semester}_${widget.subject}_$unit';
      finalItemType = 'unit';
      finalItemName = '${widget.subject} – Unit $unit';
    } else if (subjectPrice > 0) {
      finalPrice = subjectPrice;
      finalItemId = 'subject_${widget.department}_${widget.semester}_${widget.subject}';
      finalItemType = 'subject';
      finalItemName = '${widget.subject} Full Access';
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pricing not configured for this content.')),
      );
      return;
    }

    // Smart bundle upgrade: if user bought 3+ subjects, offer bundle at discounted price
    if (boughtCount >= 3 && bundlePrice > 0 && subjectPrice > 0 && mounted) {
      final mon = Provider.of<MonetizationService>(context, listen: false);
      final upgradePrice = mon.calculateBundleUpgradePrice(bundlePrice, boughtCount, subjectPrice);
      if (upgradePrice > 0) {
        finalPrice = upgradePrice;
        finalItemId = 'bundle_${widget.department}_${widget.semester}';
        finalItemType = 'semester_bundle';
        finalItemName = 'Sem ${widget.semester} Complete Bundle';
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PremiumCheckoutScreen(
          itemId: finalItemId,
          itemType: finalItemType,
          itemName: finalItemName,
          itemUrl: note['file_url'],
          price: finalPrice,
        ),
      ),
    ).then((result) {
      if (result != null && result is Map && result['success'] == true) {
        final String? itemUrl = result['itemUrl'];
        final String itemName = result['itemName'] ?? 'Academic Note';
        if (itemUrl != null) {
          // Show non-blocking success feedback
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unlock Successful! ✨ Preparing your content...'),
              backgroundColor: Color(0xFF8E82FF),
              duration: Duration(seconds: 2),
            ),
          );
          // Open PDF immediately for zero-friction experience
          _openPdf(url: itemUrl, title: itemName);
        }
        // Reload notes in background after starting the PDF viewer
        _loadNotes();
      } else {
        // Just reload if we returned without a specific success object
        _loadNotes();
      }
    }); 
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
      final int unit = entry.key;
      final double? unitPrice = _unitPrices[unit];
      // Unit is locked if it has a price set AND user doesn't have unit/subject access
      final bool unitLocked = !_hasAccess && !_unlockedUnits.contains(unit) && unitPrice != null && unitPrice > 0;
      // Check if this unit has ANY premium notes
      final bool hasAnyPremiumNotes = entry.value.any((n) => n['is_premium'] == true);
      final bool showUnitLock = unitLocked && hasAnyPremiumNotes;

      // Unit header
      widgets.add(Padding(
        padding: EdgeInsets.only(top: widgets.isEmpty ? 0 : 24, bottom: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: showUnitLock 
                    ? _premiumGold.withValues(alpha: isDark ? 0.15 : 0.1)
                    : accent.withValues(alpha: isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showUnitLock) ...[
                    const Icon(Iconsax.lock_1_copy, size: 11, color: _premiumGold),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    'Unit $unit',
                    style: TextStyle(
                      color: showUnitLock ? _premiumGold : accent, 
                      fontSize: 12, 
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Divider(color: _border(isDark).withValues(alpha: 0.4))),
            if (showUnitLock) ...[
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _openCheckout(entry.value.first, unitOverride: unit),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: _goldGradient),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Buy Unit $unit · ₹${unitPrice.toInt()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ));

      // Note cards — lock each note using is_premium flag + unit access check
      for (final note in entry.value) {
        final bool noteLocked = (note['is_premium'] == true) && !_hasAccess && !_unlockedUnits.contains(unit);
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _noteCard(note, isDark, accent, isLocked: noteLocked, unit: unit),
        ));
      }
    }

    return widgets;
  }

  Widget _noteCard(Map<String, dynamic> note, bool isDark, Color accent, {required bool isLocked, required int unit}) {
    final id = note['id'].toString();
    final isDownloaded = OfflineService().isDownloaded(id);
    final title = note['title'] ?? 'Untitled';
    final url = note['file_url'];
    final isPremium = note['is_premium'] == true;
    // isLocked is passed from the unit section — no hardcoded preview unit logic

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _card(isDark),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLocked 
              ? _premiumGold.withValues(alpha: 0.3) 
              : _border(isDark).withValues(alpha: 0.08),
          width: isLocked ? 1.5 : 1,
        ),
        boxShadow: isLocked ? [
          BoxShadow(
            color: _premiumGold.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ] : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (isLocked) {
                _openCheckout(note, unitOverride: unit);
              } else if (isDownloaded) {
                final resource = OfflineService().getResource(id);
                _openPdf(filePath: resource!.localPath, title: title);
              } else {
                _openPdf(url: url, title: title);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // ── Icon Container ──
                  Stack(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isLocked 
                              ? _premiumGold.withValues(alpha: 0.1)
                              : accent.withValues(alpha: isDark ? 0.1 : 0.05),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          isLocked ? Iconsax.lock_1_copy : Iconsax.document_text_1, 
                          color: isLocked ? _premiumGold : accent, 
                          size: 24
                        ),
                      ),
                      if (isLocked)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: _premiumGold,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Iconsax.star_1, size: 8, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  
                  // ── Info & Action Column ──
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  color: _textP(isDark), 
                                  fontSize: 15, 
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isLocked) ...[
                              const SizedBox(width: 8),
                              Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: _goldGradient),
                                  borderRadius: BorderRadius.circular(100), // pill shape looks better
                                  boxShadow: [
                                    BoxShadow(
                                      color: _premiumGold.withValues(alpha: 0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                ),
                                child: const Text(
                                  'PRO',
                                  style: TextStyle(
                                    color: Colors.white, 
                                    fontSize: 9, 
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              isLocked ? Iconsax.flash_1 : (isDownloaded ? Iconsax.cloud_drizzle : Iconsax.document_text),
                              size: 12,
                              color: isLocked ? _premiumGold : (isDownloaded ? Colors.green : _textS(isDark)),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isLocked 
                                  ? 'Unlock Unit $unit · ₹${_unitPrices[unit]?.toInt() ?? '--'}' 
                                  : (isDownloaded ? 'Available Offline' : 'Ready to Read · PDF'),
                              style: TextStyle(
                                color: isLocked ? _premiumGold.withValues(alpha: 0.8) : _textS(isDark), 
                                fontSize: 12,
                                fontWeight: isLocked ? FontWeight.w500 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // ── Download Action (only for unlocked) ──
                  if (!isLocked)
                    IconButton(
                      icon: Icon(
                        isDownloaded ? Iconsax.tick_circle : Iconsax.document_download,
                        color: isDownloaded ? Colors.green : _textS(isDark),
                        size: 22,
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
