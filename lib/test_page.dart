
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
  List<String> _notFoundIds = <String>[];   /// 未发现的商品ID
  List<ProductDetails> _products = <ProductDetails>[];   /// 商品列表
  List<PurchaseDetails> _purchases = <PurchaseDetails>[]; /// 已购买列表
  bool _isAvailable = false;  /// 商店是否可用
  bool _purchasePending = false;  /// 支付中
  bool _loading = true; /// 初始化中
  String? _queryProductError;  /// 获取商品失败

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
  /// 加载商品信息
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
    /// 请求商品详情
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
      // id:year_subscription - title:年度订阅 - desc:高级版，年度订阅 - price:¥68 - rawPrice:68.0 - code:CNY - symbol:¥
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
  /// 购买状态
  Card _buildConnectionCheckTile() {
    if (_loading) {
      return const Card(child: ListTile(title: Text('尝试连接 ...')));
    }
    final Widget storeHeader = ListTile(
      leading: Icon(_isAvailable ? Icons.check : Icons.block,
      color: _isAvailable ? Colors.green : ThemeData.light().colorScheme.error),
      title: Text('商店 ${_isAvailable ? '可用' : '不可用'}.'),
    );
    final List<Widget> children = <Widget>[storeHeader];

    if (!_isAvailable) {
      children.addAll(<Widget>[
        const Divider(),
        ListTile(title: Text('未连接', style: TextStyle(color: ThemeData.light().colorScheme.error)), subtitle: const Text('无法连接到支付处理程序。'))
      ]);
    }
    return Card(child: Column(children: children));
  }
  /// 商品列表
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
                // 如果您正在进行订阅购买/升级/降级，我们建议您使用服务器端收据验证验证您的订阅的最新状态，并相应地更新UI。应用程序内显示的订阅购买状态可能不准确。
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

    const ListTile productHeader = ListTile(title: Text('商品列表'));
    return Card(child: Column(children: <Widget>[productHeader, const Divider()] + productList));
  }
  /// 恢复购买按钮
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
            child: const Text('恢复购买'),
          ),
        ],
      ),
    );
  }

  /// 凭证校验
  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) {
    return Future<bool>.value(true);
  }
  /// 校验通过，购买成功，交付产品给用户
  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    setState(() {
      _purchases.add(purchaseDetails);
      _purchasePending = false;
    });
  }
  /// 凭证校验失败
  void _handleInvalidPurchase(PurchaseDetails purchaseDetails) {

  }
  /// 购买相关事件处理
  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) { /// 购买中，加载购买窗口
        if (kDebugMode) { print('购买中:${purchaseDetails.status} - ${purchaseDetails.productID} - ${purchaseDetails.purchaseID} - ${purchaseDetails.transactionDate}'); }
        setState(() { _purchasePending = true; });
      } else if (purchaseDetails.status == PurchaseStatus.error || purchaseDetails.status == PurchaseStatus.canceled) { /// 购买失败\取消
        if (kDebugMode) { print('购买未成功:${purchaseDetails.status} - ${purchaseDetails.productID} - ${purchaseDetails.purchaseID} - ${purchaseDetails.transactionDate}'); }
        setState(() { _purchasePending = false; });
      } else if (purchaseDetails.status == PurchaseStatus.purchased || purchaseDetails.status == PurchaseStatus.restored) { /// 购买成功、恢复成功
        final bool valid = await _verifyPurchase(purchaseDetails);
        if (valid) {  /// 校验通过
          if (kDebugMode) { print('已购买商品:${purchaseDetails.status} - ${purchaseDetails.productID} - ${purchaseDetails.purchaseID} - ${purchaseDetails.transactionDate}'); }
          _deliverProduct(purchaseDetails);
        } else {  /// 校验失败
          if (kDebugMode) { print('已购买商品(校验失败):${purchaseDetails.status} - ${purchaseDetails.productID} - ${purchaseDetails.purchaseID} - ${purchaseDetails.transactionDate}'); }
          _handleInvalidPurchase(purchaseDetails);
          return;
        }
      }
      if (purchaseDetails.pendingCompletePurchase) {
        if (kDebugMode) { print('购买结束！'); }
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }
  /// 升级订阅
  Future<void> confirmPriceChange(BuildContext context) async {
    if (Platform.isAndroid) {
      final InAppPurchaseAndroidPlatformAddition androidAddition = _inAppPurchase.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final BillingResultWrapper priceChangeConfirmationResult = await androidAddition.launchPriceChangeConfirmationFlow(sku: 'purchaseId',);
      if (priceChangeConfirmationResult.responseCode == BillingResponse.ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('价格变化了')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(priceChangeConfirmationResult.debugMessage ?? 'Price change failed with code ${priceChangeConfirmationResult.responseCode}'),));
      }
    }
    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iapStoreKitPlatformAddition = _inAppPurchase.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iapStoreKitPlatformAddition.showPriceConsentIfNeeded();
    }
  }
  /// 安卓获取需要升级或者降级的商品
  GooglePlayPurchaseDetails? _getOldSubscription(ProductDetails productDetails, Map<String, PurchaseDetails> purchases) {
    //此方法假设您在一个组'subscription_silver'和'subscription_gold'下只有2个订阅。
    //订阅'subscription_silver'可以升级为'subscription_gold'，订阅'subscription_gold'可以降级为'subscription_silver'。
    //请记住根据您的应用程序替换查找旧订阅Id的逻辑。
    //旧的订阅只需要在Android上，因为苹果处理这个内部使用iTunesConnect的订阅组功能。
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
/// 可以实现支付队列委托来提供完成事务所需的信息。
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
