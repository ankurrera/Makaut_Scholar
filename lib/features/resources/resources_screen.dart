import 'package:flutter/material.dart';
import '../../core/widgets/modern_folder.dart';
import '../../services/offline_service.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'category_downloads_screen.dart';

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1115) : const Color(0xFFF4F5F7),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resources',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Access your downloaded offline files',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? const Color(0xFF9AA0A6) : const Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _CategoryTile(
                    label: 'Notes',
                    category: ResourceCategory.NOTES,
                    color: const Color(0xFF8B7CF6),
                    icon: Iconsax.note_text,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _CategoryTile(
                    label: 'Syllabus',
                    category: ResourceCategory.SYLLABUS,
                    color: const Color(0xFF34A875),
                    icon: Iconsax.document_text_1,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _CategoryTile(
                    label: 'PYQ Bank',
                    category: ResourceCategory.PYQ,
                    color: const Color(0xFF5BAAEF),
                    icon: Iconsax.archive_book,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _CategoryTile(
                    label: 'Exam Focus',
                    category: ResourceCategory.EXAM_FOCUS,
                    color: const Color(0xFFFF708D),
                    icon: Iconsax.flash,
                    isDark: isDark,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String label;
  final ResourceCategory category;
  final Color color;
  final IconData icon;
  final bool isDark;

  const _CategoryTile({
    required this.label,
    required this.category,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CategoryDownloadsScreen(
                title: label,
                category: category,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF171A21) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF2A2F3A) : const Color(0xFFE6E8EC),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                height: 52,
                child: ModernFolder(
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                      ),
                    ),
                    Text(
                      'View Offline',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF9AA0A6) : const Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Iconsax.arrow_right_3, size: 18, color: color.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
