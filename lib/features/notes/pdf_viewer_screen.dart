import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class PdfViewerScreen extends StatefulWidget {
  final String? url;
  final String? filePath;
  final String title;
  
  const PdfViewerScreen({
    super.key, 
    this.url, 
    this.filePath,
    required this.title,
  }) : assert(url != null || filePath != null);

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  late PdfViewerController _pdfController;
  int _totalPages = 0;
  int _currentPage = 0;
  bool _hasError = false;

  // ── Palette ──
  Color _bg(bool d) => d ? const Color(0xFF0F1115) : const Color(0xFFF4F5F7);
  Color _textP(bool d) => d ? const Color(0xFFF5F6FA) : const Color(0xFF1E1E1E);
  Color _textS(bool d) => d ? const Color(0xFF9AA0A6) : const Color(0xFF8E8E93);
  Color _accent(bool d) => d ? const Color(0xFF8E82FF) : const Color(0xFF7C6FF6);

  static const _secureChannel = MethodChannel('com.makaut_scholar/screen_security');

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    _enableSecure();
  }

  @override
  void dispose() {
    _disableSecure();
    _pdfController.dispose();
    super.dispose();
  }

  Future<void> _enableSecure() async {
    try { await _secureChannel.invokeMethod('enableSecure'); } catch (_) {}
  }

  Future<void> _disableSecure() async {
    try { await _secureChannel.invokeMethod('disableSecure'); } catch (_) {}
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
        title: Text(
          widget.title,
          style: TextStyle(color: _textP(isDark), fontSize: 16, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        actions: [
          if (_totalPages > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_currentPage} / $_totalPages',
                    style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _hasError
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.warning_2, size: 44, color: Colors.redAccent.withValues(alpha: 0.6)),
                  const SizedBox(height: 14),
                  Text('Failed to load PDF',
                      style: TextStyle(color: _textP(isDark), fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => setState(() => _hasError = false),
                    icon: Icon(Iconsax.refresh, size: 16, color: accent),
                    label: Text('Retry', style: TextStyle(color: accent, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            )
          : widget.filePath != null 
            ? SfPdfViewer.file(
                File(widget.filePath!),
                key: _pdfViewerKey,
                controller: _pdfController,
                canShowScrollHead: true,
                onDocumentLoaded: (details) {
                  if (mounted) {
                    setState(() {
                      _totalPages = details.document.pages.count;
                      _currentPage = 1;
                    });
                  }
                },
                onPageChanged: (details) {
                  if (mounted) setState(() => _currentPage = details.newPageNumber);
                },
                onDocumentLoadFailed: (details) {
                  if (mounted) setState(() => _hasError = true);
                },
              )
            : SfPdfViewer.network(
                widget.url!,
                key: _pdfViewerKey,
                controller: _pdfController,
                canShowScrollHead: true,
                onDocumentLoaded: (details) {
                  if (mounted) {
                    setState(() {
                      _totalPages = details.document.pages.count;
                      _currentPage = 1;
                    });
                  }
                },
                onPageChanged: (details) {
                  if (mounted) setState(() => _currentPage = details.newPageNumber);
                },
                onDocumentLoadFailed: (details) {
                  debugPrint('PDF Load Failed: ${details.error}');
                  debugPrint('Raw URL: ${widget.url}');
                  if (mounted) setState(() => _hasError = true);
                },
              ),
    );
  }
}
