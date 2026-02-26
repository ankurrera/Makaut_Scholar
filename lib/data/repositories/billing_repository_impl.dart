import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';

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
  Future<void> launchBillingFlow(ProductDetails product, {String? orderId}) async {
    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: product,
      applicationUserName: orderId, // Used to link this purchase to our Supabase order
    );
    
    _activeSupabaseOrderId = orderId;
    // Use buyConsumable since we use generic price-tier products
    await _iap.buyConsumable(purchaseParam: purchaseParam, autoConsume: true);
  }

  Future<void> _initializeUserChoiceBilling() async {
    if (Platform.isAndroid) {
      // Listen to Google Play purchase updates and auto-report to backend
      _iap.purchaseStream.listen((purchases) {
        for (var purchase in purchases) {
          if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
            if (purchase.pendingCompletePurchase) {
              _iap.completePurchase(purchase);
            }
            // Report to backend in background
            _reportGooglePlayPurchase(purchase);
          }
        }
      });
    }
  }

  Future<void> _reportGooglePlayPurchase(PurchaseDetails purchase) async {
    try {
      await _supabase.functions.invoke(
        'report-play-billing-transaction',
        body: {
          'orderId': _activeSupabaseOrderId ?? purchase.purchaseID,
          'razorpayPaymentId': purchase.purchaseID,
          'razorpaySignature': null,
          'externalTransactionToken': null,
        },
      );
    } catch (e) {
      print('Error reporting Google Play purchase: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> createOrder({
    required String itemId,
    required String itemType,
    required double amount,
    required String gateway,
  }) async {
    final response = await _supabase.functions.invoke(
      'create-razorpay-order',
      body: {
        'itemId': itemId,
        'itemType': itemType,
        'amount': amount,
        'gateway': gateway,
      },
    );

    if (response.status != 200) throw Exception('Failed to create order');
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<void> processRazorpayPayment({
    required String razorpayOrderId,
    required String internalOrderId,
    required String keyId,
    required double amount,
    String? externalTransactionToken,
  }) async {
    _pendingExternalToken = externalTransactionToken;
    _activeSupabaseOrderId = internalOrderId;
    try {
      // Open Razorpay Checkout using the already-created order
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
