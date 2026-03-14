import 'package:flutter/material.dart';
import '../../core/widgets/solid_folder.dart';
import '../../services/offline_service.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'category_downloads_screen.dart';

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121512) : const Color(0xFFF8F6F1),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'RESOURCES',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                        letterSpacing: 2.0,
                        fontFamily: 'NDOT',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Access your downloaded offline files',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFF9AA0A6)
                            : const Color(0xFF8E8E93),
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
                    label: 'NOTES',
                    category: ResourceCategory.NOTES,
                    color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                    icon: Iconsax.note_text,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),
                  _CategoryTile(
                    label: 'SYLLABUS',
                    category: ResourceCategory.SYLLABUS,
                    color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                    icon: Iconsax.document_text_1,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),
                  _CategoryTile(
                    label: 'PYQ BANK',
                    category: ResourceCategory.PYQ,
                    color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                    icon: Iconsax.archive_book,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),
                  _CategoryTile(
                    label: 'EXAM FOCUS',
                    category: ResourceCategory.EXAM_FOCUS,
                    color: isDark ? Colors.white : const Color(0xFF1E1E1E),
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
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                height: 48,
                child: SolidFolder(
                  color: isDark ? Colors.white : const Color(0xFFF2F0EF),
                  borderColor: isDark ? Colors.transparent : const Color(0xFFE5E5EA),
                  tabHeight: 8,
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
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'NDOT',
                        letterSpacing: 1.0,
                        color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'View Offline',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFF9AA0A6)
                            : const Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(Iconsax.arrow_right_3,
                    size: 16, color: isDark ? Colors.white54 : Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
