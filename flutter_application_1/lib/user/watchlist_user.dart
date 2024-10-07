import 'dart:async';

import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_database/firebase_database.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../global.dart' as globals;

class WatchList extends StatefulWidget {
  const WatchList({super.key});

  @override
  State<WatchList> createState() => _WatchListState();
}

class _WatchListState extends State<WatchList> {
  @override
  void initState() {
    super.initState();

    _fetchWatchlist();
    _checkLimit();

    //_checkTime();
  }

  List<Map<String, dynamic>> listedFiltered = [];

  Map<String, Map<String, dynamic>> live_watchlist_real_time = {};

  List<Map<String, dynamic>> live = [];

  var stockData1 = <String, dynamic>{};
  final firestore = FirebaseFirestore.instance;

  List<String> stocksToFetch = [];
  bool loading = false;
  bool loading1 = false;
  List<Map<String, dynamic>> listedAll = [];

  List<Map<String, dynamic>> searchResults = [];
  bool buySell = false;

  final TextEditingController _quantityController = TextEditingController();

  bool market = true;

  bool search = false;
  String error = '';
  List<StreamSubscription<DatabaseEvent>> _subscriptions = [];
  final TextEditingController _searchController = TextEditingController();
  FocusNode _SearchFocusNode = FocusNode();
  double funds = 0;

  bool marketLive = true;

