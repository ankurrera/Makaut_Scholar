import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../services/auth_service.dart';
import 'subject_screen.dart';

class SemesterScreen extends StatefulWidget {
  final String department;
  const SemesterScreen({super.key, required this.department});

  @override
  State<SemesterScreen> createState() => _SemesterScreenState();
}

class _SemesterScreenState extends State<SemesterScreen> {
  late String _userDepartment;

  static const _accentLight = Color(0xFF7C6FF6);
  static const _accentDark = Color(0xFF8E82FF);

  Color _bg(bool d) => d ? const Color(0xFF0F1115) : const Color(0xFFF4F5F7);
  Color _textP(bool d) => d ? const Color(0xFFF5F6FA) : const Color(0xFF1E1E1E);
  Color _textS(bool d) => d ? const Color(0xFF9AA0A6) : const Color(0xFF8E8E93);
  Color _accent(bool d) => d ? _accentDark : _accentLight;

  // Each entry: [body, tab/back, bar]
  static const _colors = [
    [Color(0xFF7B6EF6), Color(0xFFB3ADFF), Color(0xFF6358E0)], // purple
    [Color(0xFF5BAAEF), Color(0xFFA3D4FF), Color(0xFF4494DB)], // blue
    [Color(0xFF4FC9A8), Color(0xFF96E8D4), Color(0xFF3BB393)], // mint
    [Color(0xFFF28BAA), Color(0xFFFFBFD0), Color(0xFFDB7494)], // pink
    [Color(0xFFF5B556), Color(0xFFFFD99A), Color(0xFFDB9D3E)], // amber
    [Color(0xFF4FD1B0), Color(0xFF96E8D4), Color(0xFF3ABB9A)], // teal
    [Color(0xFFA78BFA), Color(0xFFCFC0FF), Color(0xFF8F73E6)], // lavender
    [Color(0xFFEF7B7B), Color(0xFFFFB3B3), Color(0xFFD8636B)], // coral
  ];

  @override
  void initState() {
    super.initState();
    _userDepartment = widget.department;
    _loadDepartment();
  }

  Future<void> _loadDepartment() async {
    try {
      // Use a short delay to ensure context is available if needed,
      // though Provider access in initState/didChangeDependencies is standard.
      // We'll access Provider here.
      final auth = Provider.of<AuthService>(context, listen: false);
      final profile = await auth.getProfile();
      final profileDept = profile?['department'] as String?;
      
      if (profileDept != null && profileDept.isNotEmpty) {
        if (mounted) {
          setState(() {
            _userDepartment = profileDept;
          });
        }
      }
    } catch (e) {
      // Cleanly fail and stick with widget.department
      debugPrint('Error loading profile department: $e');
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
            Text('Academic Notes',
                style: TextStyle(color: _textP(isDark), fontSize: 18, fontWeight: FontWeight.w600)),
            Text(_userDepartment,
                style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Semester',
                style: TextStyle(color: _textS(isDark), fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                itemCount: 8,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.92,
                ),
                itemBuilder: (context, i) {
                  final sem = i + 1;
                  final pal = _colors[i];

                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SubjectScreen(department: _userDepartment, semester: sem),
                      ),
                    ),
                    child: _SemesterTile(
                      bodyColor: pal[0],
                      backColor: pal[1],
                      barColor: pal[2],
                      semester: sem,
                      isDark: isDark,
                      textP: _textP(isDark),
                      textS: _textS(isDark),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SemesterTile extends StatelessWidget {
  final Color bodyColor;
  final Color backColor;
  final Color barColor;
  final int semester;
  final bool isDark;
  final Color textP;
  final Color textS;

  const _SemesterTile({
    required this.bodyColor,
    required this.backColor,
    required this.barColor,
    required this.semester,
    required this.isDark,
    required this.textP,
    required this.textS,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171A21) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── 3D Folder Icon ──
          SizedBox(
            width: 80,
            height: 68,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Back panel with tab
                Positioned(
                  top: 0,
                  left: 4,
                  right: 4,
                  bottom: 6,
                  child: CustomPaint(
                    painter: _FolderBackPainter(color: backColor),
                  ),
                ),
                // Front body
                Positioned(
                  top: 14,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: bodyColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      // Horizontal bar
                      child: Container(
                        width: 30,
                        height: 5,
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Label
          Text(
            'Semester $semester',
            style: TextStyle(
              color: textP,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints the back panel of the folder with a tab on the top-right
class _FolderBackPainter extends CustomPainter {
  final Color color;
  _FolderBackPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final w = size.width;
    final h = size.height;
    const r = 10.0; // corner radius
    const tabW = 28.0;
    const tabH = 12.0;
    const tabR = 7.0;

    final path = Path();

    // Start at top-left rounded corner (of main back body, starting below tab area)
    path.moveTo(0, tabH + r);
    path.quadraticBezierTo(0, tabH, r, tabH);

    // Bottom edge of tab area — go to tab start
    path.lineTo(w - tabW - tabR, tabH);

    // Curve up into tab
    path.quadraticBezierTo(w - tabW, tabH, w - tabW, tabH - tabR);
    path.lineTo(w - tabW, tabR);
    path.quadraticBezierTo(w - tabW, 0, w - tabW + tabR, 0);

    // Tab top
    path.lineTo(w - tabR, 0);
    path.quadraticBezierTo(w, 0, w, tabR);

    // Right side down
    path.lineTo(w, h - r);
    path.quadraticBezierTo(w, h, w - r, h);

    // Bottom
    path.lineTo(r, h);
    path.quadraticBezierTo(0, h, 0, h - r);

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FolderBackPainter old) => old.color != color;
}
