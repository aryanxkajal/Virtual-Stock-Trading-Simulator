import 'dart:async';

import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_database/firebase_database.dart';

import 'package:flutter_application_1/model_calculation.dart';

import 'package:intl/intl.dart';

import '../global.dart' as globals;

class Portfolio extends StatefulWidget {
  const Portfolio({super.key});

  @override
  State<Portfolio> createState() => _PortfolioState();
}

class _PortfolioState extends State<Portfolio> {
  List<Map<String, dynamic>> listedFiltered = [];
  Map<String, Map<String, dynamic>> live_watchlist_real_time = {};

  List<StreamSubscription<DatabaseEvent>> _subscriptions = [];

  bool loading1 = true;

  List<Map<String, dynamic>> live = [];

  var stockData1 = <String, dynamic>{};
  final firestore = FirebaseFirestore.instance;

  List<String> stocksToFetch = [];
  TabController? _tabController;

  List<Order> ordersList = [];
  List<dynamic> name = [];

  Map<String, Map<String, dynamic>> orderAll = {};

  // Function to get orders from Firestore

  List<Map<String, dynamic>> listedAll = [];

  bool market = true;

  bool search = false;

  double totalProfit = 0;

  final TextEditingController _searchController = TextEditingController();

  bool buySell = false;

  final TextEditingController _quantityController = TextEditingController();

  int _navBar = 1;
  double funds = 0;

  @override
  void initState() {
    super.initState();

    //totalProfit = 0;

    fetchOrders();
    //_checkTime();
  }

  bool marketLive = true;

  _checkTime() {
    DateTime now = DateTime.now();
    if (now.hour >= 9.15 && now.hour <= 15.30) {
      marketLive = true;
    } else {
      marketLive = false;
    }
  }

  void fetchOrders() async {
    // Determine the correct document based on 'intradayLongterm'
    String docId = _navBar == 1 ? 'position' : 'holdings';
    DocumentReference docRef = firestore
        .collection('users')
        .doc(globals.userId)
        .collection('order_holding_position')
        .doc(docId);

    try {
      // Retrieve the current data
      DocumentSnapshot snapshot = await docRef.get();
      if (snapshot.exists) {
        Map<String, dynamic> currentData =
            snapshot.data() as Map<String, dynamic>;
        // print(currentData);

        for (var i in currentData.entries) {
          //print(i);
          orderAll[i.key] = {
            'price': i.value['price'],
            'quantity': i.value['quantity'],
            'intradayLongterm': i.value['intradayLongterm'],
            'instrument_token': i.value['instrument_token'],
            'instrument_type': i.value['instrument_type'],
            'segment': i.value['segment'],
            'profit': i.value['profit'],
          };

          stocksToFetch.add(i.value['instrument_token']);
        }
        listenToStocks(stocksToFetch);

        // Increment the quantity
      } else {}
    } catch (e) {
      print('1Error updating watchlist: $e');
      if (e is FirebaseException) {
        print('Error code: ${e.code}');
        print('Error message: ${e.message}');
      }
    }

    setState(() {});
  }

  void listenToStocks(List<String> stockNames) {
    for (String stockName in stockNames) {
      final DatabaseReference _dbRef =
          FirebaseDatabase.instance.ref('live_watchlist_real_time/$stockName');

      try {
        StreamSubscription<DatabaseEvent> subscription =
            _dbRef.onValue.listen((event) async {
          if (event.snapshot.exists && mounted) {
            // Update the stockData map with the new value
            setState(() {
              stockData1[stockName] = event.snapshot.value;
            });
          }
        });

        // Add the subscription to the list for later cleanup
        _subscriptions.add(subscription);
      } catch (e) {
        print(e);
      }
    }

    // After setting up all subscriptions, set loading1 to false if necessary
    if (mounted) {
      setState(() {
        loading1 = false;
      });
    }
  }

  void _addOrder(
      String symbol,
      String intradayLongterm1,
      String price,
      String quantity,
      String buySell,
      String instrument_token,
      String exchange,
      String instrument_type,
      String segment) async {
    // String formattedDateTime = DateFormat('dd MM yyyy HH mm ss').format(now);
    // print(formattedDateTime);

    try {
      await firestore
          .collection('users')
          .doc('${globals.userId}')
          .collection('order_holding_position')
          .doc('order')
          .collection('${DateFormat('dd MM yyyy').format(DateTime.now())}')
          .add({
        '${DateFormat('HH mm ss').format(DateTime.now())}': {
          'symbol': '$symbol',
          'buySell': '${buySell}',
          'quantity': '$quantity',
          'price': '${price.toString()}',
          'intradayLongterm': '${intradayLongterm1}',
          'instrument_token': '${instrument_token}',
          'exchange': '${exchange}',
          'instrument_type': '${instrument_type}',
          'segment': '${segment}',
        },
      });
    } catch (e) {
      print('Error updating watchlist: $e');
      if (e is FirebaseException) {
        print('Error code: ${e.code}');
        print('Error message: ${e.message}');
      }

      print('end');
    }
  }

