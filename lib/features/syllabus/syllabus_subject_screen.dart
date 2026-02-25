import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/offline_service.dart';
import '../notes/pdf_viewer_screen.dart';

class SyllabusSubjectScreen extends StatefulWidget {
  final String department;
  final int semester;
  const SyllabusSubjectScreen({super.key, required this.department, required this.semester});

  @override
  State<SyllabusSubjectScreen> createState() => _SyllabusSubjectScreenState();
}

class _SyllabusSubjectScreenState extends State<SyllabusSubjectScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _syllabusEntries = [];
  bool _isLoading = true;
  String? _error;

  static const _accentLight = Color(0xFF34A875);
  static const _accentDark = Color(0xFF4FC9A8);

  Color _bg(bool d) => d ? const Color(0xFF0F1115) : const Color(0xFFF4F5F7);
  Color _card(bool d) => d ? const Color(0xFF181B22) : Colors.white;
  Color _textP(bool d) => d ? const Color(0xFFF5F6FA) : const Color(0xFF1E1E1E);
  Color _textS(bool d) => d ? const Color(0xFF9AA0A6) : const Color(0xFF8E8E93);
  Color _accent(bool d) => d ? _accentDark : _accentLight;

  static const _gradients = [
    [Color(0xFF34A875), Color(0xFF5BCC9A)],
    [Color(0xFF5BAAEF), Color(0xFF7BC4FF)],
    [Color(0xFF8B7CF6), Color(0xFFA78BFA)],
    [Color(0xFFE88AA0), Color(0xFFF5A0B4)],
    [Color(0xFFF0A850), Color(0xFFFFBE6A)],
    [Color(0xFF58C9B0), Color(0xFF76E4CA)],
    [Color(0xFFA07EF0), Color(0xFFB898FF)],
    [Color(0xFFE87878), Color(0xFFFF9A9A)],
    [Color(0xFF6CB4F0), Color(0xFF90CCFF)],
    [Color(0xFF8DD4A8), Color(0xFFA8ECC0)],
  ];

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
    setState(() { _isLoading = true; _error = null; });
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      // Fetch all subjects, then for each get syllabus entries
      final subjects = await auth.fetchSyllabusSubjects(widget.department, widget.semester);
      List<Map<String, dynamic>> allEntries = [];
      for (final subjectData in subjects) {
        final subject = subjectData['subject'] as String;
        final paperCode = subjectData['paper_code'] as String?;
        final entries = await auth.fetchSyllabus(widget.department, widget.semester, subject, paperCode: paperCode);
        allEntries.addAll(entries);
      }
      if (mounted) {
        setState(() { _syllabusEntries = allEntries; _isLoading = false; });
        _staggerController.forward(from: 0);
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
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: accent, strokeWidth: 2.5),
                  const SizedBox(height: 16),
                  Text('Loading syllabus...', style: TextStyle(color: _textS(isDark), fontSize: 13)),
                ],
              ),
            )
          : _error != null
              ? _buildError(isDark, accent)
              : _syllabusEntries.isEmpty
                  ? _buildEmpty(isDark)
                  : RefreshIndicator(
                      color: accent,
                      onRefresh: _loadSyllabus,
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        slivers: [
                          SliverAppBar(
                            backgroundColor: _bg(isDark),
                            elevation: 0,
                            scrolledUnderElevation: 0,
                            pinned: true,
                            expandedHeight: MediaQuery.of(context).padding.top + kToolbarHeight + 80,
                            leading: IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _card(isDark),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Iconsax.arrow_left, color: _textP(isDark), size: 18),
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            flexibleSpace: FlexibleSpaceBar(
                              background: Padding(
                                padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + kToolbarHeight + 8, 20, 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: accent.withValues(alpha: isDark ? 0.15 : 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Sem ${widget.semester} · ${widget.department}',
                                        style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Syllabus',
                                      style: TextStyle(
                                        color: _textP(isDark),
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_syllabusEntries.length} subject${_syllabusEntries.length != 1 ? 's' : ''} available',
                                      style: TextStyle(color: _textS(isDark), fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // ── Subjects section ──
                          if (normal.isNotEmpty) ...[
                            _sectionHeader('Subjects', Iconsax.book_1, normal.length, isDark),
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, i) => _animatedTile(normal[i], i, normal.length, isDark),
                                  childCount: normal.length,
                                ),
                              ),
                            ),
                          ],

                          // ── Laboratory section ──
                          if (labs.isNotEmpty) ...[
                            _sectionHeader('Laboratory', Iconsax.cpu, labs.length, isDark),
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, i) => _animatedTile(labs[i], i, labs.length, isDark),
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
            Text(
              title,
              style: TextStyle(
                color: _textP(isDark),
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _accent(isDark).withValues(alpha: isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(color: _accent(isDark), fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _animatedTile(Map<String, dynamic> entry, int index, int total, bool isDark) {
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
    final grad = _gradients[index % _gradients.length];
    final subject = entry['subject'] as String;
    final title = entry['title'] as String;
    final fileUrl = entry['file_url'] as String;
    final id = entry['id'].toString();
    final isDownloaded = OfflineService().isDownloaded(id);

    return Container(
      decoration: BoxDecoration(
        color: _card(isDark),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isDownloaded) {
              final resource = OfflineService().getResource(id);
              _openPdf(filePath: resource!.localPath, title: '$subject Syllabus');
            } else {
              _openPdf(url: fileUrl, title: '$subject Syllabus');
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Gradient icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: grad,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject,
                        style: TextStyle(
                          color: _textP(isDark),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Iconsax.document_text, size: 12, color: grad[0]),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              isDownloaded ? 'Offline Access Enabled' : title,
                              style: TextStyle(color: isDownloaded ? Colors.green : _textS(isDark), fontSize: 11),
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
                  icon: Icon(
                    isDownloaded ? Iconsax.tick_circle : Iconsax.document_download,
                    color: isDownloaded ? Colors.green : grad[0],
                    size: 20,
                  ),
                  onPressed: isDownloaded ? null : () async {
                    try {
                      await OfflineService().downloadResource(
                        id: id,
                        title: '$subject Syllabus',
                        url: fileUrl,
                        category: ResourceCategory.SYLLABUS,
                      );
                      if (mounted) setState(() {});
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  },
                ),
                const SizedBox(width: 4),

                // Arrow
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: grad[0].withValues(alpha: isDark ? 0.12 : 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Iconsax.arrow_right_3, color: grad[0], size: 16),
                ),
              ],
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
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: _accent(isDark).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Iconsax.book_1, size: 36, color: _accent(isDark).withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 20),
          Text('No syllabus yet',
              style: TextStyle(color: _textP(isDark), fontSize: 17, fontWeight: FontWeight.w600)),
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
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Iconsax.warning_2, size: 36, color: Colors.redAccent.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 20),
          Text('Failed to load syllabus',
              style: TextStyle(color: _textP(isDark), fontSize: 17, fontWeight: FontWeight.w600)),
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
                  Text('Retry', style: TextStyle(color: accent, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
