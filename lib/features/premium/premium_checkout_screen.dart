import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:makaut_scholar/domain/repositories/billing_repository.dart';
import 'package:makaut_scholar/core/config/payment_config.dart';
import 'package:makaut_scholar/core/widgets/dot_loading.dart';
import 'package:makaut_scholar/core/widgets/shimmer_skeleton.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../auth/login/login_screen.dart' show AuthTheme;
import 'dart:async' show StreamSubscription, Timer;


class PremiumCheckoutScreen extends StatefulWidget {
  final String itemId;
  final String itemType;
  final String itemName;
  final String? itemUrl;
  final double price;

  const PremiumCheckoutScreen({
    super.key,
    required this.itemId,
    required this.itemType,
    required this.itemName,
    this.itemUrl,
    required this.price,
  });

  @override
  State<PremiumCheckoutScreen> createState() => _PremiumCheckoutScreenState();
}

class _PremiumCheckoutScreenState extends State<PremiumCheckoutScreen> {
  String _selectedMethod =
      'GooglePlay'; // Will switch to Razorpay if product unavailable
  bool _isLoading = true;
  bool _successHandled = false;
  late BillingRepository _billingRepository;
  ProductDetails? _productDetails;
  // NOTE: We do NOT subscribe to purchaseStream directly.
  // The global listener in BillingRepositoryImpl handles purchase completion
  // and reports to backend. We only listen to the resulting alternativePurchaseStream,
  // which fires after the purchase is synced. This prevents a double-notification loop.
  StreamSubscription<Map<String, dynamic>>? _alternativePurchaseSubscription;
  Timer? _paymentTimeoutTimer;

  @override
  void initState() {
    super.initState();
    _billingRepository = context.read<BillingRepository>();
    _loadProducts();
    // Only listen to the alternativePurchaseStream (fired by BillingRepo after backend sync).
    _alternativePurchaseSubscription = _billingRepository
        .alternativePurchaseStream
        .listen(_listenToAlternativePurchases);
  }

