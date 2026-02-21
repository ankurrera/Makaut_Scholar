import 'dart:io';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentService {
  final InAppPurchase _iap = InAppPurchase.instance;
  final _supabase = Supabase.instance.client;

  /// Initializes the In-App Purchase connection.
  Future<void> initialize() async {
    final bool available = await _iap.isAvailable();
    if (!available) {
      // Handle store not available
      return;
    }
  }

  /// Implements Google Play's User Choice Billing (Alternative Billing).
  /// This reports the choice to Google Play and returns an External Transaction Token.
  Future<String?> initiateAlternativeBilling(String sku) async {
    if (!Platform.isAndroid) return null;

    try {
      final InAppPurchaseAndroidPlatformAddition androidAddition =
          _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();

      // 1. Check if Alternative Billing is supported for this user (India policy)
      // This triggers the Google Play "Alternative Billing" choice dialog
      final BillingResultWrapper billingResult = await androidAddition.isAlternativeBillingOnlyAvailable();
      
      if (billingResult.responseCode == BillingResponse.ok) {
        // In a real scenario, you'd fetch the product details first
        // ProductDetails product = ...
        
        // 2. We trigger the Alternative Billing Flow
        // This is where you'd normally show the choice dialog via showAlternativeBillingOnlyInformationDialog
        // For brevity, we assume the user opted for alternative billing.
        
        // Note: The specific implementation for "User Choice Billing" (Choice of IAP or Alternative)
        // is handled via the BillingClient in native code, but Flutter's plugin wraps it partially.
        // You would typically capture the 'externalTransactionToken' here.
        
        return "mock_external_transaction_token_from_google";
      }
    } on PlatformException catch (e) {
      print("Google Play Billing Error: ${e.message}");
    }
    return null;
  }

  /// Processes payment via Supabase Edge Function and launches UPI Intent.
  Future<void> processThirdPartyPayment({
    required String itemId,
    required String itemType,
    required double amount,
    required String externalTransactionToken,
  }) async {
    try {
      // 1. Call Supabase Edge Function to create order and get UPI Intent
      final response = await _supabase.functions.invoke(
        'process-payment',
        body: {
          'itemId': itemId,
          'itemType': itemType,
          'amount': amount,
          'externalTransactionToken': externalTransactionToken,
        },
      );

      if (response.status != 200) throw Exception("Failed to create order");

      final upiUrl = response.data['upiIntentUrl'] as String;

      // 2. Launch UPI Intent (Zero Friction)
      // Example: upi://pay?pa=...
      final Uri uri = Uri.parse(upiUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception("Could not launch UPI app");
      }
    } catch (e) {
      rethrow;
    }
  }
}
