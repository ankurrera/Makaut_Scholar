import 'package:in_app_purchase/in_app_purchase.dart';

abstract class BillingRepository {
  /// The valid price tiers matching Google Play Console products
  static const List<int> priceTiers = [49, 99, 129, 149, 199, 399, 699];

  /// Maps a price (from Supabase) to the matching Play Console product ID
  static String priceTierProductId(double price) {
    final int rounded = price.round();
    // Find nearest tier (exact match expected since admin uses dropdowns)
    final int tier = priceTiers.firstWhere(
      (t) => t == rounded,
      orElse: () => priceTiers.reduce((a, b) => (a - rounded).abs() < (b - rounded).abs() ? a : b),
    );
    return 'scholar_price_$tier';
  }

  /// Stream of purchase updates from Google Play/App Store
  Stream<List<PurchaseDetails>> get purchaseStream;

  /// Stream of alternative billing successes (e.g. Razorpay)
  Stream<Map<String, dynamic>> get alternativePurchaseStream;

  /// Check if the store is available
  Future<bool> isStoreAvailable();

  /// Query product details from Google Play
  Future<List<ProductDetails>> fetchProducts(Set<String> productIds);

  /// Launch Google Play Billing Flow with an order tracking ID.
  Future<void> launchBillingFlow(ProductDetails product, {String? orderId});

  /// Create an order in Supabase before launching any payment flow
  Future<Map<String, dynamic>> createOrder({
    required String itemId,
    required String itemType,
    required double amount,
    required String gateway, // 'google_play' or 'razorpay'
  });

  /// Open Razorpay Checkout with a pre-created order (created via createOrder())
  Future<void> processRazorpayPayment({
    required String razorpayOrderId,  // From Razorpay API (returned by createOrder)
    required String internalOrderId,  // Our Supabase order UUID
    required String keyId,            // Razorpay key
    required double amount,
    String? externalTransactionToken,
  });

  /// Dispose resources
  void dispose();
}