  @override
  void dispose() {
    _paymentTimeoutTimer?.cancel();
    _alternativePurchaseSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      // Map the item's price to a generic price-tier product ID
      final String tierId = BillingRepository.priceTierProductId(widget.price);
      final products = await _billingRepository.fetchProducts({tierId});
      if (products.isNotEmpty) {
        setState(() {
          _productDetails = products.first;
          _isLoading = false;
        });
      } else {
        // Product not found in Play Console — do NOT fall back silently
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      // Could not reach Play Console — do NOT fall back silently
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  void _listenToAlternativePurchases(Map<String, dynamic> purchase) {
    // Fired by BillingRepositoryImpl after it has synced the purchase to the backend.
    // Both 'purchased' (success) and 'purchased_finished' (sync done, possibly with error)
    // should trigger a success unlock since the OS already confirmed the payment.
    final status = purchase['status'] as String? ?? '';
    if (status == 'purchased' || status == 'purchased_finished') {
      _handleSuccess();
    }
  }

  Future<void> _handlePayment() async {
    if (_productDetails == null && _selectedMethod == 'GooglePlay') {
      _handleError(
          "Product not found in Google Play Console. Please try again later.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Create an order in Supabase FIRST
      final orderData = await _billingRepository.createOrder(
        itemId: widget.itemId,
        itemType: widget.itemType,
        amount: widget.price,
        // Always 'google_play' when Razorpay is disabled
        gateway: (!PaymentConfig.razorpayEnabled || _selectedMethod == 'GooglePlay')
            ? 'google_play'
            : 'razorpay',
      );

      final String orderId = orderData['orderId'];

      if (!PaymentConfig.razorpayEnabled || _selectedMethod == 'GooglePlay') {
        // Launch Google Play Billing.
        // After the user completes payment, Google Play will:
        //   1. Fire a purchaseStream event (caught by BillingRepo global listener)
        //   2. BillingRepo reports to backend
        //   3. BillingRepo fires alternativePurchaseStream
        //   4. Our _listenToAlternativePurchases calls _handleSuccess
        await _billingRepository.launchBillingFlow(_productDetails!,
            orderId: orderId);
        // Start a safety timeout: if no signal comes in 45s, show an error
        _paymentTimeoutTimer?.cancel();
        _paymentTimeoutTimer = Timer(const Duration(seconds: 45), () {
          if (mounted && !_successHandled) {
            setState(() => _isLoading = false);
            _handleError('Payment timed out. If payment was charged, it will be processed shortly.');
          }
        });
      } else {
        // Launch Razorpay (only reachable when PaymentConfig.razorpayEnabled = true)
        final String razorpayOrderId = orderData['razorpayOrderId'] ?? '';
        final String keyId = orderData['keyId'] ?? '';
        if (razorpayOrderId.isEmpty || keyId.isEmpty) {
          throw Exception('Missing Razorpay order details from server.');
        }
        await _billingRepository.processRazorpayPayment(
          razorpayOrderId: razorpayOrderId,
          internalOrderId: orderId,
          keyId: keyId,
          amount: widget.price,
        );
      }
    } catch (e) {
      _handleError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSuccess() async {
    if (mounted && !_successHandled) {
      _successHandled = true;
      
      // Stop local loading state
      setState(() => _isLoading = false);

      // Show the beautiful success dialog defined below
      await _showSuccessDialog();

      if (mounted) {
        // Pop to the originating screen with success flag
        Navigator.pop(context, {
          'success': true,
          'itemUrl': widget.itemUrl,
          'itemName': widget.itemName,
        });
      }
    }
  }

  Future<void> _showSuccessDialog() async {
    // Auto-close dialog after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AuthTheme.darkSurface
                  : AuthTheme.lightSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AuthTheme.accent.withValues(alpha: 0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AuthTheme.accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Iconsax.tick_circle_copy,
                      color: AuthTheme.accent, size: 48),
                ),
                const SizedBox(height: 24),
                const Text(
                  "SUCCESSFUL! ✨",
                  style: TextStyle(
                      fontFamily: 'NDOT',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  "Your premium content is ready. We are preparing it for you now...",
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                const ShimmerSkeleton(
                  width: 80,
                  height: 4,
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleError(String message) {
    if (mounted) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark ? AuthTheme.darkBg : AuthTheme.lightBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ERROR',
                  style: TextStyle(
                      fontFamily: 'NDOT',
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      letterSpacing: 1.5)),
              const SizedBox(height: 16),
              Text(message,
                  style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.white70 : Colors.black87)),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AuthTheme.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('GOT IT',
                      style: TextStyle(
                          fontFamily: 'NDOT',
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: 1.0)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Theme-aware Color Palette
    final Color bgColor = isDarkMode ? AuthTheme.darkBg : AuthTheme.lightBg;
    final Color surfaceColor = isDarkMode ? AuthTheme.darkSurface : AuthTheme.lightSurface;
    final Color borderColor = isDarkMode ? AuthTheme.darkBorder : AuthTheme.lightBorder;
    final Color textColor = isDarkMode ? AuthTheme.darkText : AuthTheme.lightText;
    final Color textDimColor = isDarkMode ? AuthTheme.darkSubtext : AuthTheme.lightSubtext;
    final Color accentColor = AuthTheme.accent;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ── Nothing OS dot-matrix grid texture ──
          Positioned.fill(
            child: CustomPaint(painter: _DotGridPainter(isDark: isDarkMode)),
          ),


          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, textColor),
                const SizedBox(height: 12),
                _buildOrderSummary(surfaceColor, borderColor, textColor,
                    textDimColor, accentColor),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    PaymentConfig.razorpayEnabled
                        ? "Secure Payment"
                        : "Pay with Google Play",
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildMethodOption(
                  id: 'GooglePlay',
                  name: 'Google Play Billing',
                  subtitle: _productDetails != null
                      ? 'Recommended • Fast & Secure'
                      : _isLoading
                          ? 'Checking availability...'
                          : 'Currently unavailable for this item',
                  icon: FontAwesomeIcons.googlePlay,
                  color: _productDetails != null
                      ? textColor
                      : textDimColor,
                  isSelected: _selectedMethod == 'GooglePlay',
                  onTap: _productDetails != null
                      ? () => setState(() => _selectedMethod = 'GooglePlay')
                      : null,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  textColor: textColor,
                  textDimColor: textDimColor,
                ),
                // Razorpay option — only shown when the feature flag is enabled
                if (PaymentConfig.razorpayEnabled) ...[
                  const SizedBox(height: 16),
                  _buildMethodOption(
                    id: 'Razorpay',
                    name: 'Other UPI / Razorpay',
                    subtitle: 'Alternative Choice Billing',
                    icon: Iconsax.shield_tick_copy,
                    color: accentColor,
                    isSelected: _selectedMethod == 'Razorpay',
                    onTap: () => setState(() => _selectedMethod = 'Razorpay'),
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                    textColor: textColor,
                    textDimColor: textDimColor,
                  ),
                ],
                const Spacer(),
                _buildSecurityBadges(textDimColor),
                const SizedBox(height: 100), // Space for bottom bar
              ],
            ),
          ),

          _buildBottomBar(accentColor, bgColor, isDarkMode),

          if (_isLoading)
            Container(
              color: isDarkMode ? Colors.black54 : Colors.white60,
              child: const Center(
                child: ShimmerSkeleton(
                  width: 120,
                  height: 20,
                  isNdot: true,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Iconsax.arrow_left_2_copy, color: textColor),
          ),
          const SizedBox(width: 4),
          Text(
            "CHECKOUT",
            style: TextStyle(
              color: textColor,
              fontFamily: 'NDOT',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(
      Color surface, Color border, Color text, Color textDim, Color accent) {
    final bool isBundle = widget.itemType == 'semester_bundle';
    final Color itemAccent = accent; // Standardize to Nothing Red

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isBundle ? itemAccent : border,
            width: isBundle ? 1.5 : 1.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isBundle)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: itemAccent, width: 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Iconsax.star_1, size: 10, color: itemAccent),
                        const SizedBox(width: 6),
                        Text('RECOMMENDED UPGRADE',
                            style: TextStyle(
                                fontFamily: 'NDOT',
                                color: itemAccent,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5)),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isBundle ? itemAccent.withValues(alpha: 0.05) : itemAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: isBundle ? Border.all(color: itemAccent.withValues(alpha: 0.2)) : null,
                      ),
                      child: Icon(
                          isBundle
                              ? Iconsax.book_1
                              : Iconsax.document_text_copy,
                          color: itemAccent,
                          size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              isBundle
                                  ? "SEMESTER BUNDLE"
                                  : "ITEM SUMMARY",
                              style: TextStyle(
                                  fontFamily: 'NDOT',
                                  color: textDim,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0)),
                          Text(widget.itemName,
                              style: TextStyle(
                                  fontFamily: 'NDOT',
                                  color: text,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: _DottedDivider(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("TOTAL AMOUNT",
                        style: TextStyle(
                            fontFamily: 'NDOT',
                            color: text,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0)),
                    Text(
                      "₹${widget.price.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontFamily: 'NDOT',
                        color: itemAccent,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMethodOption({
    required String id,
    required String name,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback? onTap,
    required Color surfaceColor,
    required Color borderColor,
    required Color textColor,
    required Color textDimColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.5) : borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name.toUpperCase(),
                      style: TextStyle(
                          fontFamily: 'NDOT',
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0)),
                  Text(subtitle,
                      style: TextStyle(
                          color: textDimColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Icon(Iconsax.tick_circle_copy,
                color: isSelected ? color : Colors.transparent, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityBadges(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.lock_copy, color: color, size: 14),
              const SizedBox(width: 6),
              Text(
                (PaymentConfig.razorpayEnabled
                    ? "256-BIT SSL SECURE TRANSACTION"
                    : "SECURED BY GOOGLE PLAY").toUpperCase(),
                style: TextStyle(
                    fontFamily: 'NDOT',
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Show all badges when Razorpay enabled; only Google Pay when disabled
              if (PaymentConfig.razorpayEnabled) ...[
                _Badge(icon: FontAwesomeIcons.ccVisa, color: color),
                const SizedBox(width: 20),
                _Badge(icon: FontAwesomeIcons.ccMastercard, color: color),
                const SizedBox(width: 20),
              ],
              _Badge(icon: FontAwesomeIcons.googlePay, color: color),
              if (PaymentConfig.razorpayEnabled) ...[
                const SizedBox(width: 20),
                _Badge(icon: FontAwesomeIcons.applePay, color: color),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(Color accent, Color bg, bool isDarkMode) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border(
              top: BorderSide(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05))),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handlePayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    (PaymentConfig.razorpayEnabled
                            ? "AUTHORIZE PAYMENT"
                            : "PAY WITH GOOGLE PLAY")
                        .toUpperCase(),
                    style: const TextStyle(
                        fontFamily: 'NDOT',
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Iconsax.arrow_right_3_copy, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  final bool isDark;
  const _DotGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04)
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

class _Badge extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _Badge({required this.icon, required this.color});
  @override
  Widget build(BuildContext context) =>
      Icon(icon, color: color.withOpacity(0.4), size: 18);
}

class _DottedDivider extends StatelessWidget {
  const _DottedDivider();
  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: List.generate(
        30,
        (i) => Expanded(
          child: Container(
            color: i % 2 == 0
                ? (isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.1))
                : Colors.transparent,
            height: 1,
          ),
        ),
      ),
    );
  }
}
