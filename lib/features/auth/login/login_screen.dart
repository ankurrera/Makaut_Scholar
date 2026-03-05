import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../services/auth_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Colour palette — single source of truth for both auth screens
// ─────────────────────────────────────────────────────────────────────────────
class AuthTheme {
  // Brand
  static const accent = Color(0xFF7C6EF5);
  static const accentDark = Color(0xFF6459D4);

  // Dark
  static const darkBg = Color(0xFF0F0F13);
  static const darkSurface = Color(0xFF18181F);
  static const darkBorder = Color(0xFF2A2A38);
  static const darkBorderFocus = Color(0xFF7C6EF5);
  static const darkText = Color(0xFFF1F0FF);
  static const darkSubtext = Color(0xFF9A9AB0);
  static const darkHint = Color(0xFF5A5A72);

  // Light
  static const lightBg = Color(0xFFF7F7FB);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFE4E4EF);
  static const lightBorderFocus = Color(0xFF7C6EF5);
  static const lightText = Color(0xFF0E0E1A);
  static const lightSubtext = Color(0xFF6B6B85);
  static const lightHint = Color(0xFFB0B0C8);
}

// ─────────────────────────────────────────────────────────────────────────────
// Login Screen
// ─────────────────────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
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
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
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
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkProfileAndNavigate());
    }
  }

  Future<void> _checkProfileAndNavigate() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final profile = await auth.getProfile();
    if (!mounted) return;
    if (profile != null && profile['college_name'] != null && profile['college_name'].toString().isNotEmpty) {
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
      content: Text(msg, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
      backgroundColor: const Color(0xFFD94F4F),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  String _friendlyError(String raw) {
    final lower = raw.toLowerCase();
    
    // Specifically handle the "Instance of 'NotInitializedError'" or related strings
    if (lower.contains('notinitializederror') || lower.contains('not been initialized')) {
      return 'Supabase is still initializing. Please check your internet and try again in a few seconds.';
    }
    
    if (lower.contains('supabase') && lower.contains('initialization')) {
      return 'Supabase is still starting up. Please try again in a moment.';
    }
    
    if (lower.contains('invalid') || lower.contains('credentials') || lower.contains('password')) {
      return 'Incorrect email or password.';
    }
    
    if (lower.contains('timed out') || lower.contains('socket') || lower.contains('network')) {
      return 'Network error. Check your connection or retry.';
    }
    
    return raw.replaceAll('Exception:', '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg      = isDark ? AuthTheme.darkBg      : AuthTheme.lightBg;
    final text    = isDark ? AuthTheme.darkText     : AuthTheme.lightText;
    final subtext = isDark ? AuthTheme.darkSubtext  : AuthTheme.lightSubtext;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
          : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
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
                      const SizedBox(height: 48),

                      // ── Logo ──────────────────────────────────────────────────
                      _Logo(isDark: isDark),
                      const SizedBox(height: 40),

                      // ── Headline ──────────────────────────────────────────────
                      Text(
                        'Welcome back',
                        style: TextStyle(
                          color: text,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in to continue to ScholarX',
                        style: TextStyle(
                          color: subtext,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ── Fields ────────────────────────────────────────────────
                      AuthField(
                        controller: _emailController,
                        label: 'Email address',
                        hint: 'you@example.com',
                        icon: Iconsax.sms_copy,
                        isDark: isDark,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => v!.isEmpty ? 'Email is required' : null,
                      ),
                      const SizedBox(height: 18),
                      AuthField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Enter your password',
                        icon: Iconsax.lock_1_copy,
                        isDark: isDark,
                        obscureText: !_isPasswordVisible,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Iconsax.eye_slash_copy : Iconsax.eye_copy,
                            size: 18,
                            color: isDark ? AuthTheme.darkHint : AuthTheme.lightHint,
                          ),
                          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),
                        validator: (v) => v!.isEmpty ? 'Password is required' : null,
                      ),

                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _showError('Password reset coming soon'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Forgot password?',
                            style: TextStyle(
                              color: AuthTheme.accent,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Primary button ────────────────────────────────────────
                      AuthPrimaryButton(
                        label: 'Sign in',
                        isLoading: _isLoading,
                        onTap: _login,
                      ),

                      const SizedBox(height: 24),
                      AuthDivider(isDark: isDark),
                      const SizedBox(height: 24),

                      // ── Google ────────────────────────────────────────────────
                      AuthGoogleButton(
                        isDark: isDark,
                        onTap: () async {
                          try {
                            await Provider.of<AuthService>(context, listen: false).signInWithGoogle();
                          } catch (e) {
                            if (!mounted) return;
                            _showError(e.toString());
                          }
                        },
                      ),

                      const SizedBox(height: 36),

                      // ── Footer ────────────────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account?  ",
                            style: TextStyle(color: subtext, fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacementNamed(context, '/signup'),
                            child: Text(
                              'Sign up',
                              style: TextStyle(
                                color: AuthTheme.accent,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Auth Widgets (exported for SignupScreen)
// ─────────────────────────────────────────────────────────────────────────────

/// Logo mark — icon + wordmark.
class _Logo extends StatelessWidget {
  final bool isDark;
  const _Logo({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AuthTheme.accent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ScholarX',
              style: TextStyle(
                color: isDark ? AuthTheme.darkText : AuthTheme.lightText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1.0,
              ),
            ),
            Text(
              'MAKAUT',
              style: TextStyle(
                color: AuthTheme.accent.withValues(alpha: 0.9),
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.5,
                height: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Clean input field with visible label + border.
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
        ? (widget.isDark ? AuthTheme.darkBorderFocus : AuthTheme.lightBorderFocus)
        : (widget.isDark ? AuthTheme.darkBorder : AuthTheme.lightBorder);
    final fieldBg = widget.isDark ? AuthTheme.darkSurface : AuthTheme.lightSurface;
    final labelColor = widget.isDark ? AuthTheme.darkSubtext : AuthTheme.lightSubtext;
    final textColor = widget.isDark ? AuthTheme.darkText : AuthTheme.lightText;
    final hintColor = widget.isDark ? AuthTheme.darkHint : AuthTheme.lightHint;
    final iconColor = _isFocused ? AuthTheme.accent : (widget.isDark ? AuthTheme.darkHint : AuthTheme.lightHint);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            color: labelColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: fieldBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _node,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500),
            validator: widget.validator,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(color: hintColor, fontSize: 14.5, fontWeight: FontWeight.w400),
              prefixIcon: Icon(widget.icon, color: iconColor, size: 18),
              suffixIcon: widget.suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            ),
          ),
        ),
      ],
    );
  }
}

/// Solid accent CTA button.
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
          decoration: BoxDecoration(
            color: AuthTheme.accent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// "or" divider.
class AuthDivider extends StatelessWidget {
  final bool isDark;
  const AuthDivider({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final divColor = isDark ? const Color(0xFF2A2A38) : const Color(0xFFE4E4EF);
    final txtColor = isDark ? AuthTheme.darkHint : AuthTheme.lightHint;

    return Row(
      children: [
        Expanded(child: Divider(color: divColor, thickness: 1, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or continue with',
            style: TextStyle(color: txtColor, fontSize: 12.5, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(child: Divider(color: divColor, thickness: 1, height: 1)),
      ],
    );
  }
}

/// Google sign-in button.
class AuthGoogleButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  const AuthGoogleButton({super.key, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AuthTheme.darkText : AuthTheme.lightText;
    final bg = isDark ? AuthTheme.darkSurface : AuthTheme.lightSurface;
    final border = isDark ? AuthTheme.darkBorder : AuthTheme.lightBorder;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.all(2),
              child: Image.asset(
                'assets/google_logo.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.g_mobiledata_rounded, size: 18, color: Color(0xFF4285F4)),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Continue with Google',
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}