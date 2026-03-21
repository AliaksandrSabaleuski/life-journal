import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'subscription_service.dart';

/// Product IDs — create these in Google Play Console → Monetization → Products.
const _productIdMonthly = 'habit_journal_premium_monthly';
const _productIdAnnual = 'habit_journal_premium_annual';
const _productIdTrial = 'habit_journal_premium_trial';

const _productIds = {_productIdMonthly, _productIdAnnual, _productIdTrial};

/// Map UI plan to product ID.
String _productIdForPlan(String planName) {
  if (planName.contains('год') || planName.contains('годов') || planName == 'Ежегодно') {
    return _productIdAnnual;
  }
  if (planName.contains('месяц') || planName == 'Ежемесячно') {
    return _productIdMonthly;
  }
  return _productIdTrial;
}

/// In-app purchase service for Android. No-op on other platforms.
class IapService {
  IapService._();

  static final IapService instance = IapService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  bool _initialized = false;
  bool _available = false;

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
  }

  Future<void> _restorePurchases(SharedPreferences prefs) async {
    await _iap.restorePurchases();
    // restorePurchases triggers purchaseStream; _onPurchaseUpdate will set premium
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        SubscriptionService.upgradeToPremium();
        if (purchase.pendingCompletePurchase) {
          _iap.completePurchase(purchase);
        }
        break;
      }
    }
  }

  /// Purchase subscription. Returns true if purchase was initiated or completed.
  /// On success, SubscriptionService.isPremium becomes true.
  Future<IapPurchaseResult> purchase(String planName) async {
    if (!_available) {
      return IapPurchaseResult.unavailable;
    }

    final productId = _productIdForPlan(planName);
    final product = _products.where((p) => p.id == productId).firstOrNull;
    if (product == null) {
      return IapPurchaseResult.productNotFound;
    }

    final param = PurchaseParam(productDetails: product);
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
