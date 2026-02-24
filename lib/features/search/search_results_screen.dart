import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../services/search_service.dart';
import '../../core/models/search_result.dart';
import '../notes/notes_viewer_screen.dart';
import '../pyq/pyq_papers_screen.dart';
import '../syllabus/syllabus_semester_screen.dart'; // Just a placeholder for now

class SearchResultsScreen extends StatefulWidget {
  final String initialQuery;
  final String initialFilter;
  final String department;

  const SearchResultsScreen({
    super.key,
    required this.initialQuery,
    required this.initialFilter,
    required this.department,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final SearchService _searchService = SearchService();
  final TextEditingController _searchController = TextEditingController();
  List<SearchResult> _results = [];
  bool _isLoading = false;
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Notes', 'Syllabus', 'PYQs', 'Important'];

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;
    _selectedFilter = widget.initialFilter;
    _performSearch();
  }

  Future<void> _performSearch() async {
    if (_searchController.text.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final results = await _searchService.search(
        query: _searchController.text,
        department: widget.department,
        filter: _selectedFilter,
      );
      if (mounted) setState(() => _results = results);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToResult(SearchResult result) {
    Widget target;
    switch (result.type) {
      case SearchResultType.notes:
        target = NotesViewerScreen(
          department: result.department,
          semester: result.semester,
          subject: result.subject,
        );
        break;
      case SearchResultType.pyq:
        target = PyqPapersScreen(
          department: result.department,
          semester: result.semester,
          subject: result.subject,
        );
        break;
      case SearchResultType.syllabus:
        // Syllabus navigation usually goes to a list, we can show specific PDF if we had a direct viewer
        // For now, let's just go up or show a snackbar if not fully implemented
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening Syllabus for ${result.subject}...'))
        );
        return;
      case SearchResultType.important:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening Important Questions for ${result.subject}...'))
        );
        return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => target));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // --- Palette ---
    final Color bg = isDark ? const Color(0xFF0F1115) : const Color(0xFFF4F5F7);
    final Color card = isDark ? const Color(0xFF171A21) : Colors.white;
    final Color textP = isDark ? const Color(0xFFF5F6FA) : const Color(0xFF1E1E1E);
    final Color textS = isDark ? const Color(0xFF9AA0A6) : const Color(0xFF8E8E93);
    final Color accent = const Color(0xFF7C6FF6);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // --- Header & Search ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                   IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Iconsax.arrow_left_2, color: textP),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Hero(
                          tag: 'search_bar_hero',
                          child: Material(
                            type: MaterialType.transparency,
                            child: Container(
                              decoration: BoxDecoration(
                                color: card,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.black.withValues(alpha: 0.05)),
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (_) => _performSearch(),
                                autofocus: true,
                                style: TextStyle(color: textP, fontSize: 16),
                                decoration: InputDecoration(
                                  hintText: 'Search...',
                                  hintStyle: TextStyle(color: textS),
                                  border: InputBorder.none,
                                  prefixIcon: Icon(Iconsax.search_normal_1,
                                      color: textS, size: 20),
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            'Searching in ${widget.department}',
                            style: TextStyle(
                              color: accent.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- Filter Tags ---
            SizedBox(
              height: 40,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedFilter = filter);
                        _performSearch();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? accent : card,
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected ? null : Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            color: isSelected ? Colors.white : textS,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // --- Results ---
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C6FF6)))
                : _results.isEmpty 
                  ? _buildEmptyState(textS, textP)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final result = _results[index];
                        return _buildResultTile(result, card, textP, textS, accent);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultTile(SearchResult result, Color cardColor, Color textP, Color textS, Color accent) {
    IconData icon;
    Color iconBg;

    switch (result.type) {
      case SearchResultType.notes:
        icon = Iconsax.book;
        iconBg = const Color(0xFFE8E4FF);
        break;
      case SearchResultType.pyq:
        icon = Iconsax.archive_book;
        iconBg = const Color(0xFFD9E6FF);
        break;
      case SearchResultType.syllabus:
        icon = Iconsax.document_text;
        iconBg = const Color(0xFFCDEBE7);
        break;
      case SearchResultType.important:
        icon = Iconsax.flash;
        iconBg = const Color(0xFFF4C7D7);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        onTap: () => _navigateToResult(result),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.black.withValues(alpha: 0.7), size: 22),
        ),
        title: Text(
          result.title,
          style: TextStyle(color: textP, fontWeight: FontWeight.bold, fontSize: 15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          result.subtitle,
          style: TextStyle(color: textS, fontSize: 13),
        ),
        trailing: Icon(Iconsax.arrow_right_3, color: textS, size: 18),
      ),
    );
  }

  Widget _buildEmptyState(Color textS, Color textP) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.search_status, size: 64, color: textS.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty ? 'Type to start searching' : 'No results found',
            style: TextStyle(color: textP, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your keywords or filters',
            style: TextStyle(color: textS, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
