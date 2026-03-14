/// Central configuration for payment features.
///
/// Toggle [razorpayEnabled] to control Razorpay (Alternative Choice Billing)
/// availability without removing any integration code.
///
/// **Play Store review:** keep `razorpayEnabled = false` until Google approves
/// Alternative Billing for your account. Once approved, flip to `true` and
/// rebuild — no other changes required.
class PaymentConfig {
  PaymentConfig._();

  /// When `false`:
  ///   • Razorpay UI option is completely hidden on the checkout screen.
  ///   • Only Google Play Billing is presented to the user.
  ///   • Razorpay SDK is NOT initialised (saves resources).
  ///
  /// When `true`:
  ///   • Both Google Play Billing and Razorpay options are shown.
  ///   • Razorpay SDK is fully initialised and ready to process payments.
  static const bool razorpayEnabled = false;
}
