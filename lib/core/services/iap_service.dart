import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_service.dart';
import 'subscription_service.dart';

/// Google Play IDs.
///
/// Subscription:
/// - Product id: `premium`
/// - Base plans: `trial-monthly`, `yearly-premium`
///
/// One-time purchase:
/// - Product id: `premium_lifetime`
const _subProductIdPremium = 'premium';
const _subBasePlanMonthlyTrial = 'trial-monthly';
const _subBasePlanYearly = 'yearly-premium';
const _productIdLifetime = 'premium_lifetime';

const _productIds = {_subProductIdPremium, _productIdLifetime};

/// In-app purchase service for Android. No-op on other platforms.
class IapService {
  IapService._();

  static final IapService instance = IapService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  bool _initialized = false;
  bool _available = false;

  /// Increments when products list changes.
  final ValueNotifier<int> productsVersion = ValueNotifier<int>(0);

  /// Whether IAP is available (Android + Play Store).
  bool get isAvailable => _available;

  /// Loaded products for purchase.
  List<ProductDetails> get products => List.unmodifiable(_products);

  /// Initialize and restore previous purchases. Call once at app start.
  Future<void> init() async {
    if (_initialized) return;
    if (kIsWeb || !Platform.isAndroid) {
      _initialized = true;
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (_) {},
    );

    _available = await _iap.isAvailable();
    if (!_available) {
      _initialized = true;
      return;
    }

    await _loadProducts();
    await _restorePurchases(prefs);
    _initialized = true;
  }

  Future<void> _loadProducts() async {
    final response = await _iap.queryProductDetails(_productIds);
    if (response.notFoundIDs.isNotEmpty && response.productDetails.isEmpty) return;
    _products = response.productDetails;
    productsVersion.value++;
  }

  Future<void> _restorePurchases(SharedPreferences prefs) async {
    await _iap.restorePurchases();
    // restorePurchases triggers purchaseStream; _onPurchaseUpdate will set premium
  }

