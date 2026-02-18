import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../services/offline_service.dart';
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
  State<CategoryDownloadsScreen> createState() => _CategoryDownloadsScreenState();
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
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF171A21) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? const Color(0xFF2A2F3A) : const Color(0xFFE6E8EC)),
                        ),
                        child: Icon(Iconsax.arrow_left_2, size: 20, color: isDark ? Colors.white : Colors.black),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Manage your local ${_downloads.length} file${_downloads.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? const Color(0xFF9AA0A6) : const Color(0xFF8E8E93),
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
                      Icon(Iconsax.document_download, size: 48, color: isDark ? Colors.white24 : Colors.black12),
                      const SizedBox(height: 16),
                      Text(
                        'No offline files here',
                        style: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171A21) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF2A2F3A) : const Color(0xFFE6E8EC)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Iconsax.document_text_1, color: Theme.of(context).primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resource.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Downloaded on ${resource.downloadedAt.day}/${resource.downloadedAt.month}/${resource.downloadedAt.year}',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Iconsax.trash, color: Colors.redAccent, size: 20),
            onPressed: onDelete,
          ),
          IconButton(
            icon: Icon(Iconsax.arrow_right_3, color: isDark ? Colors.white24 : Colors.black12, size: 20),
            onPressed: () {
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
          ),
        ],
      ),
    );
  }
}
