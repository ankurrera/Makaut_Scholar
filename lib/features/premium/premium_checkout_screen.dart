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
  final double price;

  const PremiumCheckoutScreen({
    super.key,
    required this.itemId,
    required this.itemType,
    required this.itemName,
    required this.price,
  });

  @override
  State<PremiumCheckoutScreen> createState() => _PremiumCheckoutScreenState();
}

class _PremiumCheckoutScreenState extends State<PremiumCheckoutScreen> {
  final String _selectedUPI = 'Razorpay';
  bool _isLoading = true;
  late BillingRepository _billingRepository;
  ProductDetails? _productDetails;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  @override
  void initState() {
    super.initState();
    _billingRepository = context.read<BillingRepository>();
    _loadProducts();
    _purchaseSubscription = _billingRepository.purchaseStream.listen(_listenToPurchases);
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
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
      if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
        _handleSuccess();
      } else if (purchase.status == PurchaseStatus.error) {
        _handleError(purchase.error?.message ?? 'Unknown error');
      }
    }
  }

  Future<void> _handlePayment() async {
    setState(() => _isLoading = true);
    try {
      await _billingRepository.processRazorpayPayment(
        itemId: widget.itemId,
        itemType: widget.itemType,
        amount: widget.price,
      );
    } catch (e) {
      _handleError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleSuccess() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase Successful! Enjoy your premium content.')),
      );
      Navigator.pop(context, true);
    }
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
                _buildUPIOption(
                  id: 'Razorpay',
                  name: 'Razorpay Checkout',
                  subtitle: 'Cards, Netbanking, UPI & Wallets',
                  icon: Iconsax.shield_tick_copy,
                  color: accentColor,
                  isSelected: true,
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: border),
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Iconsax.document_text_copy, color: accent, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Item Summary", style: TextStyle(color: textDim, fontSize: 12, fontWeight: FontWeight.bold)),
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
                        color: accent,
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

  Widget _buildUPIOption({
    required String id,
    required String name,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required Color surfaceColor,
    required Color borderColor,
    required Color textColor,
    required Color textDimColor,
  }) {
    return Container(
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
            child: Icon(icon, color: color, size: 22),
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
            gap: 20,
            children: [
              _Badge(icon: FontAwesomeIcons.ccVisa, color: color),
              _Badge(icon: FontAwesomeIcons.ccMastercard, color: color),
              _Badge(icon: FontAwesomeIcons.googlePay, color: color),
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
