
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A store of consumable items.
///
/// This is a development prototype tha stores consumables in the shared
/// preferences. Do not use this in real world apps.
class ConsumableStore {
  static const String _kPrefKey = 'consumables';
  static Future<void> _writes = Future<void>.value();

  /// Adds a consumable with ID `id` to the store.
  ///
  /// The consumable is only added after the returned Future is complete.
  static Future<void> save(String id) {
    _writes = _writes.then((void _) => _doSave(id));
    return _writes;
  }

  /// Consumes a consumable with ID `id` from the store.
  ///
  /// The consumable was only consumed after the returned Future is complete.
  static Future<void> consume(String id) {
    _writes = _writes.then((void _) => _doConsume(id));
    return _writes;
  }

  /// Returns the list of consumables from the store.
  static Future<List<String>> load() async {
    return (await SharedPreferences.getInstance()).getStringList(_kPrefKey) ?? <String>[];
  }

  static Future<void> _doSave(String id) async {
    final List<String> cached = await load();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    cached.add(id);
    await prefs.setStringList(_kPrefKey, cached);
  }

  static Future<void> _doConsume(String id) async {
    final List<String> cached = await load();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    cached.remove(id);
    await prefs.setStringList(_kPrefKey, cached);
  }
}



const String _kMonthSubscriptionId = 'monthly_subscription';
const String _kYearSubscriptionId = 'year_subscription';
const List<String> _kProductIds = <String>[ _kMonthSubscriptionId, _kYearSubscriptionId,];

class PurchasePage extends StatefulWidget {
  const PurchasePage({Key? key}) : super(key: key);

  @override
  State<PurchasePage> createState() => PurchasePageState();
}

