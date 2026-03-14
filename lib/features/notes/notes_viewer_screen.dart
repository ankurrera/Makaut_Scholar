import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
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
  bool _hasAccess = false; // Full subject/bundle access
  Map<int, double> _unitPrices = {}; // unit → price (from unit_prices table)
  Set<int> _unlockedUnits = {}; // units the user has individually purchased
  Map<String, dynamic> _pricing = {};
  bool _isLoading = true;
  String? _error;

  // ── Palette ──
  static const _accentLight = Color(0xFF111111);
  static const _accentDark = Colors.white;

  Color _bg(bool isDark) => isDark ? Colors.black : Colors.white;
  Color _card(bool d) => d ? const Color(0xFF0A0A0A) : Colors.white;
  Color _textP(bool d) => d ? const Color(0xFFF5F6FA) : const Color(0xFF1E1E1E);
  Color _textS(bool d) => d ? const Color(0xFF9AA0A6) : const Color(0xFF8E8E93);
  Color _border(bool d) =>
      d ? const Color(0xFF1A1A1A) : const Color(0xFFE6E8EC);
  Color _accent(bool d) => d ? _accentDark : _accentLight;

  // ── Luxury Palette ──
  static const _brandRed = Color(0xFFE5252A);
  static const _redGradient = [Color(0xFFE5252A), Color(0xFFFF4D4D)];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final mon = Provider.of<MonetizationService>(context, listen: false);

      // ── 1. Fetch notes (must succeed, this is the core data) ──
      final notes = await auth.fetchNotes(
        widget.department,
        widget.semester,
        widget.subject,
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
        if (kDebugMode)
          print('checkSubjectAccess error (defaulting to locked): $e');
      }

      // ── 4. Fetch pricing details (graceful fallback) ──
      Map<String, dynamic> pricing = <String, dynamic>{'subject_price': 0.0};
      try {
        pricing = await mon.getPricingDetails(
            widget.department, widget.semester, widget.subject);
      } catch (e) {
        if (kDebugMode)
          print('getPricingDetails error (defaulting to empty): $e');
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
      if (mounted)
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
    }
  }

  void _openPdf({String? url, String? filePath, required String title}) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PdfViewerScreen(url: url, filePath: filePath, title: title),
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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.star_1, color: _brandRed, size: 48),
            const SizedBox(height: 16),
            Text("Ready to master ${widget.subject}?",
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
                "You've viewed some great preview content! Unlock the full subject to continue your learning journey without limits.",
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: _brandRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                if (_notes.isNotEmpty) {
                  _openCheckout(_notes.firstWhere(
                      (n) => n['is_premium'] == true,
                      orElse: () => _notes.first));
                }
              },
              child: const Text("Unlock Full Access",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  void _openCheckout(Map<String, dynamic> note, {int? unitOverride}) async {
    final int unit = unitOverride ?? (note['unit'] as int? ?? 1);
    final double unitPrice = _unitPrices[unit] ?? 0.0;
    final double subjectPrice =
        (_pricing['subject_price'] as num?)?.toDouble() ?? 0.0;
    final double bundlePrice =
        (_pricing['bundle_price'] as num?)?.toDouble() ?? 0.0;
    final int boughtCount = (_pricing['purchased_subjects_count'] as int?) ?? 0;

    // Determine which tier to offer
    double finalPrice;
    String finalItemId;
    String finalItemType;
    String finalItemName;

    if (unitPrice > 0) {
      // Offer unit access first (cheapest option)
      finalPrice = unitPrice;
      finalItemId =
          'unit_${widget.department}_${widget.semester}_${widget.subject}_$unit';
      finalItemType = 'unit';
      finalItemName = '${widget.subject} – Unit $unit';
    } else if (subjectPrice > 0) {
      finalPrice = subjectPrice;
      finalItemId =
          'subject_${widget.department}_${widget.semester}_${widget.subject}';
      finalItemType = 'subject';
      finalItemName = '${widget.subject} Full Access';
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Pricing not configured for this content.')),
      );
      return;
    }

    // Smart bundle upgrade: if user bought 3+ subjects, offer bundle at discounted price
    if (boughtCount >= 3 && bundlePrice > 0 && subjectPrice > 0 && mounted) {
      final mon = Provider.of<MonetizationService>(context, listen: false);
      final upgradePrice = mon.calculateBundleUpgradePrice(
          bundlePrice, boughtCount, subjectPrice);
      if (upgradePrice > 0) {
        finalPrice = upgradePrice;
        finalItemId = 'bundle_${widget.department}_${widget.semester}';
        finalItemType = 'semester_bundle';
        finalItemName = 'Sem ${widget.semester} Complete Bundle';
      }
    }

    final result = await Navigator.push(
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
    );

    // ALWAYS reload to update locked/unlocked state — even if cancelled.
    if (mounted) {
      _loadNotes();
      if (result is Map && result['success'] == true) {
        final String? itemUrl = result['itemUrl'] as String?;
        final String itemName = result['itemName'] as String? ?? 'Academic Note';
        if (itemUrl != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Content unlocked! ✨'),
              backgroundColor: Color(0xFFE5252A),
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
            ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 40),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.subject,
                      style: const TextStyle(
                        fontFamily: 'NDOT',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
            Text(
                  widget.department,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: (Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black)
                        .withOpacity(0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                        children: _buildFlatNotesList(isDark, accent),
                      ),
                    ),
    );
  }

  List<Widget> _buildFlatNotesList(bool isDark, Color accent) {
    if (_notes.isEmpty) return [];

    final widgets = <Widget>[];
    for (int i = 0; i < _notes.length; i++) {
      final note = _notes[i];
      final int unit = (note['unit'] as int?) ?? 1;

      final bool noteLocked = (note['is_premium'] == true) &&
          !_hasAccess &&
          !_unlockedUnits.contains(unit);

      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child:
            _noteCard(note, isDark, accent, isLocked: noteLocked, unit: unit),
      ));
    }
    return widgets;
  }

  Widget _noteCard(Map<String, dynamic> note, bool isDark, Color accent,
      {required bool isLocked, required int unit}) {
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
        border: isLocked
            ? null
            : Border.all(
                color: isDark ? Colors.black : const Color(0xFFE5E5EA),
                width: 1,
              ),
        boxShadow: [],
      ),
      child: CustomPaint(
        painter: isLocked ? _DottedBorderPainter(color: (isDark ? Colors.white : Colors.black).withOpacity(0.2)) : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Material(
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
                              Icon(
                                  isLocked ? Iconsax.lock_1_copy : Iconsax.document_1,
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

                        // ── Info & Action Column ──
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  color: isLocked 
                                      ? _textP(isDark).withOpacity(0.5)
                                      : _textP(isDark),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  if (!isLocked)
                                    Icon(
                                      isDownloaded
                                          ? Iconsax.cloud_drizzle
                                          : Iconsax.document_text,
                                      size: 12,
                                      color: isDownloaded
                                          ? Colors.green
                                          : _textS(isDark),
                                    ),
                                  if (!isLocked) const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      isLocked
                                          ? 'SPEC: UNIT-${unit.toString().padLeft(2, '0')} // VAL: ${_unitPrices[unit]?.toInt() ?? '--'}'
                                          : (isDownloaded
                                              ? 'Unit $unit · Available Offline'
                                              : 'Unit $unit · Ready to Read · PDF'),
                                      style: TextStyle(
                                        fontFamily: isLocked ? 'NDOT' : null,
                                        color: isLocked
                                            ? _brandRed
                                            : _textS(isDark),
                                        fontSize: isLocked ? 10 : 12,
                                        fontWeight: isLocked
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        letterSpacing: isLocked ? 0.5 : null,
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

                        // ── Download Action (only for unlocked) ──
                        if (!isLocked)
                          IconButton(
                            icon: isDownloaded
                                ? const Icon(Iconsax.tick_circle,
                                    color: Colors.green, size: 22)
                                : Image.asset(
                                    'assets/icons/down_to_line.png',
                                    width: 22,
                                    height: 22,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                            onPressed: isDownloaded
                                ? null
                                : () async {
                                    try {
                                      await OfflineService().downloadResource(
                                        id: id,
                                        title: title,
                                        url: url,
                                        category: ResourceCategory.NOTES,
                                      );
                                      if (mounted) setState(() {});
                                    } catch (e) {
                                      if (mounted)
                                        ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(e.toString())));
                                    }
                                  },
                          ),
                      ],
                    ),
                  ),
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

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.document,
              size: 48, color: _textS(isDark).withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('No notes available yet',
              style: TextStyle(
                  color: _textS(isDark),
                  fontSize: 15,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text('Notes will appear here once uploaded',
              style: TextStyle(
                  color: _textS(isDark).withValues(alpha: 0.6), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildError(bool isDark, Color accent) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.warning_2,
              size: 44, color: Colors.redAccent.withValues(alpha: 0.6)),
          const SizedBox(height: 14),
          Text('Failed to load notes',
              style: TextStyle(
                  color: _textP(isDark),
                  fontSize: 15,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _loadNotes,
            icon: Icon(Iconsax.refresh, size: 16, color: accent),
            label: Text('Retry',
                style: TextStyle(color: accent, fontWeight: FontWeight.w500)),
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
        const Radius.circular(24),
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
