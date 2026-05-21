/// Paymob configuration
///
/// Get your credentials from: https://accept.paymob.com/portal2/en/settings
///
/// IMPORTANT: In production, use environment variables or secure storage
/// instead of hardcoding these values.
class PaymobConfig {
  PaymobConfig._();

  static const String apiKey =
      'ZXlKaGJHY2lPaUpJVXpVeE1pSXNJblI1Y0NJNklrcFhWQ0o5LmV5SmpiR0Z6Y3lJNklrMWxjbU5vWVc1MElpd2ljSEp2Wm1sc1pWOXdheUk2TVRFeE9UWXpNQ3dpYm1GdFpTSTZJbWx1YVhScFlXd2lmUS5RekdtaG1hQmxOWlFoZGpBYUt4aVJZcVpiQVlrNGc3T0x2OVlQMmZhR2JCanBaTk5XOUtxaTVfT1dtSWdXeHV4bkdOVlFKSjRqR1VxY3JhYTlMVm9wZw==';

  // Card payment integration ID
  static const int integrationId = 5456758;

  // Wallet payment integration ID (Vodafone Cash, etc.)
  static const int walletIntegrationId = 5456894;

  // iFrame ID for card payments
  // 993103: Installment & Discount support
  // 993104: Standard card iframe (with custom branding)
  static const int iFrameId = 993104;

  /// Check if Paymob is configured
  static bool get isConfigured =>
      apiKey.isNotEmpty && integrationId != 0 && iFrameId != 0;
}