  _updatePortfolio(
    String position,
    String symbol,
    String intradayLongterm1,
    String price,
    String quantity,
    String buySell,
    String instrument_token,
    String exchange,
    String instrument_type,
    String segment,
    double currentQuantity,
    double currentPrice,
  ) async {
    // Determine the correct document based on 'intradayLongterm'
    String docId = intradayLongterm1 == 'intraday' ? 'position' : 'holdings';
    DocumentReference docRef = firestore
        .collection('users')
        .doc(globals.userId)
        .collection('order_holding_position')
        .doc(docId);

    try {
      // Retrieve the current data
      double newQuantity = 0;
      double newPrice = 0;
      DocumentSnapshot snapshot = await docRef.get();

      if (snapshot.exists) {
        if (buySell == 'buy') {
          if (currentQuantity > 0 && position == 'existing') {
            print('4');
            newQuantity = currentQuantity + double.parse(quantity);
            newPrice = ((currentPrice * currentQuantity) +
                    (double.parse(price) * double.parse(quantity))) /
                (currentQuantity + double.parse(quantity));
          } else if ((currentQuantity < 0) &&
              (currentQuantity.abs() != double.parse(quantity))) {
            print('3');
            newQuantity = currentQuantity + double.parse(quantity);
            newPrice = ((currentPrice * currentQuantity) +
                    (double.parse(price) * double.parse(quantity))) /
                ((currentQuantity + double.parse(quantity)));
          } else if ((currentQuantity < 0) &&
              (currentQuantity.abs() == double.parse(quantity))) {
            print('1');
            newPrice = 0;
            newQuantity = 0;
          } else {
            print('2');
            newQuantity = double.parse(quantity);
            newPrice = double.parse(price);
          }
        } else if (buySell == 'sell') {
          if (currentQuantity < 0 && position == 'existing') {
            print('s4');
            newQuantity = currentQuantity - double.parse(quantity);
            newPrice = ((currentPrice * currentQuantity) -
                    (double.parse(price) * double.parse(quantity))) /
                (currentQuantity - double.parse(quantity));
          } else if ((currentQuantity > 0) &&
              (currentQuantity.abs() != double.parse(quantity))) {
            print('s3');
            newQuantity = currentQuantity - double.parse(quantity);
            newPrice = ((currentPrice * currentQuantity) -
                    (double.parse(price) * double.parse(quantity))) /
                ((currentQuantity - double.parse(quantity)));
          } else if ((currentQuantity > 0) &&
              (currentQuantity.abs() == double.parse(quantity))) {
            print('s1');
            newPrice = 0;
            newQuantity = 0;
          } else {
            print('s2');
            newQuantity = double.parse('-${quantity}');
            newPrice = double.parse(price);
          }
        }

        print('jh ${newPrice}');
        print(newQuantity);

        // Update the data
        await docRef.update({
          '$symbol.quantity': '${newQuantity}',
          '$symbol.price': '${newPrice}',
          '$symbol.intradayLongterm': intradayLongterm1,
          '$symbol.instrument_token': instrument_token,
          '$symbol.exchange': '${exchange}',
          '$symbol.instrument_type': '${instrument_type}',
          '$symbol.segment': '${segment}',
          '$symbol.date': '${DateFormat('dd MM yyyy').format(DateTime.now())}',
          '$symbol.profit': '0',
        });
      } else {
        // Document does not exist, set the initial data
        await docRef.set({
          symbol: {
            'quantity': quantity.toString(),
            'price': price.toString(),
            'intradayLongterm': intradayLongterm1.toString(),
            'instrument_token': instrument_token.toString(),
            'exchange': '${exchange}',
            'instrument_type': '${instrument_type}',
            'segment': '${segment}',
            'date': '${DateFormat('dd MM yyyy').format(DateTime.now())}',
            'profit': '0',
          },
        });
      }
    } catch (e) {
      print('E1rror updating watchlist: $e');
      if (e is FirebaseException) {
        print('Error code: ${e.code}');
        print('Error message: ${e.message}');
      }
    }
  }

  Future<bool> _manageWallet(
    String debitCredit,
    String price,
    String quantity,
    String userAdmin,
  ) async {
    double fund = await _fetchFunds();
    double amount = double.tryParse(price)! * double.tryParse(quantity)!;

    if (debitCredit == 'debit') {
      if (fund < amount) {
        return false;
      } else {
        try {
          await firestore
              .collection('users')
              .doc('${globals.userId}')
              .collection('details')
              .doc('wallet')
              .collection('${DateFormat('dd MM yyyy').format(DateTime.now())}')
              .add({
            '${DateFormat('HH mm ss').format(DateTime.now())}': {
              'debitCredit': '$debitCredit',
              'amount': '${amount}',
              'userAdmin': '$userAdmin',
              'price': '$price',
              'quantity': '$quantity',
            },
          });

          DocumentReference docRef = firestore
              .collection('users')
              .doc(globals.userId)
              .collection('details')
              .doc('wallet');

          double newAmount =
              debitCredit == 'debit' ? fund - amount : fund + amount;
          await docRef.update({
            'available_fund': newAmount.toString(),
          });

          print('end');
        } catch (e) {
          print(e);
        }
        return true;
      }
    } else {
      try {
        await firestore
            .collection('users')
            .doc('${globals.userId}')
            .collection('details')
            .doc('wallet')
            .collection('${DateFormat('dd MM yyyy').format(DateTime.now())}')
            .add({
          '${DateFormat('HH mm ss').format(DateTime.now())}': {
            'debitCredit': '$debitCredit',
            'amount': '${amount}',
            'userAdmin': '$userAdmin',
            'price': '$price',
            'quantity': '$quantity',
          },
        });

        DocumentReference docRef = firestore
            .collection('users')
            .doc(globals.userId)
            .collection('details')
            .doc('wallet');

        double newAmount =
            debitCredit == 'debit' ? fund - amount : fund + amount;
        await docRef.update({
          'available_fund': newAmount.toString(),
        });

        print('end');
      } catch (e) {
        print(e);
      }
      return true;
    }
  }

