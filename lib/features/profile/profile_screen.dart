import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _collegeController = TextEditingController();
  String? _selectedDepartment;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final List<String> _departments = ['CSE', 'ECE', 'ME', 'CE', 'EE', 'IT'];
  final _picker = ImagePicker();

  // ── Palette ──
  static const _accentLight = Color(0xFF7C6FF6);
  static const _accentDark = Color(0xFF8E82FF);

  Color _bg(bool d) => d ? const Color(0xFF0F1115) : const Color(0xFFF4F5F7);
  Color _card(bool d) => d ? const Color(0xFF171A21) : Colors.white;
  Color _textP(bool d) => d ? const Color(0xFFF5F6FA) : const Color(0xFF1E1E1E);
  Color _textS(bool d) => d ? const Color(0xFF9AA0A6) : const Color(0xFF8E8E93);
  Color _border(bool d) => d ? const Color(0xFF2A2F3A) : const Color(0xFFE6E8EC);
  Color _accent(bool d) => d ? _accentDark : _accentLight;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
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
          _phoneController.text = profile['phone_number'] ?? '';
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
        phoneNumber: _phoneController.text.trim(),
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
      builder: (ctx) => _PhotoSourceSheet(isDark: isDark, accent: _accent(isDark)),
    );
    if (source == null) return;

    final picked = await _picker.pickImage(source: source, maxWidth: 512, maxHeight: 512, imageQuality: 80);
    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      if (!mounted) return;
      await Provider.of<AuthService>(context, listen: false).uploadAvatar(picked.path);
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
      setState(() => _isLoading = true);
      try {
        await Provider.of<AuthService>(context, listen: false).deleteAccount();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
          _showSnack('Account deleted successfully. We\'re sorry to see you go.', isSuccess: true);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showSnack('Deletion failed: $e');
        }
      }
    }
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      backgroundColor: isSuccess ? _accent(Theme.of(context).brightness == Brightness.dark) : Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ));
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _collegeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _accent(isDark);
    final email = Provider.of<AuthService>(context, listen: false).currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: _bg(isDark),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accent))
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
                              color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Iconsax.arrow_left, color: _textP(isDark), size: 20),
                          ),
                          onPressed: () => Navigator.pop(context),
                        )
                      : null,
                  actions: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.5),
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
                          _phoneController.text = _profile!['phone_number'] ?? '';
                          _collegeController.text = _profile!['college_name'] ?? '';
                          _selectedDepartment = _profile!['department'];
                        }
                      }),
                    ),
                    const SizedBox(width: 8),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildHeaderBackground(isDark, accent, email),
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
                              : _buildDetailSection(isDark, accent),
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
  Widget _buildHeaderBackground(bool isDark, Color accent, String email) {
    final avatarUrl = _profile?['avatar_url'] as String?;
    final name = _profile?['name'] ?? 'Scholar';
    final dept = _profile?['department'] as String?;
    final hasPhoto = avatarUrl != null && avatarUrl.isNotEmpty;

    return GestureDetector(
      onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
      onLongPress: hasPhoto ? _removePhoto : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Full-bleed cover image ──
          if (_isUploadingPhoto)
            Container(
              color: isDark ? const Color(0xFF171A21) : Colors.grey[200],
              child: Center(child: CircularProgressIndicator(color: accent, strokeWidth: 2.5)),
            )
          else if (hasPhoto)
            Image.network(
              avatarUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _coverFallback(name, isDark),
            )
          else
            _coverFallback(name, isDark),

          // ── Bottom gradient scrim for text readability ──
          Positioned(
            left: 0, right: 0, bottom: 0,
            height: 160,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // ── Overlaid user info ──
          Positioned(
            left: 24, right: 24, bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                    shadows: [Shadow(color: Colors.black26, blurRadius: 6)],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Iconsax.sms, size: 13, color: Colors.white70),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        email,
                        style: const TextStyle(fontSize: 13, color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (dept != null && dept.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      dept,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Camera edit button ──
          Positioned(
            bottom: 20,
            right: 20,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(12),

              ),
              child: const Icon(Iconsax.camera, size: 16, color: Colors.white),
            ),
          ),
        ],
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
              ? [const Color(0xFF2D1B69), const Color(0xFF1A1530), const Color(0xFF0F1115)]
              : [const Color(0xFF9F8FFF), const Color(0xFF7C6FF6), const Color(0xFFEDE9FE)],
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
  Widget _buildDetailSection(bool isDark, Color accent) {
    return _GlassCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Text(
              'PERSONAL INFORMATION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _textS(isDark),
                letterSpacing: 1.2,
              ),
            ),
          ),
          _detailRow(Iconsax.user, 'Full Name', _profile?['name'] ?? '—', isDark, accent),
          _divider(isDark),
          _detailRow(Iconsax.call, 'Phone', _profile?['phone_number'] ?? '—', isDark, accent),
          _divider(isDark),
          _detailRow(Iconsax.teacher, 'College', _profile?['college_name'] ?? '—', isDark, accent),
          _divider(isDark),
          _detailRow(Iconsax.book_1, 'Department', _profile?['department'] ?? '—', isDark, accent),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, bool isDark, Color accent) {
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
                Text(label, style: TextStyle(fontSize: 11, color: _textS(isDark), fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 15, color: _textP(isDark), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) => Divider(height: 1, indent: 72, color: _border(isDark).withValues(alpha: 0.35));

  // ──────────────────────────── EDIT FORM ────────────────────────────
  Widget _buildEditForm(bool isDark, Color accent) {
    return _GlassCard(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EDIT PROFILE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _textS(isDark),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 18),
              _field(_nameController, 'Full Name', Iconsax.user, isDark, accent,
                  validator: (v) => v!.isEmpty ? 'Name is required' : null),
              const SizedBox(height: 14),
              _field(_phoneController, 'Phone Number', Iconsax.call, isDark, accent,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 14),
              _field(_collegeController, 'College Name', Iconsax.teacher, isDark, accent),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _selectedDepartment,
                dropdownColor: _card(isDark),
                style: TextStyle(color: _textP(isDark), fontSize: 14),
                icon: Icon(Iconsax.arrow_down_1, color: _textS(isDark), size: 16),
                decoration: _inputDeco('Department', Iconsax.book_1, isDark, accent),
                items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Text('Save Changes',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon, bool isDark, Color accent,
      {TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      style: TextStyle(color: _textP(isDark), fontSize: 14),
      keyboardType: keyboardType,
      decoration: _inputDeco(label, icon, isDark, accent),
      validator: validator,
    );
  }

  InputDecoration _inputDeco(String label, IconData icon, bool isDark, Color accent) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _textS(isDark), fontSize: 13),
      prefixIcon: Icon(icon, color: _textS(isDark), size: 18),
      filled: true,
      fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
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
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Text(
              'PREFERENCES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _textS(isDark),
                letterSpacing: 1.2,
              ),
            ),
          ),
          _settingsTile(Iconsax.moon, 'Appearance', 'System default', isDark, accent),
          _divider(isDark),
          _settingsTile(Iconsax.notification, 'Notifications', 'Enabled', isDark, accent),
          _divider(isDark),
          _settingsTile(Iconsax.info_circle, 'About', 'v1.0.0', isDark, accent),
          _divider(isDark),
          _settingsTile(
            Iconsax.shield_tick,
            'Privacy Policy',
            'View',
            isDark,
            accent,
            onTap: () async {
              final url = Uri.parse('https://makaut-scholar.vercel.app/#privacy');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                _showSnack('Could not launch the Privacy Policy');
              }
            },
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _settingsTile(IconData icon, String title, String subtitle, bool isDark, Color accent, {VoidCallback? onTap}) {
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
              child: Text(title, style: TextStyle(fontSize: 15, color: _textP(isDark), fontWeight: FontWeight.w500)),
            ),
            Text(subtitle, style: TextStyle(fontSize: 13, color: _textS(isDark))),
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
          'Sign Out',
          style: TextStyle(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.w500),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.25)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  // ──────────────────────────── DELETE ACCOUNT ────────────────────────────
  Widget _buildDeleteAccountButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: TextButton(
        onPressed: _deleteAccount,
        style: TextButton.styleFrom(
          foregroundColor: Colors.redAccent.withValues(alpha: 0.7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: const Text(
          'Delete My Account permanently',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}

// ────────────────────────── REUSABLE GLASS CARD ──────────────────────────
class _GlassCard extends StatelessWidget {
  final bool isDark;
  final Widget child;

  const _GlassCard({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.04),
          width: 0.5,
        ),

      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
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
          Container(width: 36, height: 4, decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(2),
          )),
          const SizedBox(height: 20),
          Text('Change Photo',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFF5F6FA) : const Color(0xFF1E1E1E))),
          const SizedBox(height: 16),
          _sheetOption(context, Iconsax.camera, 'Take Photo', ImageSource.camera, isDark),
          _sheetOption(context, Iconsax.gallery, 'Choose from Gallery', ImageSource.gallery, isDark),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _sheetOption(BuildContext context, IconData icon, String label, ImageSource source, bool isDark) {
    return ListTile(
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: accent, size: 20),
      ),
      title: Text(label, style: TextStyle(
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
          style: TextStyle(color: isDark ? const Color(0xFFF5F6FA) : const Color(0xFF1E1E1E), fontWeight: FontWeight.w600)),
      content: Text(
        'Are you sure you want to sign out?',
        style: TextStyle(color: isDark ? const Color(0xFF9AA0A6) : const Color(0xFF8E8E93)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel', style: TextStyle(color: isDark ? const Color(0xFF9AA0A6) : const Color(0xFF8E8E93))),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(
            backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
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
    final textColor = isDark ? const Color(0xFFF5F6FA) : const Color(0xFF1E1E1E);

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
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 14),
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
              style: TextStyle(color: isDark ? const Color(0xFF9AA0A6) : const Color(0xFF8E8E93))),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: const Text('Delete permanently',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ],
    );
  }
}