  _checkTime() {
    DateTime now = DateTime.now();
    if (now.hour >= 9.15 && now.hour <= 15.30) {
      marketLive = true;
    } else {
      marketLive = false;
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

  void _fetchWatchlist() async {
    setState(() {
      live_watchlist_real_time = {};
      stocksToFetch = [];
      stockData1 = {};
      loading1 = true;
    });
    try {
      await firestore
          .collection('users')
          .doc('${globals.userId}')
          .get()
          .then((DocumentSnapshot documentSnapshot) async {
        if (documentSnapshot.exists) {
          Map<String, dynamic> data =
              documentSnapshot.data() as Map<String, dynamic>;

          // Access watchlist1
          List<String> watchlist1 = List<String>.from(data['watchlist1']);

          for (var i in watchlist1) {
            live_watchlist_real_time[i] = await detailsInstrumentToken(i);
          }

          stocksToFetch = watchlist1;

          listenToStocks(stocksToFetch);
        } else {
          print('Document does not exist on the database');
        }
      });
    } catch (e) {}
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
              // Update your state here
              // This could be a good place to update a state management provider,
              // or call setState if you're handling state locally in this widget.
            });
          } else {
            // If the snapshot doesn't exist, remove the stock from the map
            stockData1[stockName] = {
              'last_price': 0,
              'change': 0,
            };
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

  void performSearch(String query) async {
    setState(() {
      loading = true;
    });
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('stock_data_master')
          .where('tradingsymbol', isGreaterThanOrEqualTo: query)
          .where('tradingsymbol', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      final instruments = querySnapshot.docs.map((doc) => doc.data()).toList();

      listedFiltered = instruments;
    } catch (e) {
      print(e);
    }
    setState(() {
      loading = false;
    });
  }

  Future<Map<String, dynamic>> detailsInstrumentToken(
      String instrument_token) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('stock_data_master')
          .where('instrument_token',
              isEqualTo: int.parse(
                  instrument_token)) // Assuming 'exchangeId' is the integer field you're querying
          .get();

      final instruments = querySnapshot.docs.map((doc) => doc.data()).toList();
      //print(instruments);
      return instruments[0];
      //updateUI(instruments);
    } catch (e) {
      print(e);
      setState(() {
        loading = false;
      });
      return {};
    }
  }

  void _updateWatchlistUser(
      String stockName, String writeDelete, String instrument_token) async {
    writeDelete == 'write'
        ? stocksToFetch.add(instrument_token)
        : stocksToFetch.remove(instrument_token);
    if (writeDelete == 'write') {
      try {
        await firestore.collection('users').doc('${globals.userId}').set(
          {'watchlist1': FieldValue.arrayUnion(stocksToFetch)},
        );
      } catch (e) {
        print('Error updating watchlist: $e');
        if (e is FirebaseException) {
          print('Error code: ${e.code}');
          print('Error message: ${e.message}');
        }
      }
    } else if (writeDelete == 'delete') {
      try {
        await firestore.collection('users').doc('${globals.userId}').update(
          {
            'watchlist1': FieldValue.arrayRemove([instrument_token])
          },
        );
      } catch (e) {
        print('Error updating watchlist: $e');
        if (e is FirebaseException) {
          print('Error code: ${e.code}');
          print('Error message: ${e.message}');
        }
      }
    }
    setState(() {});
  }

  void _updateWatchlistGlobal(
      String stockName, String writeDelete, String instrument_token) async {
    if (writeDelete == 'write') {
      final DatabaseReference databaseReference =
          FirebaseDatabase.instance.ref();
      DatabaseReference nseCompanyListedRef =
          databaseReference.child('live_watchlist/${instrument_token}');

      try {
        await nseCompanyListedRef.set(instrument_token);
      } catch (e) {
        print(e);
      }
    } else if (writeDelete == 'delete') {
      final DatabaseReference databaseReference =
          FirebaseDatabase.instance.ref();
      DatabaseReference nseCompanyListedRef =
          databaseReference.child('live_watchlist/${instrument_token}');

      try {
        await nseCompanyListedRef.remove();
      } catch (e) {
        print(e);
      }
    }
    setState(() {});
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
        } catch (e) {}
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
      } catch (e) {}
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

  @override
  void dispose() {
    _searchController.dispose();
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
          length: 4,
          child: Scaffold(
              backgroundColor: Colors.white,
              body: search == false
                  ? Column(
                      children: [
                        Container(
                            width: double.infinity,
                            padding: EdgeInsets.only(
                                left: width * 0.04,
                                right: width * 0.04,
                                top: height * 0.02,
                                bottom: height * 0),
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                RichText(
                                  text: TextSpan(
                                    children: <TextSpan>[
                                      const TextSpan(
                                        text: 'Watchlist',
                                        style: TextStyle(
                                            fontSize: 20,
                                            color:
                                                Color.fromRGBO(63, 63, 63, 1),
                                            fontFamily: 'M-regular',
                                            fontWeight: FontWeight.w900),
                                      ),
                                      TextSpan(
                                          text: marketLive == true
                                              ? ' Live'
                                              : ' Closed',
                                          style: TextStyle(
                                              color: marketLive == true
                                                  ? Colors.green
                                                  : Colors.red,
                                              fontSize: 9,
                                              fontFamily: 'M-Bold')),
                                    ],
                                  ),
                                ),
                                Expanded(child: Container()),
                                IconButton(
                                    onPressed: () {},
                                    icon: const Icon(
                                      Icons.sort,
                                      color: Colors.white,
                                    )),
                              ],
                            )),
                        Container(
                          width: double.infinity,
                          height: height * 0.07,
                          margin: EdgeInsets.only(
                              left: width * 0.04,
                              right: width * 0.04,
                              top: height * 0.02),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromARGB(70, 158, 158, 158),
                                  // Color of the shadow
                                  offset: Offset.zero, // Offset of the shadow
                                  blurRadius:
                                      6, // Spread or blur radius of the shadow
                                  spreadRadius:
                                      0, // How much the shadow should spread
                                )
                              ]),
                          child: TextField(
                            // enabled: false,
                            onTap: () {
                              setState(() {
                                search = true;
                                _searchController.clear();
                                _SearchFocusNode.requestFocus();
                              });
                            },
                            decoration: InputDecoration(
                              hintText:
                                  'Search & add to watchlist  (${live_watchlist_real_time.length}/15)',
                              hintStyle: const TextStyle(
                                  color: Color.fromRGBO(146, 146, 168, 1),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'M-regular'),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Color.fromRGBO(146, 146, 168, 1),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 0),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.only(
                              left: width * 0.01,
                              right: width * 0.01,
                              top: height * 0,
                            ),
                            margin: EdgeInsets.only(top: height * 0.008),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                            ),
                            child: loading1 == false
                                ? ListView.builder(
                                    itemCount: stockData1.length,
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                      String key =
                                          stockData1.keys.elementAt(index);

                                      String name = live_watchlist_real_time[
                                          key]!['tradingsymbol']!;
                                      String exchange =
                                          live_watchlist_real_time[key]![
                                              'exchange']!;

                                      double price =
                                          stockData1[key]['last_price']! ?? 0;
                                      double change =
                                          stockData1[key]['change']! ?? 0;

                                      // print(stockData1[key]!);
                                      return Column(
                                        children: [
                                          InkWell(
                                            child: _buildStockItemWatchlist(
                                                '${key}',
                                                '${name}',
                                                '${exchange}',
                                                '${price}',
                                                '${change.toStringAsFixed(2)}',
                                                Colors.green,
                                                index,
                                                width,
                                                height),
                                          ),
                                          const Divider(
                                            color: Color.fromARGB(22, 0, 0, 0),
                                            thickness: 0.8,
                                            height: 0,
                                          ),
                                        ],
                                      );
                                    })
                                : Container(
                                    alignment: Alignment.center,
                                    child: const CircularProgressIndicator(
                                      color: Colors.blue,
                                      strokeWidth: 3,
                                    ),
                                  ),
                          ),
                        )
                      ],
                    )
                  : Column(
                      children: <Widget>[
                        // Your keyboard space here

                        Container(
                          width: double.infinity,
                          height: height * 0.06,
                          //color: Colors.black,
                          decoration: const BoxDecoration(),
                          margin: EdgeInsets.only(top: height * 0.025),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _SearchFocusNode,
                            onChanged: (value) {
                              if (value != '') {
                                performSearch(value.toUpperCase());
                              }
                            },
                            onTapOutside: (event) {},
                            decoration: InputDecoration(
                              hintText: 'Search',
                              hintStyle: const TextStyle(
                                  color: Color.fromRGBO(146, 146, 168, 1),
                                  fontSize: 13,
                                  fontFamily: 'M-semiBold'),
                              prefixIcon: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  size: 25,
                                ),
                                onPressed: () {
                                  setState(() {
                                    search = false;
                                    _searchController.clear();
                                    _fetchWatchlist();
                                  });
                                },
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: _searchController.clear,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),

                        loading == false
                            ? Expanded(
                                child: Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(top: 0),
                                  child: ListView.builder(
                                      itemCount: listedFiltered.length,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        String symbol = listedFiltered[index]
                                                ['tradingsymbol']!
                                            .toString();
                                        String company = listedFiltered[index]
                                                ['name']!
                                            .toString();
                                        String instrument_token =
                                            listedFiltered[index]
                                                    ['instrument_token']!
                                                .toString();
                                        String exchange = listedFiltered[index]
                                                ['exchange']!
                                            .toString();
                                        return Column(
                                          children: [
                                            InkWell(
                                                child: _buildStockTileSearch(
                                              '$symbol',
                                              '$company',
                                              '$instrument_token',
                                              '${exchange}',
                                            )),
                                            const Divider(
                                              color: Color.fromARGB(
                                                  132, 193, 194, 193),
                                              thickness: 0.8,
                                              height: 0,
                                            ),
                                          ],
                                        );
                                      }),
                                ),
                              )
                            : Expanded(
                                child: Container(
                                  alignment: Alignment.center,
                                  child: const CircularProgressIndicator(
                                    color: Colors.blue,
                                    strokeWidth: 3,
                                  ),
                                ),
                              ),
                      ],
                    ),
                    ),
                    ),
    );
  }

  Widget _buildStockTileSearch(
      String title, String subtitle, String instrument_token, String exchange) {
    return ListTile(
      leading: Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
          ),
          padding: const EdgeInsets.all(4),
          child: Text('${exchange}',
              style: TextStyle(
                  // fontWeight: FontWeight.w500,
                  fontFamily: 'M-bold',
                  fontSize: 9,
                  color: Color.fromARGB(161, 0, 0, 0)))),
      title: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontFamily: 'M-regular',
              fontSize: 12,
              color: Colors.black)),
      subtitle: Text(subtitle,
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontFamily: 'M-regular',
              fontSize: 9,
              color: Color.fromRGBO(134, 134, 135, 1))),
      trailing: IconButton(
          icon: !stocksToFetch.contains('${instrument_token}')
              ? const Icon(FontAwesomeIcons.squarePlus, color: Colors.blue)
              : const Icon(FontAwesomeIcons.checkSquare, color: Colors.green),
          onPressed: () async {
            if (stocksToFetch.contains('${instrument_token}')) {
              _updateWatchlistUser(title, 'delete', instrument_token);

              _fetchWatchlist();
              // stocksToFetch.remove('${instrument_token}');
            } else {
              if (live_watchlist_real_time.length < 15) {
                bool limit = await _checkLimit();
                if (limit == true) {
                  _updateWatchlistGlobal(title, 'write', instrument_token);
                  _updateWatchlistUser(title, 'write', instrument_token);

                  _fetchWatchlist();
                }
              }
            }

            setState(() {});
          }),
    );
  }

  bool openWatchlist = false;
  Future<bool> _checkLimit() async {
    // Initialize the database reference
    final DatabaseReference dbRef = FirebaseDatabase.instance.ref();

    // Path to 'live_watchlist'
    final DatabaseReference liveWatchlistRef = dbRef.child('live_watchlist');

    // Fetch the data at 'live_watchlist'
    DataSnapshot snapshot = await liveWatchlistRef.get();

    if (snapshot.exists) {
      // Assuming 'live_watchlist' contains a map
      Map<dynamic, dynamic> liveWatchlist =
          snapshot.value as Map<dynamic, dynamic>;
      int numberOfFields =
          liveWatchlist.keys.length; // Calculate number of fields

      print("Number of fields in 'live_watchlist': $numberOfFields");
      if (numberOfFields < 2900) {
        return true;
      } else {
        return false;
      }
    } else {
      print("'live_watchlist' does not exist or is empty.");
      return true;
    }
  }

  String _tapStock = '';
  String buySellStockSymbol = '';
  String buySellStockPrice = '';

  Widget _buildStockItemWatchlist(
      String instrument_token,
      String name,
      String index,
      String price,
      String change,
      Color changeColor,
      int index1,
      double width,
      double height) {
    return (_tapStock != name)
        ? Dismissible(
            key: Key(name),
            onDismissed: (direction) {
              _updateWatchlistUser(name, 'delete', instrument_token);

              _fetchWatchlist();
              setState(() {});
            },
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20.0),
              child: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
            child: InkWell(
              child: ListTile(
                style: ListTileStyle.list,
                title: Text(name,
                    style: const TextStyle(
                        fontFamily: 'M-regular',
                        fontSize: 13,
                        color: Colors.black)),
                subtitle: Text(index,
                    style: const TextStyle(
                        fontFamily: 'M-semiBold',
                        fontSize: 10,
                        color: Color.fromRGBO(146, 146, 168, 1))),
                trailing: RichText(
                  textAlign: TextAlign.end,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: price != '0'
                            ? '${double.parse(price).toStringAsFixed(2)}\n'
                            : '0.00\n',
                        style: TextStyle(
                          color: double.parse(change) > 0
                              ? Colors.green
                              : Colors.red,
                          fontFamily: 'M-semiBold',
                          fontSize: 14,
                        ),
                      ),
                      const TextSpan(
                        text: ' ',
                        style: TextStyle(
                          fontSize: 19,
                        ),
                      ),
                      TextSpan(
                        text: change != '0'
                            ? (double.parse(change) > 0
                                ? '+${change}'
                                : '${change}')
                            : '0.00',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'M-regular',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              onTap: () {
                if (marketLive == true && double.parse(price) != 0) {
                  setState(() {
                    if (_tapStock != '') {
                      _tapStock = '';
                      _quantityController.text = '';
                    } else {
                      _tapStock = name;
                      _quantityController.text = '1';
                    }
                  });
                }
              },
            ),
          )
        : InkWell(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(
                    left: width * 0.03,
                    right: width * 0.03,
                    top: height * 0.02,
                    bottom: height * 0.02),
                child: Container(
                  height: height * 0.37,
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
                                  style: const TextStyle(
                                    fontFamily: 'M-regular',
                                    fontSize: 17,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: double.infinity,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${double.parse(price).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontFamily: 'M-bold',
                                    //fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                width: double.infinity,
                                height: height * 0.032,
                                child: Row(
                                  children: <Widget>[
                                    _buildCustomButton(context, 'Intraday',
                                        intradayLongterm == 'intraday'),
                                    Text(
                                      'Intraday',
                                      style: TextStyle(
                                        color: intradayLongterm == 'intraday'
                                            ? Colors.blue
                                            : Colors.grey,
                                        fontSize: 11,
                                        fontFamily: 'M-bold',
                                      ),
                                    ),
                                    _buildCustomButton(context, 'Longterm',
                                        intradayLongterm == 'longterm'),
                                    Text(
                                      'Longterm',
                                      style: TextStyle(
                                        color: intradayLongterm == 'longterm'
                                            ? Colors.blue
                                            : Colors.grey,
                                        fontSize: 11,
                                        fontFamily: 'M-bold',
                                      ),
                                    ),
                                    Expanded(child: Container())
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                width: double.infinity,
                                //height: height * 0.06,
                                padding: EdgeInsets.only(right: width * 0.04),
                                child: TextFormField(
                                  keyboardType: TextInputType.number,
                                  controller: _quantityController,
                                  onChanged: (value) {
                                    // print(value);
                                  },
                                  decoration: const InputDecoration(
                                    labelText: 'Quantity',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                ),
                                child: Container(
                                  width: double.infinity,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    intradayLongterm == 'longterm'
                                        ? 'Margin: ${price}/qty'
                                        : 'Margin: ${(double.parse(price) / 5).toStringAsFixed(2)}/qty',
                                    style: const TextStyle(
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

                                        //////////////////////
                                        if ((position['price'] == 0 &&
                                                position['quantity'] == 0) ||
                                            position.isEmpty) {
                                          ////NO POSITION////
//////////1111
                                          bool fundSuccess = await _manageWallet(
                                              'debit',
                                              intradayLongterm == 'longterm'
                                                  ? '${price}'
                                                  : '${(double.parse(price) / 5)}',
                                              double.parse(
                                                      _quantityController.text)
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
                                                double.parse(_quantityController
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
                                                double.parse(_quantityController
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
                                                    _quantityController.text)) {
                                              error =
                                                  'User need to exit their current position of (${position['quantity']}) to change their position';
                                              setState(() {});
                                            } else {
                                              bool fundSuccess = await _manageWallet(
                                                  'credit',
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
                                              double.parse(
                                                      _quantityController.text)
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
                                                double.parse(_quantityController
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
                                                double.parse(_quantityController
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
                                                    _quantityController.text)) {
                                              error =
                                                  'User need to exit their current position of (${position['quantity']}) to change their position';
                                              setState(() {});
                                            } else {
                                              bool fundSuccess = await _manageWallet(
                                                  'credit',
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
            onTap: () {
              setState(() {
                // _tapStock = '';
              });
            },
          );
  }

  String intradayLongterm = 'intraday';

  Widget _buildCustomButton(
      BuildContext context, String text, bool isSelected) {
    return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 4.0,
        ),
        child: InkWell(
          onTap: () {
            setState(() {
              intradayLongterm = text.toLowerCase();
            });

            // Handle button tap
          },
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
              //borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey,
                width: 3,
              ),
            ),
            alignment: Alignment.center,
            child: Container(
              width: 20, // Set the width of the inner circle
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.blue : Colors.transparent,
              ),
            ),
          ),
        ));
  }
}
/*
  Future<void> uploadCsvDataToFirebase() async {
    // Read the CSV file from assets
    print('start');
    final String csvData =
        await rootBundle.loadString('assets/instruments.csv');

    // Parse CSV data
    List<List<dynamic>> rowsAsListOfValues =
        const CsvToListConverter().convert(csvData);

    // final firestore = FirebaseFirestore.instance;
    /*List<String> exchange = [];
    List<String> instrument_type = [];
    List<String> segment = [];

    int BCD = 0;
    int BFO = 0;
    int BSE = 0;
    int CDS = 0;
    int MCX = 0;
    int NSE = 0;
    int NSEIX = 0;
    int NFO = 0;*/

    int count = 0;

    //instrument_token,
    //exchange_token,
    //tradingsymbol,
    //name,
    //last_price,
    //expiry,
    //strike,
    //tick_size,
    //lot_size,
    //instrument_type,
    //segment,
    //exchange

    List<dynamic> instrument_token = [];

    Map<String, dynamic> dataMap = {};

    print('start');
    for (final row in rowsAsListOfValues) {
      // Create a map from the CSV data, assuming the first 3 columns are ID, Name, and Description
      // final Map<String, dynamic>

      dataMap = {
        'instrument_token': row[0],
        'exchange_token': row[1],
        'tradingsymbol': row[2],
        'name': row[3],
        'last_price': row[4],
        'expiry': row[5],
        'strike': row[6],
        'tick_size': row[7],
        'lot_size': row[8],
        'instrument_type': row[9],
        'segment': row[10],
        'exchange': row[11],

        // Add further fields here
      };
      await firestore
          .collection('stock_data_master')
          .doc() // Using the company symbol as the document ID
          .set(dataMap);

      count++;
      print(count);
      //print(row[9]);
      //instrument_type.removeAt(0);
      /* if (instrument_type.contains(dataMap['instrument_type'])) {
      } else {
        instrument_type.add(dataMap['instrument_type']);
      }
      // segment.removeAt(0);
      if (segment.contains(dataMap['segment'])) {
      } else {
        segment.add(dataMap['segment']);
      }*/

      /*  if(dataMap['exchange'] == 'BCD'){
        BCD++;
      }
      if(dataMap['exchange'] == 'BFO'){
        BFO++;
      } 
      if(dataMap['exchange'] == 'BSE'){
        BSE++;
      }
      if(dataMap['exchange'] == 'CDS'){
        CDS++;
      }
      if(dataMap['exchange'] == 'MCX'){
        MCX++;
      }
      if(dataMap['exchange'] == 'NSE'){
        NSE++;
      }
      if(dataMap['exchange'] == 'NSEIX'){
        NSEIX++;
      }
      if(dataMap['exchange'] == 'NFO'){
        NFO++;
      }*/
    }

    //instrument_type.removeAt(0);
/*    print('instrument type length : ${instrument_type.length}');
    print('instrument type list : ${instrument_type}');

    // segment.removeAt(0);
    print('segment length : ${segment.length}');
    print('segment list : ${segment}');
*/
    /*print('BCD : ${BCD}');
    print('BFO : ${BFO}');
    print('BSE : ${BSE}');
    print('CDS : ${CDS}');
    print('MCX : ${MCX}');
    print('NSE : ${NSE}');
    print('NSEIX : ${NSEIX}');
    print('NFO : ${NFO}');*/

//EXCHANGE LENGTH : 8
//EXCHANGE : [BCD, BFO, BSE, CDS, MCX, NSE, NSEIX, NFO]

    /* final DatabaseReference databaseReference =
          FirebaseDatabase.instance.ref();
      DatabaseReference nseCompanyListedRef =
          databaseReference.child('nse_company_listed/${row[1]}');*/
    // Example path where you want to upload data
    // String path = 'https://stock-eb628-default-rtdb.firebaseio.com/nsecompany_listed';

    /* try {
        // Upload the data to the path
        await nseCompanyListedRef.set(dataMap);
      } catch (e) {
        print(e);
      }*/

    // Upload the data to the path
    //

    //await databaseReference.child(path).set(dataMap);

    //listedAll.add(dataMap);
    // listedFiltered.add(dataMap);

    // Push the data to Firebase Database

    print('end');
  }
*/