  Future<IapPurchaseResult> restore() async {
    if (kIsWeb || !Platform.isAndroid) return IapPurchaseResult.unavailable;
    if (!_available) return IapPurchaseResult.unavailable;
    await _iap.restorePurchases();
    return IapPurchaseResult.started;
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        SubscriptionService.upgradeToPremium();
        // Design analytics
        final isRestore = purchase.status == PurchaseStatus.restored;
        if (isRestore) {
          AnalyticsService.instance.logRestoreSuccess();
        } else {
          // productID might be 'premium' or 'premium_lifetime'
          AnalyticsService.instance.logPurchaseSuccess(plan: purchase.productID);
        }
        if (purchase.pendingCompletePurchase) {
          _iap.completePurchase(purchase);
        }
        break;
      }
    }
  }

  GooglePlayProductDetails? _subscriptionDetailsForBasePlan(String basePlanId) {
    for (final p in _products) {
      if (p is! GooglePlayProductDetails) continue;
      if (p.id != _subProductIdPremium) continue;
      final idx = p.subscriptionIndex;
      if (idx == null) continue;
      final offers = p.productDetails.subscriptionOfferDetails;
      if (offers == null || idx < 0 || idx >= offers.length) continue;
      if (offers[idx].basePlanId == basePlanId) {
        return p;
      }
    }
    return null;
  }

  SubscriptionOfferDetailsWrapper? _offerFor(GooglePlayProductDetails p) {
    final idx = p.subscriptionIndex;
    final offers = p.productDetails.subscriptionOfferDetails;
    if (idx == null || offers == null) return null;
    if (idx < 0 || idx >= offers.length) return null;
    return offers[idx];
  }

  static String _formatMoney(double value, {required String symbol}) {
    final abs = value.abs();
    final decimals = (abs - abs.roundToDouble()).abs() < 0.00001 ? 0 : 2;
    final nf = NumberFormat.currency(
      locale: 'ru',
      symbol: symbol,
      decimalDigits: decimals,
    );
    return nf.format(value);
  }

  /// UI pricing snapshot (nullable if products not loaded / unavailable).
  ///
  /// - trialMonthlyLine: `0 ₽ сегодня, затем 30 ₽ / месяц`
  /// - annualPrice: `2 390 ₽ / год`
  /// - annualOldPrice: `5 975 ₽ / год` (annual * 2.5)
  /// - annualBenefitPercent: e.g. 60
  /// - lifetimeLine: `2 990 ₽ — единоразово`
  Map<String, Object>? pricingSnapshot() {
    if (!_available) return null;

    // Monthly trial base plan: get currency from recurring phase.
    final monthly = _subscriptionDetailsForBasePlan(_subBasePlanMonthlyTrial);
    String? trialLine;
    if (monthly != null) {
      final offer = _offerFor(monthly);
      final phases = offer?.pricingPhases;
      // Expected: [trial(0), recurring(monthly)]
      PricingPhaseWrapper? recurring;
      if (phases != null && phases.isNotEmpty) {
        recurring = phases.length >= 2 ? phases[1] : phases.first;
      }
      if (recurring != null) {
        final symbol = monthly.currencySymbol;
        final after = recurring.formattedPrice;
        final zeroToday = '0 $symbol';
        trialLine = '$zeroToday сегодня, затем $after / месяц';
      }
    }

    // Annual base plan
    final yearly = _subscriptionDetailsForBasePlan(_subBasePlanYearly);
    String? annualPrice;
    String? annualOldPrice;
    int? benefit;
    if (yearly != null) {
      final offer = _offerFor(yearly);
      final phases = offer?.pricingPhases;
      PricingPhaseWrapper? recurring;
      if (phases != null && phases.isNotEmpty) {
        recurring = phases.first;
      }
      if (recurring != null) {
        final currentRaw = recurring.priceAmountMicros / 1000000.0;
        final symbol = yearly.currencySymbol;
        annualPrice = '${recurring.formattedPrice} / год';
        final oldRaw = currentRaw * 2.5;
        annualOldPrice = '${_formatMoney(oldRaw, symbol: symbol)} / год';
        final percent = (100 * (1 - (currentRaw / oldRaw))).round();
        benefit = percent.clamp(0, 99);
      }
    }

    // Lifetime
    final lifetime = _lifetimeDetails();
    String? lifetimeLine;
    if (lifetime != null) {
      lifetimeLine = '${lifetime.price} — единоразово';
    }

    if (trialLine == null && annualPrice == null && lifetimeLine == null) {
      return null;
    }
    return <String, Object>{
      if (trialLine != null) 'trialLine': trialLine,
      if (annualPrice != null) 'annualPrice': annualPrice,
      if (annualOldPrice != null) 'annualOldPrice': annualOldPrice,
      if (benefit != null) 'annualBenefit': benefit,
      if (lifetimeLine != null) 'lifetimeLine': lifetimeLine,
    };
  }

  GooglePlayProductDetails? _lifetimeDetails() {
    for (final p in _products) {
      if (p is GooglePlayProductDetails && p.id == _productIdLifetime) {
        return p;
      }
    }
    return null;
  }

  /// Purchase plan:
  /// - `trial_monthly`: subscription base plan `trial-monthly`
  /// - `yearly`: subscription base plan `yearly-premium`
  /// - `lifetime`: one-time `premium_lifetime`
  Future<IapPurchaseResult> purchasePlan(String plan) async {
    if (!_available) {
      return IapPurchaseResult.unavailable;
    }

    if (plan == 'lifetime') {
      final product = _lifetimeDetails();
      if (product == null) return IapPurchaseResult.productNotFound;
      final param = GooglePlayPurchaseParam(productDetails: product);
      final success = await _iap.buyNonConsumable(purchaseParam: param);
      return success ? IapPurchaseResult.started : IapPurchaseResult.failed;
    }

    final basePlanId = plan == 'yearly'
        ? _subBasePlanYearly
        : _subBasePlanMonthlyTrial;
    final product = _subscriptionDetailsForBasePlan(basePlanId);
    if (product == null) return IapPurchaseResult.productNotFound;

    final param = GooglePlayPurchaseParam(
      productDetails: product,
      offerToken: product.offerToken,
    );
    final success = await _iap.buyNonConsumable(purchaseParam: param);
    return success ? IapPurchaseResult.started : IapPurchaseResult.failed;
  }

  void dispose() {
    _subscription?.cancel();
  }
}

enum IapPurchaseResult {
  started,
  unavailable,
  productNotFound,
  failed,
}
