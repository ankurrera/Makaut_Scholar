import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../providers/theme_provider.dart';
import '../../core/widgets/shimmer_skeleton.dart';
import '../../core/widgets/dot_loading.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _collegeController = TextEditingController();
  String? _selectedDepartment;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final List<String> _departments = ['CSE', 'ECE', 'ME', 'CE', 'EE', 'IT'];
  final _picker = ImagePicker();

  // ── Palette ──
  static const _accentLight = Color(0xFFE5252A);
  static const _accentDark = Color(0xFFE5252A);

  Color _bg(bool d) => d ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
  Color _card(bool d) => d ? const Color(0xFF111111) : const Color(0xFFF5F5F5);
  Color _textP(bool d) => d ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
  Color _textS(bool d) => d ? const Color(0xFF999999) : const Color(0xFF666666);
  Color _border(bool d) =>
      d ? const Color(0xFF222222) : const Color(0xFFE0E0E0);
  Color _accent(bool d) => d ? _accentDark : _accentLight;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final profile = await authService.getProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _isLoading = false;
        if (profile != null) {
          _nameController.text = profile['name'] ?? '';
          _collegeController.text = profile['college_name'] ?? '';
          _selectedDepartment = profile['department'];
        }
      });
      _animController.forward();
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await Provider.of<AuthService>(context, listen: false).updateProfile(
        name: _nameController.text.trim(),
        collegeName: _collegeController.text.trim(),
        department: _selectedDepartment ?? '',
      );
      await _loadProfile();
      if (mounted) {
        setState(() => _isEditing = false);
        _showSnack('Profile updated successfully', isSuccess: true);
      }
    } catch (e) {
      if (mounted) _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          _PhotoSourceSheet(isDark: isDark, accent: _accent(isDark)),
    );
    if (source == null) return;

    final picked = await _picker.pickImage(
        source: source, maxWidth: 512, maxHeight: 512, imageQuality: 80);
    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      if (!mounted) return;
      await Provider.of<AuthService>(context, listen: false)
          .uploadAvatar(picked.path);
      await _loadProfile();
      if (mounted) _showSnack('Photo updated', isSuccess: true);
    } catch (e) {
      if (mounted) _showSnack('Upload failed: $e');
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _removePhoto() async {
    setState(() => _isUploadingPhoto = true);
    try {
      await Provider.of<AuthService>(context, listen: false).deleteAvatar();
      await _loadProfile();
      if (mounted) _showSnack('Photo removed', isSuccess: true);
    } catch (e) {
      if (mounted) _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _signOut() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _SignOutDialog(isDark: isDark),
    );
    if (confirmed == true && mounted) {
      await Provider.of<AuthService>(context, listen: false).signOut();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _deleteAccount() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _DeleteAccountDialog(isDark: isDark),
    );

    if (confirmed == true && mounted) {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ShimmerSkeleton(width: 64, height: 64, borderRadius: BorderRadius.all(Radius.circular(32))),
                const SizedBox(height: 20),
                Text('DELETING ACCOUNT',
                    style: TextStyle(
                        fontFamily: 'NDOT',
                        color: _textP(isDark),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0)),
              ],
            ),
          ),
        ),
      );

      try {
        await Provider.of<AuthService>(context, listen: false).deleteAccount();
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          Navigator.pushReplacementNamed(context, '/login');
          _showSnack(
              'Account deleted successfully. We\'re sorry to see you go.',
              isSuccess: true);
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          _showSnack('Deletion failed: $e');
        }
      }
    }
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w500)),
      backgroundColor: isSuccess
          ? _accent(Theme.of(context).brightness == Brightness.dark)
          : Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ));
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _collegeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _accent(isDark);
    final email =
        Provider.of<AuthService>(context, listen: false).currentUser?.email ??
            '';

    return Scaffold(
      body: _isLoading && _profile == null
          ? _buildLoadingSkeleton(isDark)
          : CustomScrollView(
              slivers: [
                // ── Header ──
                SliverAppBar(
                  expandedHeight: 340,
                  pinned: true,
                  stretch: true,
                  backgroundColor: _bg(isDark),
                  leading: Navigator.canPop(context)
                      ? IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.black : Colors.white)
                                  .withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Iconsax.arrow_left,
                                color: _textP(isDark), size: 20),
                          ),
                          onPressed: () => Navigator.pop(context),
                        )
                      : null,
                  actions: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.black : Colors.white)
                              .withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isEditing ? Iconsax.close_circle : Iconsax.edit_2,
                          color: accent,
                          size: 20,
                        ),
                      ),
                      onPressed: () => setState(() {
                        _isEditing = !_isEditing;
                        if (!_isEditing && _profile != null) {
                          _nameController.text = _profile!['name'] ?? '';
                          _collegeController.text =
                              _profile!['college_name'] ?? '';
                          _selectedDepartment = _profile!['department'];
                        }
                      }),
                    ),
                    const SizedBox(width: 8),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildHeaderBackground(isDark, accent),
                  ),
                ),

                // ── Body ──
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _isEditing
                              ? _buildEditForm(isDark, accent)
                              : _buildDetailSection(isDark, accent, email),
                          const SizedBox(height: 24),
                          _buildSettingsSection(isDark, accent),
                          const SizedBox(height: 24),
                          _buildSignOutButton(isDark),
                          const SizedBox(height: 16),
                          _buildDeleteAccountButton(isDark),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ──────────────────────────── HEADER ────────────────────────────
  Widget _buildHeaderBackground(bool isDark, Color accent) {
    final avatarUrl = _profile?['avatar_url'] as String?;
    final name = _profile?['name'] ?? 'Scholar';
    final dept = _profile?['department'] as String?;
    final hasPhoto = avatarUrl != null && avatarUrl.isNotEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Consistent brand gradient fallback ──
        _coverFallback(name, isDark),

        // ── Bottom gradient scrim ──
        Positioned(
          left: 0, right: 0, bottom: 0,
          height: 200,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.5),
                  Colors.black.withValues(alpha: 0.85),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        // ── Bottom-left: avatar + info ──
        Positioned(
          left: 20,
          bottom: 20,
          right: 20,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // ── Square avatar with email badge at its bottom-left ──
              Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                    onLongPress: hasPhoto ? _removePhoto : null,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 2,
                        ),
                        color: isDark ? const Color(0xFF1C1C1E) : Colors.grey[300],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: hasPhoto
                            ? Image.network(avatarUrl!, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _avatarFallback(name))
                            : _avatarFallback(name),
                      ),
                    ),
                  ),
                  // ── Camera badge ──
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: const Icon(Iconsax.camera, size: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // ── Name + dept ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'NDOT',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (dept != null && dept.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22)),
                        ),
                        child: Text(
                          dept,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'NDOT',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Small avatar fallback (used inside the 80x80 square avatar)
  Widget _avatarFallback(String name) {
    return Container(
      color: const Color(0xFF1C1C1E),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'S',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white54,
          ),
        ),
      ),
    );
  }

  /// Full-bleed gradient fallback when no photo is set
  Widget _coverFallback(String name, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF33080A),
                  const Color(0xFF1A0505),
                  const Color(0xFF000000)
                ]
              : [
                  const Color(0xFFff6b6b),
                  const Color(0xFFE5252A),
                  const Color(0xFFcccccc)
                ],
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'S',
          style: TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────── DETAILS VIEW ────────────────────────────
  Widget _buildDetailSection(bool isDark, Color accent, String email) {
    return _GlassCard(
      color: _card(isDark),
      borderColor: _border(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Center(
              child: Text(
                'PERSONAL INFORMATION',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NDOT',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _textP(isDark),
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          _detailRow(Iconsax.personalcard, 'Full Name', _profile?['name'] ?? '—',
              isDark, accent),
          _divider(isDark),
          _detailRow(Iconsax.sms, 'Email', email, isDark, accent),
          _divider(isDark),
          _detailRow(Iconsax.building_3, 'College',
              _profile?['college_name'] ?? '—', isDark, accent),
          _divider(isDark),
          _detailRow(Iconsax.category, 'Department',
              _profile?['department'] ?? '—', isDark, accent),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _detailRow(
      IconData icon, String label, String value, bool isDark, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontFamily: 'NDOT',
                        fontSize: 11,
                        color: _textS(isDark),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontFamily: 'NDOT',
                        fontSize: 16,
                        color: _textP(isDark),
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) => Divider(
      height: 1, indent: 72, color: _border(isDark).withValues(alpha: 0.35));

  // ──────────────────────────── EDIT FORM ────────────────────────────
  Widget _buildEditForm(bool isDark, Color accent) {
    return _GlassCard(
      color: _card(isDark),
      borderColor: _border(isDark),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'EDIT PROFILE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'NDOT',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textP(isDark),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _field(_nameController, 'Full Name', Iconsax.user, isDark, accent,
                  validator: (v) => v!.isEmpty ? 'Name is required' : null),
              const SizedBox(height: 14),
              _field(_collegeController, 'College Name', Iconsax.teacher,
                  isDark, accent),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedDepartment,
                dropdownColor: _card(isDark),
                style: TextStyle(color: _textP(isDark), fontSize: 14),
                icon:
                    Icon(Iconsax.arrow_down_1, color: _textS(isDark), size: 16),
                decoration:
                    _inputDeco('Department', Iconsax.book_1, isDark, accent),
                items: _departments
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedDepartment = v),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ))
                      : const Text('SAVE CHANGES',
                          style: TextStyle(
                              fontFamily: 'NDOT',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      bool isDark, Color accent,
      {TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      style: TextStyle(color: _textP(isDark), fontSize: 14),
      keyboardType: keyboardType,
      decoration: _inputDeco(label, icon, isDark, accent),
      validator: validator,
    );
  }

  InputDecoration _inputDeco(
      String label, IconData icon, bool isDark, Color accent) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _textS(isDark), fontSize: 13),
      prefixIcon: Icon(icon, color: _textS(isDark), size: 18),
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.black.withValues(alpha: 0.02),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _border(isDark)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _border(isDark).withValues(alpha: 0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: accent, width: 1.5),
      ),
    );
  }

  // ──────────────────────────── SETTINGS ────────────────────────────
  Widget _buildSettingsSection(bool isDark, Color accent) {
    return _GlassCard(
      color: _card(isDark),
      borderColor: _border(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Center(
              child: Text(
                'PREFERENCES',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NDOT',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _textP(isDark),
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),

          _settingsTile(
              Iconsax.notification_bing, 'Notifications', 'Enabled', isDark, accent),
          _divider(isDark),
          // ── Appearance Selection ────────────────────────────────────────
          _settingsTile(
            Iconsax.paintbucket,
            'Appearance',
            _themeModeLabel(context),
            isDark,
            accent,
            onTap: () => _showThemeSelection(context),
          ),
          _divider(isDark),
          _settingsTile(Iconsax.code_circle, 'About', 'v1.0.0', isDark, accent,
              onTap: () => Navigator.pushNamed(context, '/about')),
          _divider(isDark),
          _settingsTile(
              Iconsax.document_text, 'Privacy Policy', 'View', isDark, accent,
              onTap: () => Navigator.pushNamed(context, '/privacy')),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _settingsTile(
      IconData icon, String title, String subtitle, bool isDark, Color accent,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: accent, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontFamily: 'NDOT',
                          fontSize: 16,
                          color: _textP(isDark),
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontFamily: 'NDOT',
                          fontSize: 12,
                          color: _textS(isDark))),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Iconsax.arrow_right_3, size: 16, color: _textS(isDark)),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────── SIGN OUT ────────────────────────────
  Widget _buildSignOutButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _signOut,
        icon: const Icon(Iconsax.logout, size: 18, color: Colors.redAccent),
        label: const Text(
          'SIGN OUT',
          style: TextStyle(
              fontFamily: 'NDOT',
              color: Colors.redAccent,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.25)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  // ──────────────────────────── DELETE ACCOUNT ────────────────────────────
  Widget _buildDeleteAccountButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: _deleteAccount,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.25)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: const Text(
          'DELETE MY ACCOUNT',
          style: TextStyle(
            fontFamily: 'NDOT',
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            // removed underline for professional look
          ),
        ),
      ),
    );
  }

  // Helper to get label for current theme mode
  String _themeModeLabel(BuildContext context) {
    final mode = Provider.of<ThemeProvider>(context, listen: false).themeMode;
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      default:
        return 'System';
    }
  }

  // Show bottom sheet to select theme mode
  void _showThemeSelection(BuildContext context) {
    final provider = Provider.of<ThemeProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        ThemeMode selected = provider.themeMode;
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: ThemeMode.values.map((mode) {
                  String label;
                  switch (mode) {
                    case ThemeMode.light:
                      label = 'Light';
                      break;
                    case ThemeMode.dark:
                      label = 'Dark';
                      break;
                    default:
                      label = 'System';
                  }
                  return RadioListTile<ThemeMode>(
                    title: Text(label),
                    value: mode,
                    groupValue: selected,
                    onChanged: (value) {
                      if (value != null) {
                        provider.setThemeMode(value);
                        setState(() => selected = value);
                        Navigator.of(context).pop();
                      }
                    },
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingSkeleton(bool isDark) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 340,
          pinned: true,
          backgroundColor: _bg(isDark),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [const Color(0xFF33080A), const Color(0xFF1A0505), const Color(0xFF000000)]
                          : [const Color(0xFFff6b6b), const Color(0xFFE5252A), const Color(0xFFcccccc)],
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  bottom: 20,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ShimmerSkeleton(width: 80, height: 80, borderRadius: BorderRadius.circular(16)),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const ShimmerSkeleton(width: 150, height: 24),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const ShimmerSkeleton(width: 60, height: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF111111) : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: List.generate(4, (index) => ShimmerSkeleton.listTile(isDark: isDark)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────── REUSABLE GLASS CARD ──────────────────────────
class _GlassCard extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final Widget child;

  const _GlassCard({
    required this.color,
    required this.borderColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }
}

// ────────────────────────── PHOTO SOURCE SHEET ──────────────────────────
class _PhotoSourceSheet extends StatelessWidget {
  final bool isDark;
  final Color accent;

  const _PhotoSourceSheet({required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2028) : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              )),
          const SizedBox(height: 20),
          Text('Change Photo',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFFF5F6FA)
                      : const Color(0xFF1E1E1E))),
          const SizedBox(height: 16),
          _sheetOption(context, Iconsax.camera, 'Take Photo',
              ImageSource.camera, isDark),
          _sheetOption(context, Iconsax.gallery, 'Choose from Gallery',
              ImageSource.gallery, isDark),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _sheetOption(BuildContext context, IconData icon, String label,
      ImageSource source, bool isDark) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: accent, size: 20),
      ),
      title: Text(label,
          style: TextStyle(
            color: isDark ? const Color(0xFFF5F6FA) : const Color(0xFF1E1E1E),
            fontWeight: FontWeight.w500,
          )),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onTap: () => Navigator.pop(context, source),
    );
  }
}

