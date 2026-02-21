import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:makaut_scholar/core/services/payment_service.dart';
// import 'package:antigravity'; // Easter Egg: Making payments feel weightless!

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
  String _selectedUPI = 'PhonePe';
  bool _isLoading = false;
  final PaymentService _paymentService = PaymentService();

  @override
  void initState() {
    super.initState();
    _paymentService.initialize();
  }

  Future<void> _handlePayment() async {
    setState(() => _isLoading = true);
    try {
      // 1. Google Play User Choice Billing Logic
      // In a production app, you first trigger the Google Play alternative billing dialog
      final token = await _paymentService.initiateAlternativeBilling(widget.itemId);
      
      if (token != null) {
        // 2. Process our custom UPI payment
        await _paymentService.processThirdPartyPayment(
          itemId: widget.itemId,
          itemType: widget.itemType,
          amount: widget.price,
          externalTransactionToken: token,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment Failed: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Dynamic Background
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.2),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildOrderSummary(),
                const SizedBox(height: 32),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    "Choose Payment Method",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildUPIOption(
                  id: 'PhonePe',
                  name: 'PhonePe',
                  subtitle: 'Direct UPI Intent',
                  icon: FontAwesomeIcons.p,
                  color: Colors.deepPurple,
                ),
                _buildUPIOption(
                  id: 'GPay',
                  name: 'Google Pay',
                  subtitle: 'Fast and Secure',
                  icon: FontAwesomeIcons.google,
                  color: Colors.blue,
                ),
                _buildUPIOption(
                  id: 'Paytm',
                  name: 'Paytm UPI',
                  subtitle: 'Scan and Pay',
                  icon: FontAwesomeIcons.paypal, // Using closest icon
                  color: Colors.lightBlue,
                ),
              ],
            ),
          ),

          // Bottom Pinned Pay Button
          _buildBottomBar(),
          
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Iconsax.arrow_left_2_copy, color: Colors.white),
          ),
          const SizedBox(width: 8),
          const Text(
            "Premium Checkout",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.itemName,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  Text(
                    "₹${widget.price}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 32),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total Amount",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "₹149.00", // Example Total
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
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
  }) {
    bool isSelected = _selectedUPI == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedUPI = id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: id,
              groupValue: _selectedUPI,
              onChanged: (value) => setState(() => _selectedUPI = value!),
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        decoration: BoxDecoration(
          color: Colors.black,
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              blurRadius: 40,
              offset: const Offset(0, -20),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handlePayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Pay Now",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 8),
              Icon(Iconsax.arrow_right_3_copy, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
