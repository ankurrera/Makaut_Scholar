import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/billing_repository.dart';

class BillingRepositoryImpl implements BillingRepository {
  final InAppPurchase _iap = InAppPurchase.instance;
  late Razorpay _razorpay;
  final _supabase = Supabase.instance.client;
  
  // To keep track of the current alternative billing token if provided by Google
  String? _pendingExternalToken;
  String? _activeSupabaseOrderId;

  // Manual stream for alternative billing success notifications
  final StreamController<Map<String, dynamic>> _alternativePurchaseController = StreamController<Map<String, dynamic>>.broadcast();

  BillingRepositoryImpl() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    
    _initializeUserChoiceBilling();
  }

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  @override
  Stream<Map<String, dynamic>> get alternativePurchaseStream => _alternativePurchaseController.stream;

  @override
  Future<bool> isStoreAvailable() async {
    return await _iap.isAvailable();
  }

  @override
  Future<List<ProductDetails>> fetchProducts(Set<String> productIds) async {
    final ProductDetailsResponse response = await _iap.queryProductDetails(productIds);
    if (response.error != null) {
      throw response.error!;
    }
    return response.productDetails;
  }

  @override
  Future<void> launchBillingFlow(ProductDetails product) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    
    // On Android, if UCB is enabled, Google Play will show the choice dialog.
    // However, the standard buyNonConsumable handles both.
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> _initializeUserChoiceBilling() async {
    if (Platform.isAndroid) {
      final InAppPurchaseAndroidPlatformAddition androidAddition =
          _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      
      // Set the alternative billing listener if required by specific plugin versions
      // In current versions, the purchaseStream handles both types of events,
      // but specific UCB workflows might require platform-specific handling.
      // This is initialized to ensure the platform additions are active.
    }
  }

  @override
  Future<void> processRazorpayPayment({
    required String itemId,
    required String itemType,
    required double amount,
    String? externalTransactionToken,
  }) async {
    _pendingExternalToken = externalTransactionToken;
    try {
      // 1. Get Razorpay Order ID from Supabase Edge Function
      final response = await _supabase.functions.invoke(
        'create-razorpay-order',
        body: {
          'itemId': itemId,
          'itemType': itemType,
          'amount': amount,
          'externalTransactionToken': externalTransactionToken, // Pass token if UCB
        },
      );

      if (response.status != 200) throw Exception("Failed to create Razorpay order");

      final data = response.data;
      final String razorpayOrderId = data['razorpayOrderId'];
      final String keyId = data['keyId'];
      _activeSupabaseOrderId = data['orderId'];

      // 2. Open Razorpay Checkout
      var options = {
        'key': keyId,
        'amount': (amount * 100).toInt(),
        'name': 'MAKAUT Scholar',
        'order_id': razorpayOrderId,
        'description': 'Premium Purchase',
        'prefill': {
          'contact': _supabase.auth.currentUser?.phone ?? '',
          'email': _supabase.auth.currentUser?.email ?? ''
        },
        'external': {
          'wallets': ['paytm']
        }
      };

      _razorpay.open(options);
    } catch (e) {
      rethrow;
    }
  }

  void _handleRazorpaySuccess(PaymentSuccessResponse response) async {
    // 1. Manually emit a success event INSTANTLY to notify the UI without waiting for network
    _alternativePurchaseController.add({
      'status': 'purchased',
      'orderId': _activeSupabaseOrderId,
      'paymentId': response.paymentId,
    });

    // 2. Report Success to our Backend in the background
    try {
      await _supabase.functions.invoke(
        'report-play-billing-transaction',
        body: {
          'orderId': _activeSupabaseOrderId ?? response.orderId,
          'razorpayPaymentId': response.paymentId,
          'razorpaySignature': response.signature,
          'externalTransactionToken': _pendingExternalToken
        },
      );
    } catch (e) {
      print("Error reporting transaction: $e");
    }
  }

  void _handleRazorpayError(PaymentFailureResponse response) {
    print("Razorpay Error: ${response.code} - ${response.message}");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print("External Wallet: ${response.walletName}");
  }

  @override
  void dispose() {
    _razorpay.clear();
  }
}
