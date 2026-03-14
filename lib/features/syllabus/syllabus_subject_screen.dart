import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/offline_service.dart';
import '../../core/widgets/dot_loading.dart';
import '../../core/widgets/solid_folder.dart';
import '../../core/widgets/shimmer_skeleton.dart';
import '../../core/widgets/premium_route.dart';
import '../../services/cache_service.dart';
import '../notes/pdf_viewer_screen.dart';

class SyllabusSubjectScreen extends StatefulWidget {
  final String department;
  final int semester;
  const SyllabusSubjectScreen(
      {super.key, required this.department, required this.semester});

  @override
  State<SyllabusSubjectScreen> createState() => _SyllabusSubjectScreenState();
}

class _SyllabusSubjectScreenState extends State<SyllabusSubjectScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _syllabusEntries = [];
  bool _isLoading = true;
  String? _error;

  static const _accentLight = Color(0xFF111111); // Monochrome Black
  static const _accentDark = Color(0xFFF5F6FA); // Monochrome White

  Color _bg(bool d) => d ? Colors.black : const Color(0xFFF9F9FB);
  Color _card(bool d) => d ? const Color(0xFF1C1C1E) : Colors.white;
  Color _textP(bool d) => d ? const Color(0xFFF5F6FA) : const Color(0xFF111111);
  Color _textS(bool d) => d ? const Color(0xFF8E8E93) : const Color(0xFF888888);
  Color _accent(bool d) => d ? _accentDark : _accentLight;

  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadSyllabus();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _loadSyllabus() async {
    setState(() {
      _error = null;
    });
    try {
      final auth = Provider.of<AuthService>(context, listen: false);

      // Try to load from cache first
      final cacheKey = 'syllabus_all_entries_${widget.department}_${widget.semester}';
      final cachedData = CacheService().get(cacheKey);

      if (cachedData != null && cachedData is List) {
        setState(() {
          _syllabusEntries = List<Map<String, dynamic>>.from(cachedData);
          _isLoading = false;
        });
        _staggerController.forward(from: 0);
      } else {
        setState(() => _isLoading = true);
      }
      // Fetch all subjects, then for each get syllabus entries
      final subjects =
          await auth.fetchSyllabusSubjects(widget.department, widget.semester);
      List<Map<String, dynamic>> allEntries = [];
      for (final subjectData in subjects) {
        final subject = subjectData['subject'] as String;
        final paperCode = subjectData['paper_code'] as String?;
        final entries = await auth.fetchSyllabus(
            widget.department, widget.semester, subject,
            paperCode: paperCode);
        allEntries.addAll(entries);
      }
      if (mounted) {
        setState(() {
          _syllabusEntries = allEntries;
          _isLoading = false;
        });
        _staggerController.forward(from: 0);
        
        // Cache the processed entries
        final cacheKey = 'syllabus_all_entries_${widget.department}_${widget.semester}';
        CacheService().set(cacheKey, allEntries);
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

  // Split entries into normal subjects and labs
  bool _isLab(String subject) {
    final lower = subject.toLowerCase();
    return lower.contains('laboratory') || RegExp(r'\blab\b').hasMatch(lower);
  }

  List<Map<String, dynamic>> get _normalEntries =>
      _syllabusEntries.where((e) => !_isLab(e['subject'] as String)).toList();

  List<Map<String, dynamic>> get _labEntries =>
      _syllabusEntries.where((e) => _isLab(e['subject'] as String)).toList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _accent(isDark);
    final normal = _normalEntries;
    final labs = _labEntries;

    return Scaffold(
      backgroundColor: _bg(isDark),
      body: _isLoading && _syllabusEntries.isEmpty
          ? _buildLoadingSkeleton(isDark)
          : _error != null
              ? _buildError(isDark, accent)
              : _syllabusEntries.isEmpty
                  ? _buildEmpty(isDark)
                  : RefreshIndicator(
                      color: accent,
                      onRefresh: _loadSyllabus,
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
                                80,
                            leading: IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _card(isDark),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF2C2C2E)
                                        : const Color(0xFFF2F2F2),
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
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Syllabus',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _textP(isDark),
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.5,
                                        fontFamily: 'NDOT',
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_syllabusEntries.length} subject${_syllabusEntries.length != 1 ? 's' : ''} available',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _textS(isDark),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // ── Subjects section ──
                          if (normal.isNotEmpty) ...[
                            _sectionHeader('Subjects', Iconsax.book_1,
                                normal.length, isDark),
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, i) => _animatedTile(
                                      normal[i], i, normal.length, isDark),
                                  childCount: normal.length,
                                ),
                              ),
                            ),
                          ],

                          // ── Laboratory section ──
                          if (labs.isNotEmpty) ...[
                            _sectionHeader(
                                'Laboratory', Iconsax.cpu, labs.length, isDark),
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, i) => _animatedTile(
                                      labs[i], i, labs.length, isDark),
                                  childCount: labs.length,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, int count, bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: _accent(isDark)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: _textP(isDark),
                  fontFamily: 'Ndot',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _accent(isDark).withValues(alpha: isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                    color: _accent(isDark),
                    fontSize: 11,
                    fontFamily: 'Ndot',
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _animatedTile(
      Map<String, dynamic> entry, int index, int total, bool isDark) {
    final interval = Interval(
      (index * 0.08).clamp(0.0, 0.5),
      ((index * 0.08) + 0.5).clamp(0.0, 1.0),
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
        child: _subjectTile(entry, index, isDark),
      ),
    );
  }

  Widget _subjectTile(Map<String, dynamic> entry, int index, bool isDark) {
    final tileBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final tileBorder =
        isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F2);
    final textPrimary = _textP(isDark);
    final textSecondary = _textS(isDark);

    final accentClr = _accent(isDark);

    // Folder icon colors - Proper white for dark mode, off-white for light mode
    final folderClr = isDark ? Colors.white : const Color(0xFFF2F0EF);
    final folderBorder = isDark ? Colors.transparent : const Color(0xFFE5E5EA);

    final subject = entry['subject'] as String;
    final title = entry['title'] as String;
    final fileUrl = entry['file_url'] as String;
    final id = entry['id'].toString();
    final isDownloaded = OfflineService().isDownloaded(id);

    return PressableWidget(
      onTap: () {
        if (isDownloaded) {
          final resource = OfflineService().getResource(id);
          _openPdf(
              filePath: resource!.localPath, title: '$subject Syllabus');
        } else {
          _openPdf(url: fileUrl, title: '$subject Syllabus');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: tileBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tileBorder, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 1. Solid White Folder Icon
            SizedBox(
              width: 52,
              height: 48,
              child: SolidFolder(
                color: folderClr,
                borderColor: folderBorder,
                tabHeight: 8,
              ),
            ),
            const SizedBox(width: 16),

            // 2. Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    subject,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // 3. Download/Action
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: isDownloaded
                      ? const Icon(Iconsax.tick_circle,
                          color: Colors.green, size: 19)
                      : Image.asset(
                          'assets/icons/down_to_line.png',
                          width: 19,
                          height: 19,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                  onPressed: isDownloaded
                      ? null
                      : () async {
                          try {
                            await OfflineService().downloadResource(
                              id: id,
                              title: '$subject Syllabus',
                              url: fileUrl,
                              category: ResourceCategory.SYLLABUS,
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
          ],
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
            child: Icon(Iconsax.book_1,
                size: 36, color: _accent(isDark).withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 20),
          Text('No syllabus yet',
              style: TextStyle(
                  color: _textP(isDark),
                  fontSize: 17,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Syllabus PDFs will appear once uploaded',
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
          Text('Failed to load syllabus',
              style: TextStyle(
                  color: _textP(isDark),
                  fontSize: 17,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _loadSyllabus,
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(child: ShimmerSkeleton(width: 120, height: 20)),
                  SizedBox(height: 10),
                  ShimmerSkeleton(width: 180, height: 28, isNdot: true),
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
