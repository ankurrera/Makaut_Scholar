import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../services/auth_service.dart';
import '../login/login_screen.dart'
    show AuthTheme, AuthField, AuthPrimaryButton, AuthDivider, AuthGoogleButton;

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isNavigating = false;
  DateTime? _lastAttempt;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    if (_lastAttempt != null && now.difference(_lastAttempt!).inSeconds < 5) {
      _showError('Please wait a moment before trying again.');
      return;
    }
    _lastAttempt = now;

    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthService>(context, listen: false).signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      final auth = Provider.of<AuthService>(context, listen: false);
      if (auth.currentSession == null) {
        _showSuccess('Check your email to confirm your account.');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        _checkProfileAndNavigate();
      }
    } catch (e) {
      if (!mounted) return;
      _showError(_friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('rate') ||
        lower.contains('too many') ||
        lower.contains('over_email')) {
      return 'Too many attempts. Please wait 1–2 minutes.';
    }
    if (lower.contains('already registered') ||
        lower.contains('user already')) {
      return 'Email already registered. Try signing in.';
    }
    if (lower.contains('timed out') ||
        lower.contains('socket') ||
        lower.contains('network')) {
      return 'Network error. Check your connection.';
    }
    return raw.replaceAll('Exception:', '').trim();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
      backgroundColor: const Color(0xFFD94F4F),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
      backgroundColor: AuthTheme.accent,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? AuthTheme.darkBg : AuthTheme.lightBg;
    final text = isDark ? AuthTheme.darkText : AuthTheme.lightText;
    final subtext = isDark ? AuthTheme.darkSubtext : AuthTheme.lightSubtext;
    final hintColor = isDark ? AuthTheme.darkHint : AuthTheme.lightHint;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light
              .copyWith(statusBarColor: Colors.transparent)
          : SystemUiOverlayStyle.dark
              .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),

                    // ── Back button ───────────────────────────────────────────
                    GestureDetector(
                      onTap: () => Navigator.canPop(context)
                          ? Navigator.pop(context)
                          : Navigator.pushReplacementNamed(context, '/login'),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AuthTheme.darkSurface
                              : AuthTheme.lightSurface,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                            color: isDark
                                ? AuthTheme.darkBorder
                                : AuthTheme.lightBorder,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Iconsax.arrow_left_copy,
                          color: isDark
                              ? AuthTheme.darkSubtext
                              : AuthTheme.lightSubtext,
                          size: 18,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Headline ──────────────────────────────────────────────
                    Text(
                      'Create an account',
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
                      'Join thousands of MAKAUT students on ScholarX',
                      style: TextStyle(
                        color: subtext,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Fields ────────────────────────────────────────────────
                    AuthField(
                      controller: _nameController,
                      label: 'Full name',
                      hint: 'Your name',
                      icon: Iconsax.user_copy,
                      isDark: isDark,
                      validator: (v) => v!.isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 18),
                    AuthField(
                      controller: _emailController,
                      label: 'Email address',
                      hint: 'you@example.com',
                      icon: Iconsax.sms_copy,
                      isDark: isDark,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          !v!.contains('@') ? 'Enter a valid email' : null,
                    ),
                    const SizedBox(height: 18),
                    AuthField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'At least 6 characters',
                      icon: Iconsax.lock_1_copy,
                      isDark: isDark,
                      obscureText: !_isPasswordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Iconsax.eye_slash_copy
                              : Iconsax.eye_copy,
                          size: 18,
                          color: hintColor,
                        ),
                        onPressed: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible),
                      ),
                      validator: (v) =>
                          v!.length < 6 ? 'Min 6 characters' : null,
                    ),
                    const SizedBox(height: 18),
                    AuthField(
                      controller: _confirmPasswordController,
                      label: 'Confirm password',
                      hint: 'Re-enter your password',
                      icon: Iconsax.lock_copy,
                      isDark: isDark,
                      obscureText: !_isConfirmPasswordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible
                              ? Iconsax.eye_slash_copy
                              : Iconsax.eye_copy,
                          size: 18,
                          color: hintColor,
                        ),
                        onPressed: () => setState(() =>
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible),
                      ),
                      validator: (v) => v != _passwordController.text
                          ? 'Passwords do not match'
                          : null,
                    ),

                    const SizedBox(height: 28),

                    // ── Primary button ────────────────────────────────────────
                    AuthPrimaryButton(
                      label: 'Create account',
                      isLoading: _isLoading,
                      onTap: _signup,
                    ),

                    const SizedBox(height: 24),
                    AuthDivider(isDark: isDark),
                    const SizedBox(height: 24),

                    AuthGoogleButton(
                      isDark: isDark,
                      onTap: () async {
                        try {
                          await Provider.of<AuthService>(context, listen: false)
                              .signInWithGoogle();
                        } catch (e) {
                          if (!mounted) return;
                          _showError(e.toString());
                        }
                      },
                    ),

                    const SizedBox(height: 32),

                    // ── Footer ────────────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account?  ',
                          style: TextStyle(color: subtext, fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () =>
                              Navigator.pushReplacementNamed(context, '/login'),
                          child: Text(
                            'Sign in',
                            style: TextStyle(
                              color: AuthTheme.accent,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ── Privacy Link ──────────────────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          Text(
                            "By creating an account, you agree to our",
                            style: TextStyle(
                                color: subtext.withValues(alpha: 0.7),
                                fontSize: 12),
                          ),
                          GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, '/privacy'),
                            child: Text(
                              'Privacy Policy',
                              style: TextStyle(
                                color: AuthTheme.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
