import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../services/auth_service.dart';
import '../../../core/widgets/dot_loading.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Nothing OS-inspired Colour Palette
// Monochrome base · Red brand accent · NDOT dot typography
// ─────────────────────────────────────────────────────────────────────────────
class AuthTheme {
  // Brand accent (matches app-wide accent)
  static const accent = Color(0xFFE5252A);

  // Dark
  static const darkBg = Color(0xFF000000);
  static const darkSurface = Color(0xFF0F0F0F);
  static const darkBorder = Color(0xFF222222);
  static const darkBorderFocus = Color(0xFFE5252A);
  static const darkText = Color(0xFFFFFFFF);
  static const darkSubtext = Color(0xFF888888);
  static const darkHint = Color(0xFF444444);

  // Light
  static const lightBg = Color(0xFFFFFFFF);
  static const lightSurface = Color(0xFFF5F5F5);
  static const lightBorder = Color(0xFFDDDDDD);
  static const lightBorderFocus = Color(0xFFE5252A);
  static const lightText = Color(0xFF000000);
  static const lightSubtext = Color(0xFF666666);
  static const lightHint = Color(0xFFBBBBBB);
}

// ─────────────────────────────────────────────────────────────────────────────
// Login Screen
// ─────────────────────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isNavigating = false;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isNavigating) return;
    final auth = Provider.of<AuthService>(context);
    if (auth.currentUser != null) {
      _isNavigating = true;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _checkProfileAndNavigate());
    }
  }

  Future<void> _checkProfileAndNavigate() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final profile = await auth.getProfile();
    if (!mounted) return;
    if (profile != null &&
        profile['college_name'] != null &&
        profile['college_name'].toString().isNotEmpty) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/create_profile');
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthService>(context, listen: false).signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(_friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              fontFamily: 'NDOT')),
      backgroundColor: AuthTheme.accent,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  String _friendlyError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('notinitializederror') ||
        lower.contains('not been initialized')) {
      return 'Supabase is still initializing. Please check your internet and try again.';
    }
    if (lower.contains('supabase') && lower.contains('initialization')) {
      return 'Supabase is still starting up. Please try again in a moment.';
    }
    if (lower.contains('invalid') ||
        lower.contains('credentials') ||
        lower.contains('password')) {
      return 'Incorrect email or password.';
    }
    if (lower.contains('timed out') ||
        lower.contains('socket') ||
        lower.contains('network')) {
      return 'Network error. Check your connection or retry.';
    }
    return raw.replaceAll('Exception:', '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AuthTheme.darkBg : AuthTheme.lightBg;
    final text = isDark ? AuthTheme.darkText : AuthTheme.lightText;
    final subtext = isDark ? AuthTheme.darkSubtext : AuthTheme.lightSubtext;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light
              .copyWith(statusBarColor: Colors.transparent)
          : SystemUiOverlayStyle.dark
              .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: bg,
        body: Stack(
          children: [
            // ── Nothing OS dot-matrix grid texture ──
            Positioned.fill(
              child: CustomPaint(painter: _DotGridPainter(isDark: isDark)),
            ),

            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 56),

                          // ── Nothing OS logo block ──────────────────────────────
                          _NothingLogo(isDark: isDark),
                          const SizedBox(height: 48),

                          // ── Headline ──────────────────────────────────────────
                          Text(
                            'SIGN IN',
                            style: TextStyle(
                              fontFamily: 'NDOT',
                              color: text,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3.0,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Access your academic universe',
                            style: TextStyle(
                              color: subtext,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.3,
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 40),

                          // ── Fields ────────────────────────────────────────────
                          AuthField(
                            controller: _emailController,
                            label: 'EMAIL ADDRESS',
                            hint: 'you@example.com',
                            icon: Iconsax.sms_copy,
                            isDark: isDark,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) =>
                                v!.isEmpty ? 'Email is required' : null,
                          ),
                          const SizedBox(height: 28),
                          AuthField(
                            controller: _passwordController,
                            label: 'PASSWORD',
                            hint: '••••••••',
                            icon: Iconsax.lock_1_copy,
                            isDark: isDark,
                            obscureText: !_isPasswordVisible,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Iconsax.eye_slash_copy
                                    : Iconsax.eye_copy,
                                size: 18,
                                color: isDark
                                    ? AuthTheme.darkHint
                                    : AuthTheme.lightHint,
                              ),
                              onPressed: () => setState(
                                  () => _isPasswordVisible = !_isPasswordVisible),
                            ),
                            validator: (v) =>
                                v!.isEmpty ? 'Password is required' : null,
                          ),

                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () =>
                                  _showError('Password reset coming soon'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Forgot password?',
                                style: TextStyle(
                                  fontFamily: 'NDOT',
                                  color: subtext,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // ── Primary button ────────────────────────────────────
                          AuthPrimaryButton(
                            label: 'CONTINUE',
                            isLoading: _isLoading,
                            onTap: _login,
                          ),

                          const SizedBox(height: 28),
                          AuthDivider(isDark: isDark),
                          const SizedBox(height: 28),

                          // ── Google ────────────────────────────────────────────
                          AuthGoogleButton(
                            isDark: isDark,
                            onTap: () async {
                              try {
                                await Provider.of<AuthService>(context,
                                        listen: false)
                                    .signInWithGoogle();
                              } catch (e) {
                                if (!mounted) return;
                                _showError(e.toString());
                              }
                            },
                          ),

                          const SizedBox(height: 40),

                          // ── Footer ────────────────────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "No account?  ",
                                style: TextStyle(
                                    fontFamily: 'NDOT',
                                    color: subtext,
                                    fontSize: 13,
                                    letterSpacing: 0.3),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pushReplacementNamed(
                                    context, '/signup'),
                                child: const Text(
                                  'CREATE ONE',
                                  style: TextStyle(
                                    fontFamily: 'NDOT',
                                    color: AuthTheme.accent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nothing OS dot-matrix grid background painter
// ─────────────────────────────────────────────────────────────────────────────
class _DotGridPainter extends CustomPainter {
  final bool isDark;
  const _DotGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.04)
      ..style = PaintingStyle.fill;
    const spacing = 20.0;
    const radius = 1.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => old.isDark != isDark;
}

// ─────────────────────────────────────────────────────────────────────────────
// Nothing OS-style Logo
// ─────────────────────────────────────────────────────────────────────────────
class _NothingLogo extends StatelessWidget {
  final bool isDark;
  const _NothingLogo({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final text = isDark ? AuthTheme.darkText : AuthTheme.lightText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Glyph mark — two stacked squares (Nothing-OS style)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              color: AuthTheme.accent,
            ),
            const SizedBox(width: 4),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                border: Border.all(color: AuthTheme.accent, width: 1.5),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 12,
              height: 12,
              color: text.withOpacity(0.15),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'Scholar',
              style: TextStyle(
                fontFamily: 'NDOT',
                color: text,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                height: 1.0,
              ),
            ),
            Text(
              'X',
              style: const TextStyle(
                fontFamily: 'NDOT',
                color: AuthTheme.accent,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'MAKAUT EDITION',
          style: TextStyle(
            fontFamily: 'NDOT',
            color: text.withOpacity(0.3),
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 3.5,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Auth Widgets (exported for SignupScreen)
// ─────────────────────────────────────────────────────────────────────────────

/// Input field — Nothing OS style: no fill, sharp border, NDOT label.
class AuthField extends StatefulWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final bool isDark, obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
  });

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  final _node = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _node.addListener(() => setState(() => _isFocused = _node.hasFocus));
  }

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _isFocused
        ? AuthTheme.accent
        : (widget.isDark ? AuthTheme.darkBorder : AuthTheme.lightBorder);
    final textColor =
        widget.isDark ? AuthTheme.darkText : AuthTheme.lightText;
    final hintColor =
        widget.isDark ? AuthTheme.darkHint : AuthTheme.lightHint;
    final labelColor =
        _isFocused ? AuthTheme.accent : (widget.isDark ? AuthTheme.darkSubtext : AuthTheme.lightSubtext);
    final iconColor = _isFocused
        ? AuthTheme.accent
        : (widget.isDark ? AuthTheme.darkHint : AuthTheme.lightHint);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontFamily: 'NDOT',
            color: labelColor,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          focusNode: _node,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              fontFamily: 'NDOT'),
          validator: widget.validator,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
                color: hintColor,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                fontFamily: 'NDOT'),
            prefixIcon: Icon(widget.icon, color: iconColor, size: 18),
            suffixIcon: widget.suffixIcon,
            filled: false,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor, width: 1.0)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor, width: 1.0)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AuthTheme.accent, width: 1.5)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AuthTheme.accent, width: 1.0)),
          ),
        ),
      ],
    );
  }
}

