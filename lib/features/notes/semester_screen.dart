import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/widgets/solid_folder.dart';
import '../../services/auth_service.dart';
import 'subject_screen.dart';

class SemesterScreen extends StatefulWidget {
  final String department;
  const SemesterScreen({super.key, required this.department});

  @override
  State<SemesterScreen> createState() => _SemesterScreenState();
}

class _SemesterScreenState extends State<SemesterScreen>
    with SingleTickerProviderStateMixin {
  late String _userDepartment;

  static const _accentLight = Color(0xFF111111);
  static const _accentDark = Colors.white;

  Color _bg(bool d) => d ? Colors.black : const Color(0xFFF8F6F1);
  Color _card(bool d) => d ? const Color(0xFF1C1C1E) : Colors.white;
  Color _textP(bool d) => d ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
  Color _textS(bool d) => d ? const Color(0xFF999999) : const Color(0xFF666666);
  Color _accent(bool d) => d ? _accentDark : _accentLight;

  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _userDepartment = widget.department;
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadDepartment();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _loadDepartment() async {
    try {
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
      if (mounted) {
        _staggerController.forward(from: 0);
      }
    } catch (e) {
      debugPrint('Error loading profile department: $e');
      if (mounted) _staggerController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _accent(isDark);

    return Scaffold(
      backgroundColor: _bg(isDark),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverAppBar(
            backgroundColor: _bg(isDark),
            elevation: 0,
            scrolledUnderElevation: 0,
            pinned: true,
            expandedHeight:
                MediaQuery.of(context).padding.top + kToolbarHeight + 80,
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
                    MediaQuery.of(context).padding.top + kToolbarHeight + 8,
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
                          color: isDark
                              ? const Color(0xFF2C2C2E)
                              : const Color(0xFFE6E8EC),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _userDepartment,
                          style: TextStyle(
                              color: _textS(isDark),
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Academic Notes',
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
                      'Lecture notes & study material',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: _textS(isDark), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            sliver: SliverList.builder(
              itemCount: 8,
              itemBuilder: (context, i) {
                final sem = i + 1;
                final interval = Interval(
                  (i * 0.1).clamp(0.0, 0.5),
                  ((i * 0.1) + 0.5).clamp(0.0, 1.0),
                  curve: Curves.easeOutCubic,
                );
                return AnimatedBuilder(
                  animation: _staggerController,
                  builder: (context, child) {
                    final v = interval.transform(_staggerController.value);
                    return Transform.translate(
                      offset: Offset(0, 24 * (1 - v)),
                      child: Opacity(opacity: v, child: child),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SubjectScreen(
                                department: _userDepartment, semester: sem),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1C1C1E)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF2C2C2E)
                                  : const Color(0xFFE6E8EC),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 64,
                                height: 52,
                                child: SolidFolder(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFFF2F0EF),
                                  borderColor: isDark
                                      ? Colors.transparent
                                      : const Color(0xFFE5E5EA),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Semester $sem',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1E1E1E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