class PurchasePageState extends State<PurchasePage> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  List<String> _notFoundIds = <String>[];   /// ??????????????????ID
  List<ProductDetails> _products = <ProductDetails>[];   /// ????????????
  List<PurchaseDetails> _purchases = <PurchaseDetails>[]; /// ???????????????
  bool _isAvailable = false;  /// ??????????????????
  bool _purchasePending = false;  /// ?????????
  bool _loading = true; /// ????????????
  String? _queryProductError;  /// ??????????????????

  @override
  void initState() {
    final Stream<List<PurchaseDetails>> purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen((List<PurchaseDetails> purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      if (kDebugMode) { print('------ ------ purchaseUpdated.listen done'); }
      _subscription.cancel();
    }, onError: (Object error) {
      if (kDebugMode) { print('------ ------ purchaseUpdated.listen error: $error'); }
    });
    initStoreInfo();
    super.initState();
  }
  /// ??????????????????
  Future<void> initStoreInfo() async {
    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      setState(() {
        _isAvailable = isAvailable;
        _products = <ProductDetails>[];
        _purchases = <PurchaseDetails>[];
        _notFoundIds = <String>[];
        _purchasePending = false;
        _loading = false;
      });
      return;
    }

    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition = _inAppPurchase.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosPlatformAddition.setDelegate(ExamplePaymentQueueDelegate());
    }
    /// ??????????????????
    final ProductDetailsResponse productDetailResponse = await _inAppPurchase.queryProductDetails(_kProductIds.toSet());
    if (productDetailResponse.error != null) {
      setState(() {
        _queryProductError = productDetailResponse.error!.message;
        _isAvailable = isAvailable;
        _products = productDetailResponse.productDetails;
        _purchases = <PurchaseDetails>[];
        _notFoundIds = productDetailResponse.notFoundIDs;
        _purchasePending = false;
        _loading = false;
      });
      return;
    }

    if (productDetailResponse.productDetails.isEmpty) {
      setState(() {
        _queryProductError = null;
        _isAvailable = isAvailable;
        _products = productDetailResponse.productDetails;
        _purchases = <PurchaseDetails>[];
        _notFoundIds = productDetailResponse.notFoundIDs;
        _purchasePending = false;
        _loading = false;
      });
      return;
    }
    for(var p in productDetailResponse.productDetails){
      // id:year_subscription - title:???????????? - desc:???????????????????????? - price:??68 - rawPrice:68.0 - code:CNY - symbol:??
      if (kDebugMode) {
        print('id:${p.id} - title:${p.title} - desc:${p.description} - price:${p.price} - rawPrice:${p.rawPrice} - code:${p.currencyCode} - symbol:${p.currencySymbol}');
      }
    }
    setState(() {
      _isAvailable = isAvailable;
      _products = productDetailResponse.productDetails;
      _notFoundIds = productDetailResponse.notFoundIDs;
      _purchasePending = false;
      _loading = false;
    });
  }

  @override
  void dispose() {
    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition = _inAppPurchase.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      iosPlatformAddition.setDelegate(null);
    }
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> stack = <Widget>[];
    if (_queryProductError == null) {
      stack.add(ListView(children: <Widget>[_buildConnectionCheckTile(), _buildProductList(), _buildRestoreButton()]));
    } else {
      stack.add(Center(child: Text(_queryProductError!)));
    }
    if (_purchasePending) {
      stack.add(
        Stack(
          children: const <Widget>[
            Opacity(opacity: 0.3, child: ModalBarrier(dismissible: false, color: Colors.grey)),
            Center(child: CircularProgressIndicator())
          ]
        )
      );
    }
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('IAP Example'),),
        body: Stack(children: stack,),
      ),
    );
  }
  /// ????????????
  Card _buildConnectionCheckTile() {
    if (_loading) {
      return const Card(child: ListTile(title: Text('???????????? ...')));
    }
    final Widget storeHeader = ListTile(
      leading: Icon(_isAvailable ? Icons.check : Icons.block,
      color: _isAvailable ? Colors.green : ThemeData.light().colorScheme.error),
      title: Text('?????? ${_isAvailable ? '??????' : '?????????'}.'),
    );
    final List<Widget> children = <Widget>[storeHeader];

    if (!_isAvailable) {
      children.addAll(<Widget>[
        const Divider(),
        ListTile(title: Text('?????????', style: TextStyle(color: ThemeData.light().colorScheme.error)), subtitle: const Text('????????????????????????????????????'))
      ]);
    }
    return Card(child: Column(children: children));
  }
  /// ????????????
  Card _buildProductList() {
    if (_loading) {
      return const Card(child: ListTile(leading: CircularProgressIndicator(), title: Text('Fetching products...')));
    }
    if (!_isAvailable) {
      return const Card();
    }
    final List<ListTile> productList = <ListTile>[];
    if (_notFoundIds.isNotEmpty) {
      productList.add(ListTile(
        title: Text('[${_notFoundIds.join(", ")}] not found', style: TextStyle(color: ThemeData.light().colorScheme.error)),
        subtitle: const Text('This app needs special configuration to run. Please see example/README.md for instructions.'))
      );
    }

    // This loading previous purchases code is just a demo. Please do not use this as it is.
    // In your app you should always verify the purchase data using the `verificationData` inside the [PurchaseDetails] object before trusting it.
    // We recommend that you use your own server to verify the purchase data.
    final Map<String, PurchaseDetails> purchases = Map<String, PurchaseDetails>.fromEntries(
      _purchases.map((PurchaseDetails purchase) {
        if (purchase.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchase);
        }
        return MapEntry<String, PurchaseDetails>(purchase.productID, purchase);
      })
    );
    productList.addAll(_products.map((ProductDetails productDetails) {
      final PurchaseDetails? previousPurchase = purchases[productDetails.id];
      return ListTile(
        title: Text( productDetails.title, ),
        subtitle: Text( productDetails.description, ),
        trailing: previousPurchase != null ?
          IconButton(
            onPressed: () => confirmPriceChange(context),
            icon: const Icon(Icons.upgrade)
          ) :
          TextButton(
            style: TextButton.styleFrom( backgroundColor: Colors.green[800], primary: Colors.white,),
            onPressed: () {
              late PurchaseParam purchaseParam;
              if (Platform.isAndroid) {
                // ?????????????????????????????????/??????/????????????????????????????????????????????????????????????????????????????????????????????????????????????UI???????????????????????????????????????????????????????????????
                final GooglePlayPurchaseDetails? oldSubscription = _getOldSubscription(productDetails, purchases);
                purchaseParam = GooglePlayPurchaseParam(productDetails: productDetails, changeSubscriptionParam: (oldSubscription != null) ? ChangeSubscriptionParam(oldPurchaseDetails: oldSubscription, prorationMode: ProrationMode.immediateWithTimeProration,) : null);
              } else {
                purchaseParam = PurchaseParam( productDetails: productDetails, );
              }
              _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
            },
            child: Text(productDetails.price),
          ),
      );
    }));

    const ListTile productHeader = ListTile(title: Text('????????????'));
    return Card(child: Column(children: <Widget>[productHeader, const Divider()] + productList));
  }
  /// ??????????????????
  Widget _buildRestoreButton() {
    if (_loading) { return Container(); }
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          TextButton(
            style: TextButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, primary: Colors.white,),
            onPressed: () => _inAppPurchase.restorePurchases(),
            child: const Text('????????????'),
          ),
        ],
      ),
    );
  }

  /// ????????????
  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) {
    return Future<bool>.value(true);
  }
  /// ???????????????????????????????????????????????????
  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    setState(() {
      _purchases.add(purchaseDetails);
      _purchasePending = false;
    });
  }
  /// ??????????????????
  void _handleInvalidPurchase(PurchaseDetails purchaseDetails) {

  }
  /// ????????????????????????
  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) { /// ??????????????????????????????
        if (kDebugMode) { print('?????????:${purchaseDetails.status} - ${purchaseDetails.productID} - ${purchaseDetails.purchaseID} - ${purchaseDetails.transactionDate}'); }
        setState(() { _purchasePending = true; });
      } else if (purchaseDetails.status == PurchaseStatus.error || purchaseDetails.status == PurchaseStatus.canceled) { /// ????????????\??????
        if (kDebugMode) { print('???????????????:${purchaseDetails.status} - ${purchaseDetails.productID} - ${purchaseDetails.purchaseID} - ${purchaseDetails.transactionDate}'); }
        setState(() { _purchasePending = false; });
      } else if (purchaseDetails.status == PurchaseStatus.purchased || purchaseDetails.status == PurchaseStatus.restored) { /// ???????????????????????????
        final bool valid = await _verifyPurchase(purchaseDetails);
        if (valid) {  /// ????????????
          if (kDebugMode) { print('???????????????:${purchaseDetails.status} - ${purchaseDetails.productID} - ${purchaseDetails.purchaseID} - ${purchaseDetails.transactionDate}'); }
          _deliverProduct(purchaseDetails);
        } else {  /// ????????????
          if (kDebugMode) { print('???????????????(????????????):${purchaseDetails.status} - ${purchaseDetails.productID} - ${purchaseDetails.purchaseID} - ${purchaseDetails.transactionDate}'); }
          _handleInvalidPurchase(purchaseDetails);
          return;
        }
      }
      if (purchaseDetails.pendingCompletePurchase) {
        if (kDebugMode) { print('???????????????'); }
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }
  /// ????????????
  Future<void> confirmPriceChange(BuildContext context) async {
    if (Platform.isAndroid) {
      final InAppPurchaseAndroidPlatformAddition androidAddition = _inAppPurchase.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final BillingResultWrapper priceChangeConfirmationResult = await androidAddition.launchPriceChangeConfirmationFlow(sku: 'purchaseId',);
      if (priceChangeConfirmationResult.responseCode == BillingResponse.ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('???????????????')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(priceChangeConfirmationResult.debugMessage ?? 'Price change failed with code ${priceChangeConfirmationResult.responseCode}'),));
      }
    }
    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iapStoreKitPlatformAddition = _inAppPurchase.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iapStoreKitPlatformAddition.showPriceConsentIfNeeded();
    }
  }
  /// ?????????????????????????????????????????????
  GooglePlayPurchaseDetails? _getOldSubscription(ProductDetails productDetails, Map<String, PurchaseDetails> purchases) {
    //??????????????????????????????'subscription_silver'???'subscription_gold'?????????2????????????
    //??????'subscription_silver'???????????????'subscription_gold'?????????'subscription_gold'???????????????'subscription_silver'???
    //??????????????????????????????????????????????????????Id????????????
    //????????????????????????Android??????????????????????????????????????????iTunesConnect?????????????????????
    GooglePlayPurchaseDetails? oldSubscription;
    if (productDetails.id == _kMonthSubscriptionId && purchases[_kYearSubscriptionId] != null) {
      oldSubscription = purchases[_kYearSubscriptionId]! as GooglePlayPurchaseDetails;
    } else if (productDetails.id == _kYearSubscriptionId && purchases[_kMonthSubscriptionId] != null) {
      oldSubscription = purchases[_kMonthSubscriptionId]! as GooglePlayPurchaseDetails;
    }
    return oldSubscription;
  }
}

/// Example implementation of the
/// [`SKPaymentQueueDelegate`](https://developer.apple.com/documentation/storekit/skpaymentqueuedelegate?language=objc).
///
/// The payment queue delegate can be implementated to provide information needed to complete transactions.
/// ?????????????????????????????????????????????????????????????????????
class ExamplePaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(SKPaymentTransactionWrapper transaction, SKStorefrontWrapper storefront) {
    if (kDebugMode) {
      print('shouldContinueTransaction:${transaction.transactionIdentifier}');
    }
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}