  Future<Map<String, double>> _fetchPosition(
      String intradayLongterm1, String symbol) async {
    String docId = intradayLongterm1 == 'intraday' ? 'position' : 'holdings';
    DocumentReference docRef = firestore
        .collection('users')
        .doc(globals.userId)
        .collection('order_holding_position')
        .doc(docId);

    DocumentSnapshot snapshot = await docRef.get();

    if (snapshot.exists) {
      Map<String, dynamic> currentData =
          snapshot.data() as Map<String, dynamic>;

      double currentQuantity = 0;
      double currentPrice = 0;
      // Check if the buySellStockSymbol already exists
      if (currentData.containsKey(symbol) &&
          currentData[symbol]['quantity'] != null) {
        currentQuantity = double.tryParse(currentData[symbol]['quantity'])!;
      }
      if (currentData.containsKey(symbol) &&
          currentData[symbol]['price'] != null) {
        currentPrice = double.tryParse(currentData[symbol]['price'])!;
      }
      return {'price': currentPrice, 'quantity': currentQuantity};
    } else {
      return {};
    }
  }

  Future<double> _fetchFunds() async {
    DocumentReference docRef = firestore
        .collection('users')
        .doc(globals.userId)
        .collection('details')
        .doc('wallet');
    DocumentSnapshot snapshot = await docRef.get();

    if (snapshot.exists) {
      Map<String, dynamic> currentData =
          snapshot.data() as Map<String, dynamic>;

      print(currentData['available_fund']);
      return double.tryParse(currentData['available_fund'])!;
    } else {
      return 0;
    }
  }