// ────────────────────────── SIGN OUT DIALOG ──────────────────────────
class _SignOutDialog extends StatelessWidget {
  final bool isDark;

  const _SignOutDialog({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1C2028) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text('Sign Out',
          style: TextStyle(
              color: isDark ? const Color(0xFFF5F6FA) : const Color(0xFF1E1E1E),
              fontWeight: FontWeight.w600)),
      content: Text(
        'Are you sure you want to sign out?',
        style: TextStyle(
            color: isDark ? const Color(0xFF9AA0A6) : const Color(0xFF8E8E93)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel',
              style: TextStyle(
                  color: isDark
                      ? const Color(0xFF9AA0A6)
                      : const Color(0xFF8E8E93))),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(
            backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Sign Out',
              style: TextStyle(
                  color: Colors.redAccent, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

// ────────────────────────── DELETE ACCOUNT DIALOG ──────────────────────────
class _DeleteAccountDialog extends StatelessWidget {
  final bool isDark;

  const _DeleteAccountDialog({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDark ? const Color(0xFFF5F6FA) : const Color(0xFF1E1E1E);

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1C2028) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Row(
        children: [
          const Icon(Iconsax.danger, color: Colors.redAccent, size: 24),
          const SizedBox(width: 12),
          Text('Delete Account?',
              style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This action is permanent and cannot be undone.',
            style: TextStyle(
                color: textColor, fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Text(
            '• All your personal data will be erased.\n'
            '• You will lose access to all premium content.\n'
            '• Your purchase history will be deleted.',
            style: TextStyle(
              color: isDark ? const Color(0xFF9AA0A6) : const Color(0xFF8E8E93),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Keep Account',
              style: TextStyle(
                  color: isDark
                      ? const Color(0xFF9AA0A6)
                      : const Color(0xFF8E8E93))),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: const Text('Delete permanently',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ],
    );
  }
}