/// Sharp rectangular CTA button — Nothing OS style.
class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedOpacity(
        opacity: isLoading ? 0.65 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: 52,
          decoration: const BoxDecoration(
            color: AuthTheme.accent,
            // Softened corners
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 40,
                    height: 20,
                    child: const DotLoadingIndicator(size: 16),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'NDOT',
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal "or" divider.
class AuthDivider extends StatelessWidget {
  final bool isDark;
  const AuthDivider({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final divColor =
        isDark ? const Color(0xFF222222) : const Color(0xFFDDDDDD);
    final txtColor =
        isDark ? AuthTheme.darkHint : AuthTheme.lightHint;

    return Row(
      children: [
        Expanded(child: Divider(color: divColor, thickness: 1, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'OR',
            style: TextStyle(
                fontFamily: 'NDOT',
                color: txtColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0),
          ),
        ),
        Expanded(child: Divider(color: divColor, thickness: 1, height: 1)),
      ],
    );
  }
}

/// Google sign-in button — Nothing OS border style.
class AuthGoogleButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  const AuthGoogleButton(
      {super.key, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AuthTheme.darkText : AuthTheme.lightText;
    final border = isDark ? AuthTheme.darkBorder : AuthTheme.lightBorder;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
              padding: const EdgeInsets.all(2),
              child: Image.asset(
                'assets/google_logo.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.g_mobiledata_rounded,
                    size: 16,
                    color: Color(0xFF4285F4)),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'CONTINUE WITH GOOGLE',
              style: TextStyle(
                fontFamily: 'NDOT',
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