  @override
  void dispose() {
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: DefaultTabController(
          length: 2,
          initialIndex: 1,
          child: Scaffold(
              backgroundColor: Colors.white,
              body: Column(
                children: [
                  Container(
                      width: double.infinity,
                      padding: EdgeInsets.only(
                          left: width * 0.04,
                          right: width * 0.04,
                          top: height * 0.02,
                          bottom: height * 0.02),
                      alignment: Alignment.centerLeft,
                      child: RichText(
                        text: TextSpan(
                          children: <TextSpan>[
                            const TextSpan(
                              text: 'Portfolio',
                              style: TextStyle(
                                  fontSize: 20,
                                  color: Color.fromRGBO(63, 63, 63, 1),
                                  fontFamily: 'M-regular',
                                  fontWeight: FontWeight.w900),
                            ),
                            TextSpan(
                                text: marketLive == true ? ' Live' : ' Closed',
                                style: TextStyle(
                                    color: marketLive == true
                                        ? Colors.green
                                        : Colors.red,
                                    fontSize: 9,
                                    fontFamily: 'M-Bold')),
                          ],
                        ),
                      )),
                  Container(
                    alignment: Alignment.centerLeft,
                    child: TabBar(
                      //tabAlignment: TabAlignment.start,
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,

                      controller: _tabController,

                      onTap: (value) {
                        setState(() {
                          totalProfit = 0;
                          loading1 = true;

                          stockData1 = {};
                          totalProfit = 0;

                          _navBar = value;
                          orderAll = {};
                          fetchOrders();
                          loading1 = false;
                        });
                      },

                      indicatorPadding: EdgeInsets.only(
                          left: width * 0.12, right: width * 0.12),

                      isScrollable: false, // Enables horizontal scrolling
                      indicatorColor:
                          Colors.blue, // Color of the indicator line
                      labelColor:
                          Colors.blue, // Color of the text for selected tab
                      unselectedLabelColor: Color.fromARGB(182, 0, 0,
                          0), // Color of the text for unselected tabs
                      labelStyle: TextStyle(
                          fontSize: 14,
                          fontFamily: 'M-regular',
                          fontWeight: FontWeight.w600),
                      tabs: [
                        Tab(
                          text: 'Holdings',
                        ),
                        Tab(text: 'Positions'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _navBar == 0
                        ? Container(
                            child: Column(
                              children: [
                                Container(
                                    width: double.infinity,
                                    height: height * 0.12,
                                    margin: EdgeInsets.only(
                                        left: width * 0.04,
                                        right: width * 0.04,
                                        top: height * 0.02),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color.fromARGB(
                                                70, 158, 158, 158),
                                            // Color of the shadow
                                            offset: Offset
                                                .zero, // Offset of the shadow
                                            blurRadius:
                                                6, // Spread or blur radius of the shadow
                                            spreadRadius:
                                                0, // How much the shadow should spread
                                          )
                                        ]),
                                    child: Column(
                                      children: [
                                        Expanded(child: Container()),
                                        Text('Total P&L',
                                            style: TextStyle(
                                                color:
                                                    Color.fromARGB(98, 0, 0, 0),
                                                fontSize: 13,
                                                fontFamily: 'M-regular',
                                                fontWeight: FontWeight.w600)),
                                        SizedBox(height: 4),
                                        Text(
                                            '${totalProfit.toStringAsFixed(2)}',
                                            style: TextStyle(
                                                color: totalProfit > 0
                                                    ? Colors.green
                                                    : Colors.red,
                                                fontSize: 19,
                                                fontFamily: 'M-regular',
                                                fontWeight: FontWeight.w600)),
                                        Expanded(child: Container())
                                      ],
                                    )),
                                Expanded(
                                  child: loading1 == false
                                      ? Container(
                                          padding: EdgeInsets.only(
                                            left: width * 0.01,
                                            right: width * 0.01,
                                            top: 0,
                                          ),
                                          margin: EdgeInsets.only(top: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(20),
                                              topRight: Radius.circular(20),
                                            ),
                                          ),
                                          child: ListView.builder(
                                              itemCount: orderAll.length,
                                              itemBuilder:
                                                  (BuildContext context,
                                                      int index) {
                                                String key1 = orderAll.keys
                                                    .elementAt(index);

                                                String price1 =
                                                    orderAll[key1]!['price'];
                                                String quantity =
                                                    orderAll[key1]!['quantity'];

                                                String intradayLongterm =
                                                    orderAll[key1]![
                                                        'intradayLongterm'];

                                                String instrument_token =
                                                    orderAll[key1]![
                                                        'instrument_token'];

                                                double latest_price =
                                                    stockData1[instrument_token]
                                                            ?['last_price'] ??
                                                        0.0;

                                                //double value = 11.0;
                                                //  print(value);

                                                // endPrice = value.toString();
                                                return Column(
                                                  children: [
                                                    InkWell(
                                                      child:
                                                          _buildStockItemWatchlist(
                                                              instrument_token,
                                                              key1,
                                                              key1,
                                                              price1,
                                                              quantity,
                                                              intradayLongterm,
                                                              latest_price
                                                                  .toString(),
                                                              width,
                                                              height),
                                                    ),
                                                    const Divider(
                                                      color: Color.fromARGB(
                                                          22, 0, 0, 0),
                                                      thickness: 0.8,
                                                      height: 0,
                                                    ),
                                                  ],
                                                );
                                              }),
                                        )
                                      : Container(
                                          alignment: Alignment.center,
                                          child:
                                              const CircularProgressIndicator(
                                            color: Colors.blue,
                                            strokeWidth: 3,
                                          ),
                                        ),
                                )
                              ],
                            ),
                          )
                        : Container(
                            child: Column(
                              children: [
                                Container(
                                    width: double.infinity,
                                    height: height * 0.12,
                                    margin: EdgeInsets.only(
                                        left: width * 0.04,
                                        right: width * 0.04,
                                        top: height * 0.02),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color.fromARGB(
                                                70, 158, 158, 158),
                                            // Color of the shadow
                                            offset: Offset
                                                .zero, // Offset of the shadow
                                            blurRadius:
                                                6, // Spread or blur radius of the shadow
                                            spreadRadius:
                                                0, // How much the shadow should spread
                                          )
                                        ]),
                                    child: Column(
                                      children: [
                                        Expanded(child: Container()),
                                        Text('Total P&L',
                                            style: TextStyle(
                                                color:
                                                    Color.fromARGB(98, 0, 0, 0),
                                                fontSize: 13,
                                                fontFamily: 'M-regular',
                                                fontWeight: FontWeight.w600)),
                                        SizedBox(height: 4),
                                        Text(
                                            '${totalProfit.toStringAsFixed(2)}',
                                            style: TextStyle(
                                                color: totalProfit > 0
                                                    ? Colors.green
                                                    : Colors.red,
                                                fontSize: 19,
                                                fontFamily: 'M-regular',
                                                fontWeight: FontWeight.w600)),
                                        Expanded(child: Container())
                                      ],
                                    )),
                                Expanded(
                                  child: loading1 == false
                                      ? Container(
                                          padding: EdgeInsets.only(
                                            left: width * 0.01,
                                            right: width * 0.01,
                                            top: 0,
                                          ),
                                          margin: EdgeInsets.only(top: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(20),
                                              topRight: Radius.circular(20),
                                            ),
                                          ),
                                          child: ListView.builder(
                                              itemCount: orderAll.length,
                                              itemBuilder:
                                                  (BuildContext context,
                                                      int index) {
                                                String key1 = orderAll.keys
                                                    .elementAt(index);

                                                String instrument_token =
                                                    orderAll[key1]![
                                                        'instrument_token'];
                                                //print(instrument_token);

                                                String price1 =
                                                    orderAll[key1]!['price'];
                                                String quantity =
                                                    orderAll[key1]!['quantity'];

                                                String intradayLongterm =
                                                    orderAll[key1]![
                                                        'intradayLongterm'];

                                                double latest_price =
                                                    stockData1[instrument_token]
                                                            ?['last_price'] ??
                                                        0.0;

                                                return Column(
                                                  children: [
                                                    InkWell(
                                                      child:
                                                          _buildStockItemWatchlist(
                                                              instrument_token,
                                                              key1,
                                                              key1,
                                                              price1,
                                                              quantity,
                                                              intradayLongterm,
                                                              latest_price
                                                                  .toString(),
                                                              width,
                                                              height),
                                                    ),
                                                    const Divider(
                                                      color: Color.fromARGB(
                                                          22, 0, 0, 0),
                                                      thickness: 0.8,
                                                      height: 0,
                                                    ),
                                                  ],
                                                );
                                              }),
                                        )
                                      : Container(
                                          alignment: Alignment.center,
                                          child:
                                              const CircularProgressIndicator(
                                            color: Colors.blue,
                                            strokeWidth: 3,
                                          ),
                                        ),
                                )
                              ],
                            ),
                          ),
                  ),
                ],
              ))),
    );
  }

  bool openWatchlist = false;

  String _tapStock = '';
  String buySellStockSymbol = '';
  String buySellStockPrice = '';

  _calculateProfit(Map<String, double> pr) {
    double p = 0;
    totalProfit = 0;
    for (var i in pr.entries) {
      p += i.value;
      // print(i);
    }

    totalProfit = p;
    print(totalProfit);
  }

  Map<String, double> profitMap = {};
  Map<String, double> profitMap1 = {};

  String intradayLongterm = '';
  String error = '';

  Widget _buildStockItemWatchlist(
      String instrument_token,
      String date,
      String name,
      String avg_price,
      String quantity,
      String intradayLongterm1,
      String price,
      double width,
      double height) {
    Trade trade = Trade(
      instrument: Instrument(
          type: '${orderAll[name]!['instrument_type']}',
          segment: '${orderAll[name]!['segment']}'),
      entryPrice: double.parse(avg_price),
      exitPrice: intradayLongterm1 == 'longterm'
          ? double.parse(price)
          : double.parse(price) / 5,
      quantity: int.parse(quantity),
    );

    double profitLoss = TradeCalculator.calculateProfitLoss(trade);

    if (intradayLongterm1 == 'longterm') {
      profitMap1[instrument_token] = profitLoss;

      _calculateProfit(profitMap1);
    } else {
      profitMap[instrument_token] = profitLoss;

      _calculateProfit(profitMap);
    }

    intradayLongterm = intradayLongterm1.toLowerCase();

    return //_tapStock != name
        InkWell(
      onTap: () {
        /* setState(() {
                if (marketLive) {
                  if (_tapStock != '') {
                    _tapStock = '';
                    _quantityController.text = '';
                  } else {
                    _tapStock = name;
                    _quantityController.text = '1';
                  }
                }
              });*/
      },
      child: Container(
          padding: EdgeInsets.only(left: 17, right: 17, top: 15, bottom: 15),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: [
                      Container(
                        width: width * 0.08,
                        height: height * 0.026,
                        color: Colors.black12,
                        // padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        alignment: Alignment.center,
                        child: Text(
                          'Qty',
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'M-regular',
                              fontSize: 9),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('${quantity}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'M-regular',
                              fontSize: 10)),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text('${name}',
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: 'M-regular',
                      )),
                  SizedBox(height: 4),
                  Text('${orderAll[name]!['segment']}',
                      style: TextStyle(
                          color: Colors.grey,
                          fontFamily: 'M-regular',
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              Expanded(child: Container()),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: [
                      Text(
                          intradayLongterm == 'longterm'
                              ? '${double.parse(price).toStringAsFixed(2)}'
                              : '${(double.parse(price) / 5).toStringAsFixed(2)}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'M-regular',
                              fontSize: 10)),
                      SizedBox(width: 8),
                      Container(
                        // width: width * 0.15,
                        height: height * 0.026,
                        color: Colors.blue[50],
                        padding:
                            EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                        alignment: Alignment.center,
                        child: Text(
                          intradayLongterm == 'intraday'
                              ? 'INTRADAY'
                              : 'LONGTERM',
                          style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'M-regular',
                              fontSize: 9),
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        // width: width * 0.14,
                        height: height * 0.026,
                        color: double.parse(quantity) == 0
                            ? Colors.red[50]
                            : Colors.green[50],
                        padding:
                            EdgeInsets.symmetric(vertical: 0, horizontal: 9),
                        alignment: Alignment.center,
                        child: Text(
                          double.parse(quantity) == 0 ? 'CLOSED' : 'OPEN',
                          style: TextStyle(
                              color: double.parse(quantity) == 0
                                  ? Colors.red
                                  : Colors.green,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'M-regular',
                              fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                      double.parse(quantity) != 0
                          ? '${profitLoss.toStringAsFixed(2)}'
                          : '${double.parse(orderAll[name]!['profit']).toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 13,
                          color: profitLoss > 0 ? Colors.green : Colors.red,
                          fontFamily: 'M-regular',
                          fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text('Avg. ${double.parse(avg_price).toStringAsFixed(2)}',
                      style: TextStyle(
                          color: Colors.grey,
                          fontFamily: 'M-regular',
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          )),
    );
    /* : InkWell(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(
                    left: width * 0.03,
                    right: width * 0.03,
                    top: height * 0.02,
                    bottom: height * 0.02),
                child: Card(
                  //color: Colors.white,
                  elevation: 0,
                  color: Colors.white,
                  child: Container(
                    height: height * 0.29,
                    child: Padding(
                      padding: const EdgeInsets.all(0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: double.infinity,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '$name',
                                    style: TextStyle(
                                      fontFamily: 'M-regular',
                                      fontSize: 17,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Container(
                                  width: double.infinity,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '${price}',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontFamily: 'M-bold',
                                      //fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),
                                Container(
                                  width: double.infinity,
                                  //height: height * 0.06,
                                  padding: EdgeInsets.only(right: width * 0.04),
                                  child: TextFormField(
                                    keyboardType: TextInputType.number,
                                    controller: _quantityController,
                                    onChanged: (value) {
                                      print(value);
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'Quantity',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 18),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4.0,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Margin: ${intradayLongterm == 'longterm' ? '${price}' : '${(double.parse(price) / 5).toStringAsFixed(2)}'}/qty',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontFamily: 'M-bold',
                                        //fontWeight: FontWeight.w500,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4.0,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '${error}',
                                      style: TextStyle(
                                        color: error == 'Order Successful!'
                                            ? Colors.green
                                            : Colors.red,
                                        fontFamily: 'M-bold',
                                        //fontWeight: FontWeight.w500,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Column(
                                // mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          error = '';

                                          ////FETCH POSITION////
                                          Map<String, double> position =
                                              await _fetchPosition(
                                                  intradayLongterm, name);
                                          print(position);

                                          //////////////////////
                                          if ((position['price'] == 0 &&
                                                  position['quantity'] == 0) ||
                                              position.isEmpty) {
                                            bool fundSuccess = await _manageWallet(
                                                'debit',
                                                intradayLongterm == 'longterm'
                                                    ? '${price}'
                                                    : '${(double.parse(price) / 5)}',
                                                double.parse(_quantityController
                                                        .text)
                                                    .round()
                                                    .toString(),
                                                'admin');

                                            if (fundSuccess) {
                                              String price1 = '';
                                              if (intradayLongterm ==
                                                  'longterm') {
                                                price1 = '${price}';
                                              } else {
                                                price1 =
                                                    '${(double.parse(price) / 5)}';
                                              }

                                              _addOrder(
                                                  name,
                                                  intradayLongterm,
                                                  price1.toString(),
                                                  double.parse(
                                                          _quantityController
                                                              .text)
                                                      .round()
                                                      .toString(),
                                                  'buy',
                                                  instrument_token,
                                                  live_watchlist_real_time[
                                                          instrument_token]![
                                                      'exchange']!,
                                                  live_watchlist_real_time[
                                                          instrument_token]![
                                                      'instrument_type']!,
                                                  live_watchlist_real_time[
                                                          instrument_token]![
                                                      'segment']!);
                                              _updatePortfolio(
                                                  'new',
                                                  name,
                                                  intradayLongterm,
                                                  '${price1}',
                                                  double.parse(
                                                          _quantityController
                                                              .text)
                                                      .round()
                                                      .toString(),
                                                  'buy',
                                                  instrument_token,
                                                  live_watchlist_real_time[
                                                          instrument_token]![
                                                      'exchange']!,
                                                  live_watchlist_real_time[
                                                          instrument_token]![
                                                      'instrument_type']!,
                                                  live_watchlist_real_time[
                                                          instrument_token]![
                                                      'segment']!,
                                                  0,
                                                  0);
                                              setState(() {
                                                error = 'Order Successful!';
                                              });
                                            } else {
                                              setState(() {
                                                error = 'Insufficient funds!';
                                              });
                                            }

                                            print('no position added');
                                          } else if ((position['price'] != 0 &&
                                                  position['quantity'] != 0) &&
                                              position.isNotEmpty) {
                                            if (position['quantity']! > 0) {
                                              print(price);
                                              print(_quantityController.text);
                                              bool fundSuccess = await _manageWallet(
                                                  'debit',
                                                  intradayLongterm == 'longterm'
                                                      ? '${price}'
                                                      : '${(double.parse(price) / 5)}',
                                                  double.parse(
                                                          _quantityController
                                                              .text)
                                                      .round()
                                                      .toString(),
                                                  'admin');

                                              if (fundSuccess) {
                                                String price1 = '';
                                                if (intradayLongterm ==
                                                    'longterm') {
                                                  price1 = '${price}';
                                                } else {
                                                  price1 =
                                                      '${(double.parse(price) / 5)}';
                                                }

                                                _addOrder(
                                                    name,
                                                    intradayLongterm,
                                                    price1.toString(),
                                                    double.parse(
                                                            _quantityController
                                                                .text)
                                                        .round()
                                                        .toString(),
                                                    'buy',
                                                    instrument_token,
                                                    live_watchlist_real_time[
                                                            instrument_token]![
                                                        'exchange']!,
                                                    live_watchlist_real_time[
                                                            instrument_token]![
                                                        'instrument_type']!,
                                                    live_watchlist_real_time[
                                                            instrument_token]![
                                                        'segment']!);
                                                _updatePortfolio(
                                                    'existing',
                                                    name,
                                                    intradayLongterm,
                                                    '${price1}',
                                                    double.parse(
                                                            _quantityController
                                                                .text)
                                                        .round()
                                                        .toString(),
                                                    'buy',
                                                    instrument_token,
                                                    live_watchlist_real_time[
                                                            instrument_token]![
                                                        'exchange']!,
                                                    live_watchlist_real_time[
                                                            instrument_token]![
                                                        'instrument_type']!,
                                                    live_watchlist_real_time[
                                                            instrument_token]![
                                                        'segment']!,
                                                    position['quantity']!,
                                                    position['price']!);
                                                setState(() {
                                                  error = 'Order Successful!';
                                                });
                                              } else {
                                                setState(() {
                                                  error = 'Insufficient funds!';
                                                });
                                              }

                                              print('no position added');
                                            } else if (position['quantity']! <
                                                0) {
                                              if (position['quantity']!.abs() <
                                                  double.parse(
                                                      _quantityController
                                                          .text)) {
                                                error =
                                                    'User need to exit their current position of (${position['quantity']}) to change their position';
                                                setState(() {});
                                              } else {
                                                bool fundSuccess = await _manageWallet(
                                                    'credit',
                                                    intradayLongterm ==
                                                            'longterm'
                                                        ? '${price}'
                                                        : '${(double.parse(price) / 5)}',
                                                    double.parse(
                                                            _quantityController
                                                                .text)
                                                        .round()
                                                        .toString(),
                                                    'admin');

                                                if (fundSuccess) {
                                                  String price1 = '';
                                                  if (intradayLongterm ==
                                                      'longterm') {
                                                    price1 = '${price}';
                                                  } else {
                                                    price1 =
                                                        '${(double.parse(price) / 5)}';
                                                  }

                                                  _addOrder(
                                                      name,
                                                      intradayLongterm,
                                                      price1.toString(),
                                                      double.parse(
                                                              _quantityController
                                                                  .text)
                                                          .round()
                                                          .toString(),
                                                      'buy',
                                                      instrument_token,
                                                      live_watchlist_real_time[
                                                              instrument_token]![
                                                          'exchange']!,
                                                      live_watchlist_real_time[
                                                              instrument_token]![
                                                          'instrument_type']!,
                                                      live_watchlist_real_time[
                                                              instrument_token]![
                                                          'segment']!);
                                                  _updatePortfolio(
                                                      'existing',
                                                      name,
                                                      intradayLongterm,
                                                      '${price1}',
                                                      double.parse(
                                                              _quantityController
                                                                  .text)
                                                          .round()
                                                          .toString(),
                                                      'buy',
                                                      instrument_token,
                                                      live_watchlist_real_time[
                                                              instrument_token]![
                                                          'exchange']!,
                                                      live_watchlist_real_time[
                                                              instrument_token]![
                                                          'instrument_type']!,
                                                      live_watchlist_real_time[
                                                              instrument_token]![
                                                          'segment']!,
                                                      position['quantity']!,
                                                      position['price']!);
                                                  setState(() {
                                                    error = 'Order Successful!';
                                                  });
                                                } else {
                                                  setState(() {
                                                    error =
                                                        'Insufficient funds!';
                                                  });
                                                }

                                                print('no position added');
                                              }
                                            }
                                          }
                                        },
                                        child: const Text('BUY'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 32, vertical: 16),
                                          textStyle: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          error = '';
                                          print(name);

                                          ////FETCH POSITION////
                                          Map<String, double> position =
                                              await _fetchPosition(
                                                  intradayLongterm, name);

                                          //////////////////////
                                          if ((position['price'] == 0 &&
                                                  position['quantity'] == 0) ||
                                              position.isEmpty) {
                                            ////NO POSITION////

                                            bool fundSuccess = await _manageWallet(
                                                'debit',
                                                intradayLongterm == 'longterm'
                                                    ? '${price}'
                                                    : '${(double.parse(price) / 5)}',
                                                double.parse(_quantityController
                                                        .text)
                                                    .round()
                                                    .toString(),
                                                'admin');

                                            if (fundSuccess) {
                                              String price1 = '';
                                              if (intradayLongterm ==
                                                  'longterm') {
                                                price1 = '${price}';
                                              } else {
                                                price1 =
                                                    '${(double.parse(price) / 5)}';
                                              }

                                              _addOrder(
                                                  name,
                                                  intradayLongterm,
                                                  price1.toString(),
                                                  double.parse(
                                                          _quantityController
                                                              .text)
                                                      .round()
                                                      .toString(),
                                                  'sell',
                                                  instrument_token,
                                                  live_watchlist_real_time[
                                                          instrument_token]![
                                                      'exchange']!,
                                                  live_watchlist_real_time[
                                                          instrument_token]![
                                                      'instrument_type']!,
                                                  live_watchlist_real_time[
                                                          instrument_token]![
                                                      'segment']!);
                                              _updatePortfolio(
                                                  'new',
                                                  name,
                                                  intradayLongterm,
                                                  '${price1}',
                                                  double.parse(
                                                          _quantityController
                                                              .text)
                                                      .round()
                                                      .toString(),
                                                  'sell',
                                                  instrument_token,
                                                  live_watchlist_real_time[
                                                          instrument_token]![
                                                      'exchange']!,
                                                  live_watchlist_real_time[
                                                          instrument_token]![
                                                      'instrument_type']!,
                                                  live_watchlist_real_time[
                                                          instrument_token]![
                                                      'segment']!,
                                                  0,
                                                  0);
                                              setState(() {
                                                error = 'Order Successful!';
                                              });
                                            } else {
                                              setState(() {
                                                error = 'Insufficient funds!';
                                              });
                                            }

                                            print('no position added');
                                          } else if ((position['price'] != 0 &&
                                                  position['quantity'] != 0) &&
                                              position.isNotEmpty) {
                                            if (position['quantity']! < 0) {
                                              bool fundSuccess = await _manageWallet(
                                                  'debit',
                                                  intradayLongterm == 'longterm'
                                                      ? '${price}'
                                                      : '${(double.parse(price) / 5)}',
                                                  double.parse(
                                                          _quantityController
                                                              .text)
                                                      .round()
                                                      .toString(),
                                                  'admin');

                                              if (fundSuccess) {
                                                String price1 = '';
                                                if (intradayLongterm ==
                                                    'longterm') {
                                                  price1 = '${price}';
                                                } else {
                                                  price1 =
                                                      '${(double.parse(price) / 5)}';
                                                }

                                                _addOrder(
                                                    name,
                                                    intradayLongterm,
                                                    price1.toString(),
                                                    double.parse(
                                                            _quantityController
                                                                .text)
                                                        .round()
                                                        .toString(),
                                                    'sell',
                                                    instrument_token,
                                                    live_watchlist_real_time[
                                                            instrument_token]![
                                                        'exchange']!,
                                                    live_watchlist_real_time[
                                                            instrument_token]![
                                                        'instrument_type']!,
                                                    live_watchlist_real_time[
                                                            instrument_token]![
                                                        'segment']!);
                                                _updatePortfolio(
                                                    'existing',
                                                    name,
                                                    intradayLongterm,
                                                    '${price1}',
                                                    double.parse(
                                                            _quantityController
                                                                .text)
                                                        .round()
                                                        .toString(),
                                                    'sell',
                                                    instrument_token,
                                                    live_watchlist_real_time[
                                                            instrument_token]![
                                                        'exchange']!,
                                                    live_watchlist_real_time[
                                                            instrument_token]![
                                                        'instrument_type']!,
                                                    live_watchlist_real_time[
                                                            instrument_token]![
                                                        'segment']!,
                                                    position['quantity']!,
                                                    position['price']!);
                                                setState(() {
                                                  error = 'Order Successful!';
                                                });
                                              } else {
                                                setState(() {
                                                  error = 'Insufficient funds!';
                                                });
                                              }

                                              print('no position added');
                                            } else if (position['quantity']! >
                                                0) {
                                              if (position['quantity']!.abs() <
                                                  double.parse(
                                                      _quantityController
                                                          .text)) {
                                                error =
                                                    'User need to exit their current position of (${position['quantity']}) to change their position';
                                                setState(() {});
                                              } else {
                                                bool fundSuccess = await _manageWallet(
                                                    'credit',
                                                    intradayLongterm ==
                                                            'longterm'
                                                        ? '${price}'
                                                        : '${(double.parse(price) / 5)}',
                                                    double.parse(
                                                            _quantityController
                                                                .text)
                                                        .round()
                                                        .toString(),
                                                    'admin');

                                                if (fundSuccess) {
                                                  String price1 = '';
                                                  if (intradayLongterm ==
                                                      'longterm') {
                                                    price1 = '${price}';
                                                  } else {
                                                    price1 =
                                                        '${(double.parse(price) / 5)}';
                                                  }

                                                  _addOrder(
                                                      name,
                                                      intradayLongterm,
                                                      price1.toString(),
                                                      double.parse(
                                                              _quantityController
                                                                  .text)
                                                          .round()
                                                          .toString(),
                                                      'sell',
                                                      instrument_token,
                                                      live_watchlist_real_time[
                                                              instrument_token]![
                                                          'exchange']!,
                                                      live_watchlist_real_time[
                                                              instrument_token]![
                                                          'instrument_type']!,
                                                      live_watchlist_real_time[
                                                              instrument_token]![
                                                          'segment']!);
                                                  _updatePortfolio(
                                                      'existing',
                                                      name,
                                                      intradayLongterm,
                                                      '${price1}',
                                                      double.parse(
                                                              _quantityController
                                                                  .text)
                                                          .round()
                                                          .toString(),
                                                      'sell',
                                                      instrument_token,
                                                      live_watchlist_real_time[
                                                              instrument_token]![
                                                          'exchange']!,
                                                      live_watchlist_real_time[
                                                              instrument_token]![
                                                          'instrument_type']!,
                                                      live_watchlist_real_time[
                                                              instrument_token]![
                                                          'segment']!,
                                                      position['quantity']!,
                                                      position['price']!);
                                                  setState(() {
                                                    error = 'Order Successful!';
                                                  });
                                                } else {
                                                  setState(() {
                                                    error =
                                                        'Insufficient funds!';
                                                  });
                                                }

                                                print('no position added');
                                              }
                                            }
                                          }
                                        },
                                        child: const Text('SELL'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 32, vertical: 16),
                                          textStyle: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            onTap: () {},
          );
 */
  }
}
