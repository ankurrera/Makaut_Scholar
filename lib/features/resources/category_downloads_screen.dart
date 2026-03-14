import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../services/offline_service.dart';
import '../../core/widgets/solid_folder.dart';
import '../notes/pdf_viewer_screen.dart';

class CategoryDownloadsScreen extends StatefulWidget {
  final String title;
  final ResourceCategory category;

  const CategoryDownloadsScreen({
    super.key,
    required this.title,
    required this.category,
  });

  @override
  State<CategoryDownloadsScreen> createState() =>
      _CategoryDownloadsScreenState();
}

class _CategoryDownloadsScreenState extends State<CategoryDownloadsScreen> {
  List<OfflineResource> _downloads = [];

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  void _loadDownloads() {
    setState(() {
      _downloads = OfflineService().getByCategory(widget.category);
    });
  }

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF1C1C1E) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: isDark
                                  ? const Color(0xFF2C2C2E)
                                  : const Color(0xFFF2F2F2)),
                        ),
                        child: Icon(Iconsax.arrow_left,
                            size: 20,
                            color: isDark ? Colors.white : Colors.black),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.title.toUpperCase(),
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
                      'Manage your local ${_downloads.length} file${_downloads.length == 1 ? '' : 's'}',
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
            if (_downloads.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Iconsax.document_copy,
                        size: 48,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.1),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No offline files here',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white54 : Colors.black45),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _DownloadTile(
                      resource: _downloads[i],
                      isDark: isDark,
                      onDelete: () async {
                        await OfflineService().removeDownload(_downloads[i].id);
                        _loadDownloads();
                      },
                    ),
                    childCount: _downloads.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DownloadTile extends StatelessWidget {
  final OfflineResource resource;
  final bool isDark;
  final VoidCallback onDelete;

  const _DownloadTile({
    required this.resource,
    required this.isDark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tileBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final tileBorder = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F2);
    final folderClr = isDark ? Colors.white : const Color(0xFFF2F0EF);
    final folderBorder = isDark ? Colors.transparent : const Color(0xFFE5E5EA);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PdfViewerScreen(
                  filePath: resource.localPath,
                  title: resource.title,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resource.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                          letterSpacing: -0.2,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Offline · ${resource.downloadedAt.day}/${resource.downloadedAt.month}/${resource.downloadedAt.year}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white54 : Colors.black54),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Iconsax.trash, color: Colors.redAccent, size: 20),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: Text('DELETE FILE', style: TextStyle(fontFamily: 'NDOT', fontSize: 18, color: isDark ? Colors.white : Colors.black)),
                        content: Text('Are you sure you want to remove this file from offline storage?', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('CANCEL', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54))),
                          TextButton(onPressed: () { Navigator.pop(ctx); onDelete(); }, child: const Text('DELETE', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
