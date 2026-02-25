import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:makaut_scholar/domain/repositories/billing_repository.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:async';

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
  String _selectedMethod = 'GooglePlay'; // Default to official method
  bool _isLoading = true;
  bool _successHandled = false;
  late BillingRepository _billingRepository;
  ProductDetails? _productDetails;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  StreamSubscription<Map<String, dynamic>>? _alternativePurchaseSubscription;

  @override
  void initState() {
    super.initState();
    _billingRepository = context.read<BillingRepository>();
    _loadProducts();
    _purchaseSubscription = _billingRepository.purchaseStream.listen(_listenToPurchases);
    _alternativePurchaseSubscription = _billingRepository.alternativePurchaseStream.listen(_listenToAlternativePurchases);
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    _alternativePurchaseSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _billingRepository.fetchProducts({widget.itemId});
      if (products.isNotEmpty) {
        setState(() {
          _productDetails = products.first;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _listenToPurchases(List<PurchaseDetails> purchases) {
    for (var purchase in purchases) {
      // Standard IAP or UCB Google Play choice
      if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
        if (purchase.pendingCompletePurchase) {
          InAppPurchase.instance.completePurchase(purchase);
        }
        _handleSuccess();
      } else if (purchase.status == PurchaseStatus.error) {
        _handleError(purchase.error?.message ?? 'Unknown error');
      }
    }
  }

  void _listenToAlternativePurchases(Map<String, dynamic> purchase) {
    if (purchase['status'] == 'purchased') {
      _handleSuccess();
    }
  }

  Future<void> _handlePayment() async {
    if (_productDetails == null && _selectedMethod == 'GooglePlay') {
      _handleError("Product not found in Google Play Console.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_selectedMethod == 'GooglePlay') {
        // Launches the standard Google Play flow
        // Google Play itself will present the choice on Android if UCB is configured
        await _billingRepository.launchBillingFlow(_productDetails!);
      } else {
        // Launches Razorpay flow directly
        await _billingRepository.processRazorpayPayment(
          itemId: widget.itemId,
          itemType: widget.itemType,
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
      // Pop immediately to avoid visibility gap
      Navigator.pop(context, {
        'success': true,
        'itemUrl': widget.itemUrl,
        'itemName': widget.itemName,
      });
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
                  ? const Color(0xFF1A1D21).withOpacity(0.9)
                  : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0xFF8E82FF).withOpacity(0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8E82FF).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Iconsax.tick_circle_copy, color: Color(0xFF8E82FF), size: 48),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Unlock Successful! ✨",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  "Your premium content is ready. We are preparing it for you now...",
                  style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF8E82FF)),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $message')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Theme-aware Color Palette
    final Color bgColor = isDarkMode ? const Color(0xFF0B0D11) : const Color(0xFFF8F9FE);
    final Color surfaceColor = isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03);
    final Color borderColor = isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08);
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF1A1D21);
    final Color textDimColor = isDarkMode ? Colors.white70 : const Color(0xFF4A4D54);
    final Color accentColor = const Color(0xFF8E82FF); // Signature Purple

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Dynamic Ambient Background Glows
          if (isDarkMode) ...[
            Positioned(
              top: -150,
              right: -100,
              child: _AmbientGlow(color: accentColor.withOpacity(0.12), size: 400),
            ),
            Positioned(
              bottom: -150,
              left: -100,
              child: _AmbientGlow(color: Colors.blue.withOpacity(0.08), size: 400),
            ),
          ],
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, textColor),
                const SizedBox(height: 12),
                _buildOrderSummary(surfaceColor, borderColor, textColor, textDimColor, accentColor),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    "Secure Payment",
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
                  subtitle: 'Recommended • Fast & Secure',
                  icon: FontAwesomeIcons.googlePlay,
                  color: const Color(0xFF34A853),
                  isSelected: _selectedMethod == 'GooglePlay',
                  onTap: () => setState(() => _selectedMethod = 'GooglePlay'),
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  textColor: textColor,
                  textDimColor: textDimColor,
                ),
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
              child: Center(
                child: CircularProgressIndicator(color: accentColor, strokeWidth: 3),
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
            "Checkout",
            style: TextStyle(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(Color surface, Color border, Color text, Color textDim, Color accent) {
    final bool isBundle = widget.itemType == 'semester_bundle';
    final Color itemAccent = isBundle ? const Color(0xFFFFB347) : accent; // Orange for bundle

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isBundle ? itemAccent.withValues(alpha: 0.5) : border, width: isBundle ? 1.5 : 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: itemAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Iconsax.star_1, size: 14, color: itemAccent),
                        const SizedBox(width: 6),
                        Text('RECOMMENDED UPGRADE', style: TextStyle(color: itemAccent, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: itemAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(isBundle ? Iconsax.book_1 : Iconsax.document_text_copy, color: itemAccent, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isBundle ? "Complete Your Semester" : "Item Summary", style: TextStyle(color: textDim, fontSize: 12, fontWeight: FontWeight.bold)),
                          Text(widget.itemName, style: TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.w700)),
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
                    Text("Total Amount", style: TextStyle(color: text, fontSize: 17, fontWeight: FontWeight.w800)),
                    Text(
                      "₹${widget.price.toStringAsFixed(2)}",
                      style: TextStyle(
                        color: itemAccent,
                        fontSize: 22,
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
    required VoidCallback onTap,
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
          color: isSelected ? color.withOpacity(0.08) : surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.5) : borderColor,
            width: isSelected ? 2 : 1,
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
                  Text(name, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w800)),
                  Text(subtitle, style: TextStyle(color: textDimColor, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Icon(Iconsax.tick_circle_copy, color: isSelected ? color : Colors.transparent, size: 24),
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
              Text("256-bit SSL Secure Transaction", style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Badge(icon: FontAwesomeIcons.ccVisa, color: color),
              const SizedBox(width: 20),
              _Badge(icon: FontAwesomeIcons.ccMastercard, color: color),
              const SizedBox(width: 20),
              _Badge(icon: FontAwesomeIcons.googlePay, color: color),
              const SizedBox(width: 20),
              _Badge(icon: FontAwesomeIcons.applePay, color: color),
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
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 34),
        decoration: BoxDecoration(
          color: bg,
          border: Border(top: BorderSide(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))),
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handlePayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 8,
            shadowColor: accent.withOpacity(0.4),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Authorize Payment", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              SizedBox(width: 10),
              Icon(Iconsax.arrow_right_3_copy, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  final Color color;
  final double size;
  const _AmbientGlow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _Badge({required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Icon(icon, color: color.withOpacity(0.4), size: 18);
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
            color: i % 2 == 0 ? (isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)) : Colors.transparent,
            height: 1,
          ),
        ),
      ),
    );
  }
}
