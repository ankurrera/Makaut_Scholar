import 'package:in_app_purchase/in_app_purchase.dart';

abstract class BillingRepository {
  /// Stream of purchase updates from Google Play/App Store
  Stream<List<PurchaseDetails>> get purchaseStream;

  /// Check if the store is available
  Future<bool> isStoreAvailable();

  /// Query product details from Google Play
  Future<List<ProductDetails>> fetchProducts(Set<String> productIds);

  /// Launch Google Play Billing Flow.
  /// If User Choice Billing is enabled, the OS will handle the choice.
  Future<void> launchBillingFlow(ProductDetails product);

  /// Initialize Razorpay payment for Alternative Billing choice
  Future<void> processRazorpayPayment({
    required String itemId,
    required String itemType,
    required double amount,
    String? externalTransactionToken,
  });

  /// Dispose resources
  void dispose();
}
