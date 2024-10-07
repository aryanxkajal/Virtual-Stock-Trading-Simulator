import 'dart:async';

import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';

import 'package:firebase_database/firebase_database.dart';

import 'package:flutter/services.dart';
import 'package:flutter_application_1/model_calculation.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '/global.dart' as globals;

class OpenPositionAdmin extends StatefulWidget {
  const OpenPositionAdmin({super.key});

  @override
  State<OpenPositionAdmin> createState() => _OpenPositionAdminState();
}

class _OpenPositionAdminState extends State<OpenPositionAdmin>
    with TickerProviderStateMixin {
  void _updateSearchResults(String searchText) {
    setState(() {
      listedFiltered = filterProduct(searchText);
    });
  }

  List<Map<String, dynamic>> listedFiltered = [];

  List<Map<String, dynamic>> filterProduct(String searchText) {
    return listedAll.where((x) {
      final productNameMatches =
          x['symbol']!.toLowerCase().contains(searchText.toLowerCase());

      final barcodeMatches = x['company'].toLowerCase().contains(searchText);
      return productNameMatches || barcodeMatches;
    }).toList();
  }

  Future<void> uploadCsvDataToFirebase() async {
    // Read the CSV file from assets
    final String csvData =
        await rootBundle.loadString('assets/MCAP31122023 (3).csv');

    // Parse CSV data
    List<List<dynamic>> rowsAsListOfValues =
        const CsvToListConverter().convert(csvData);

    final firestore = FirebaseFirestore.instance;

    print('start');
    for (final row in rowsAsListOfValues) {
      // Create a map from the CSV data, assuming the first 3 columns are ID, Name, and Description
      final Map<String, dynamic> dataMap = {
        'id': row[0],
        'symbol': row[1],
        'company': row[2],
        //'e1': 'x',
        //'e2': 'x',

        // Add further fields here
      };
      print(dataMap);

      final DatabaseReference databaseReference =
          FirebaseDatabase.instance.ref();
      DatabaseReference nseCompanyListedRef =
          databaseReference.child('nse_company_listed/${row[1]}');
      // Example path where you want to upload data
      // String path = 'https://stock-eb628-default-rtdb.firebaseio.com/nsecompany_listed';

      try {
        // Upload the data to the path
        await nseCompanyListedRef.set(dataMap);
      } catch (e) {
        print(e);
      }

      // Upload the data to the path
      //

      //await databaseReference.child(path).set(dataMap);

      //listedAll.add(dataMap);
      // listedFiltered.add(dataMap);

      // Push the data to Firebase Database
      /* await firestore
          .collection('companies')
          .doc(row[1]) // Using the company symbol as the document ID
          .set(dataMap);*/
    }
    print('end');
  }

// await ref.child('your_firebase_child_path').push().set(dataMap);

  // This map holds the latest data
  Map<String, Map<String, dynamic>> live_watchlist_real_time = {};

  List<StreamSubscription<DatabaseEvent>> _subscriptions = [];

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

  bool loading1 = true;

  List<Map<String, dynamic>> live = [];

  var stockData1 = <String, dynamic>{};
  final firestore = FirebaseFirestore.instance;

  List<String> stocksToFetch = [];
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    //uploadCsvDataToFirebase();
    // fetchListedCompanies();
    totalProfit = 0;
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);

    // _fetchWatchlist();
    fetchOrders();
    //listenToStocks(stocksToFetch);
  }

  List<Order> ordersList = [];
  List<dynamic> name = [];

  Map<String, Map<String, dynamic>> orderAll = {};

  // Function to get orders from Firestore
  void fetchOrders() async {
    // Determine the correct document based on 'intradayLongterm'

    try {
      // Retrieve the current data

      final querySnapshot = await firestore.collection('users_details').get();
      List<Future<void>> operations = []; // List to hold all async operations

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        String docId = _navBar == 1 ? 'position' : 'holdings';
        DocumentReference docRef = firestore
            .collection('users')
            .doc(data['id'].toString())
            .collection('order_holding_position')
            .doc(docId);

        DocumentSnapshot snapshot = await docRef.get();
        if (snapshot.exists) {
          Map<String, dynamic> currentData =
              snapshot.data() as Map<String, dynamic>;
          // print(currentData);

          for (var i in currentData.entries) {
            if (double.parse(i.value['quantity']) != 0) {
              // print(i);
              orderAll['${data['id']}-${i.key}'] = {
                'name': i.key,
                'id': data['id'],
                'price': i.value['price'],
                'quantity': i.value['quantity'],
                'intradayLongterm': i.value['intradayLongterm'],
                'instrument_token': i.value['instrument_token'],
                'instrument_type': i.value['instrument_type'],
                'segment': i.value['segment'],
                'profit': i.value['profit'],
              };

              if (stocksToFetch.contains(i.value['instrument_token']) ==
                  false) {
                stocksToFetch.add(i.value['instrument_token']);
              }
            }
          }
          listenToStocks(stocksToFetch);

          // Increment the quantity
        } else {}
      }
    } catch (e) {
      print('1Error updating watchlist: $e');
      if (e is FirebaseException) {
        print('Error code: ${e.code}');
        print('Error message: ${e.message}');
      }
    }

    setState(() {});
  }

/*
  void _fetchWatchlist() async {
    userDataAll = {};
    userDataAllFiltered = {};

    try {
      final querySnapshot = await firestore.collection('users_details').get();
      List<Future<void>> operations = []; // List to hold all async operations

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        // Avoid unnecessary async operation if condition is met
        if (data['id'] != 'admin@stockup.com') {
          // Store the async operation in the operations list
          var operation = firestore
              .collection('users')
              .doc(data['id'])
              .collection('details')
              .doc('wallet')
              .get()
              .then((value) {
            double funds = double.tryParse(value.data()!['available_fund'])!;
            // Update userDataAll within the then() to ensure funds is available
            userDataAll[data['id']] = {
              'id': data['id'],
              'password': data['password'],
              'funds': funds.toString(),
            };
          });
          operations.add(operation);
        }
      }

      // Await all operations to complete
      await Future.wait(operations);

      // This print statement will now correctly display userDataAll after all updates
      // print('ss${userDataAll}');
    } catch (e) {
      print(e);
    }
    userDataAllFiltered = userDataAll;
    setState(() {});
  }
*/
  List<Map<String, dynamic>> listedAll = [];

  fetchListedCompanies() async {
    final DatabaseReference databaseReference = FirebaseDatabase.instance.ref();
    DatabaseReference nseCompanyListedRef =
        databaseReference.child('nse_company_listed');

    final dataSnapshot = await nseCompanyListedRef.once();
    if (dataSnapshot.snapshot.exists) {
      Map<String, dynamic> data =
          Map<String, dynamic>.from(dataSnapshot.snapshot.value as Map);
      data.forEach((key, value) {
        if (value is Map) {
          Map<String, dynamic> companyData = Map<String, dynamic>.from(value);
          listedAll.add(
              companyData); // Ensure listedAll is declared to accept this type
          listedFiltered.add(companyData); // Same as above
        } else {
          print("Unexpected data type: $value");
        }
      });
    } else {
      print('No data available.');
    }
  }

  var _bottomNavIndex = 0; //default index of a first screen

  final iconList = <IconData>[
    FontAwesomeIcons.bookmark,
    FontAwesomeIcons.book,
    FontAwesomeIcons.briefcase,
    FontAwesomeIcons.user,
  ];

  bool market = true;

  bool search = false;

  List<String> stocks = [
    'ARABIAN-SM ARABIAN PETROLEUM',
    'ARAVALIS ARAVALI SECURITIES & FINANCE L',
    // Add more stocks here
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _tabController?.dispose();
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  double totalProfit = 0;

  final TextEditingController _searchController = TextEditingController();

  // This function simulates adding a stock to a watchlist.
  void _addStock(String stockName) {
    // Placeholder for add stock logic
    print('Adding $stockName to watchlist');
  }

  void _updateWatchlistUser(String stockName, String writeDelete) async {
    if (writeDelete == 'write') {
      try {
        await firestore.collection('users').doc('${globals.userId}').set(
          {
            'uid': globals.userId,
            'name': 'Aryan',
            'upi': '8168889152@paytm',
            'watchlist1': FieldValue.arrayUnion(stocksToFetch)
          },
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
            'uid': globals.userId,
            'name': 'Aryan',
            'upi': '8168889152@paytm',
            'watchlist1': FieldValue.arrayRemove([stockName])
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

  void _updateWatchlistGlobal(String stockName, String writeDelete) async {
    if (writeDelete == 'write') {
      final DatabaseReference databaseReference =
          FirebaseDatabase.instance.ref();
      DatabaseReference nseCompanyListedRef =
          databaseReference.child('live_watchlist/${stockName}');

      try {
        await nseCompanyListedRef.set(stockName);
      } catch (e) {
        print(e);
      }
    } else if (writeDelete == 'delete') {
      final DatabaseReference databaseReference =
          FirebaseDatabase.instance.ref();
      DatabaseReference nseCompanyListedRef =
          databaseReference.child('live_watchlist/${stockName}');

      try {
        await nseCompanyListedRef.remove();
      } catch (e) {
        print(e);
      }
    }
    setState(() {});
  }

  bool buySell = false;

  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  void _updateBuySellData(String price, String quantity, String buySell) async {
    // String formattedDateTime = DateFormat('dd MM yyyy HH mm ss').format(now);
    // print(formattedDateTime);

    try {
      await firestore
          .collection('users')
          .doc('${globals.userId}')
          .collection('buySell')
          .doc('${DateFormat('dd MM yyyy').format(DateTime.now())}')
          .set(
        {
          'name': '$buySellStockSymbol',
          'buySell': '${buySell}',
          'quantity': '$quantity',
          'startPrice': '$buySellStockPrice',
          'intradayLongterm': '${intradayLongterm1}',
          'endPrice': '0',
          'status': 'pending',
          'timestamp': DateTime.now(),
          'profit': '0',
        },
      );
    } catch (e) {
      print('Error updating watchlist: $e');
      if (e is FirebaseException) {
        print('Error code: ${e.code}');
        print('Error message: ${e.message}');
      }

      print('end');
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

/*
  void _handle(
      String symbol,
      String intradayLongterm1,
      String price,
      String quantity,
      String buySell,
      String instrument_token,
      String exchange,
      String instrument_type,
      String segment) async {
    String docId = intradayLongterm1 == 'intraday' ? 'position' : 'holdings';
    DocumentReference docRef = firestore
        .collection('users')
        .doc(globals.userId)
        .collection('order_holding_position')
        .doc(docId);
    try {
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

        // fund logics

        if (currentQuantity > 0) {
          if (buySell == 'buy') {
            if (funds < double.tryParse(price)! * double.tryParse(quantity)!) {
              setState(() {
                error = 'Insufficient funds';
              });
            } else {
              _updateWallet(
                  'debit',
                  (double.tryParse(price)! * double.tryParse(quantity)!)
                      .toString(),
                  'admin',
                  symbol,
                  price,
                  quantity);
              _addOrder(symbol, intradayLongterm1, price, quantity, buySell,
                  instrument_token, exchange, instrument_type, segment);
              _updatePortfolio(
                  symbol,
                  intradayLongterm1,
                  price,
                  quantity,
                  buySell,
                  instrument_token,
                  exchange,
                  instrument_type,
                  segment,
                  (currentQuantity + double.parse(quantity)).toString(),
                  ((currentPrice / currentQuantity) +
                          (double.parse(price) / double.parse(quantity)) *
                              (currentQuantity + double.parse(quantity)))
                      .toString());
              setState(() {
                error = 'Order placed!';
              });
            }
          } else if (buySell == 'sell') {
            if (currentQuantity < double.tryParse(quantity)!) {
              setState(() {
                error =
                    'Users need to exist their current position to change their position';
              });
            } else {
              _updateWallet(
                  'credit',
                  (double.tryParse(price)! * double.tryParse(quantity)!)
                      .toString(),
                  'admin',
                  symbol,
                  price,
                  quantity);
              _addOrder(symbol, intradayLongterm1, price, quantity, buySell,
                  instrument_token, exchange, instrument_type, segment);
              _updatePortfolio(
                  symbol,
                  intradayLongterm1,
                  price,
                  quantity,
                  buySell,
                  instrument_token,
                  exchange,
                  instrument_type,
                  segment,
                  (currentQuantity - double.parse(quantity)).toString(),
                  ((currentPrice / currentQuantity.abs()) +
                          (double.parse(price) / double.parse(quantity)) *
                              ((currentQuantity - double.parse(quantity))
                                  .abs()))
                      .toString());
              setState(() {
                error = 'Order placed!';
              });
            }
          }
        } else if (currentQuantity < 0) {
          if (buySell == 'sell') {
            if (funds <
                (double.tryParse(price)! * double.tryParse(quantity)!)) {
              setState(() {
                error = 'Insufficient funds';
              });
            } else {
              _updateWallet(
                  'debit',
                  (double.tryParse(price)! * double.tryParse(quantity)!)
                      .toString(),
                  'admin',
                  symbol,
                  price,
                  quantity);
              _addOrder(symbol, intradayLongterm1, price, quantity, buySell,
                  instrument_token, exchange, instrument_type, segment);
              setState(() {
                error = 'Order placed!';
              });
            }
          } else if (buySell == 'buy') {
            if (currentQuantity.abs() < double.tryParse(quantity)!) {
              setState(() {
                error =
                    'Users need to exist their current position to change their position';
              });
            } else {
              _updateWallet(
                  'credit',
                  (double.tryParse(price)! * double.tryParse(quantity)!)
                      .toString(),
                  'admin',
                  symbol,
                  price,
                  quantity);
              _addOrder(symbol, intradayLongterm1, price, quantity, buySell,
                  instrument_token, exchange, instrument_type, segment);
              setState(() {
                error = 'Order placed!';
              });
            }
          }
        }

        // Increment the quantity

        // Update the data
      } else {
        if (buySell == 'buy') {
          _updateWallet(
              'debit',
              (double.tryParse(price)! * double.tryParse(quantity)!).toString(),
              'admin',
              symbol,
              price,
              quantity);
        } else if (buySell == 'sell') {
          _updateWallet(
              'debit',
              (double.tryParse(price)! * double.tryParse(quantity)!).toString(),
              'admin',
              symbol,
              price,
              quantity);
        }
      }
    } catch (e) {}
  }
*/

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
    DocumentSnapshot snapshot = await docRef.get();

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
            newPrice = ((currentPrice * currentQuantity) +
                    (double.parse(price) * double.parse(quantity))) /
                (currentQuantity - double.parse(quantity));
          } else if ((currentQuantity > 0) &&
              (currentQuantity.abs() != double.parse(quantity))) {
            print('s3');
            newQuantity = currentQuantity - double.parse(quantity);
            newPrice = ((currentPrice * currentQuantity) +
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

  _updateWallet(
    String debitCredit,
    String amount,
    String userAdmin,
    String symbol,
    String price,
    String quantity,
  ) async {
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
          'symbol': '$symbol',
          'price': '$price',
          'quantity': '$quantity',
        },
      });

      DocumentReference docRef = firestore
          .collection('users')
          .doc(globals.userId)
          .collection('details')
          .doc('wallet');
      DocumentSnapshot snapshot = await docRef.get();

      if (snapshot.exists) {
        Map<String, dynamic> currentData =
            snapshot.data() as Map<String, dynamic>;

        //print(currentData['available_fund']);
        double currentAmount = double.tryParse(currentData['available_fund'])!;
        double newAmount = debitCredit == 'debit'
            ? currentAmount - double.tryParse(amount)!
            : currentAmount + double.tryParse(amount)!;
        await docRef.update({
          'available_fund': newAmount.toString(),
        });
      }
    } catch (e) {
      print('Error updating watchlist: $e');
      if (e is FirebaseException) {
        print('Error code: ${e.code}');
        print('Error message: ${e.message}');
      }

      print('end');
    }
  }

  //////////////////////////////////
  ///
  ///

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

  int _navBar = 1;

  //////////calculation

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
              backgroundColor: search != true
                  ? Color.fromARGB(242, 254, 255, 254)
                  : Colors.white,
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
                              text: 'Open Positions',
                              style: TextStyle(
                                  fontSize: 20,
                                  color: Color.fromRGBO(63, 63, 63, 1),
                                  fontFamily: 'M-regular',
                                  fontWeight: FontWeight.w900),
                            ),
                            TextSpan(
                                text: market == true ? '' : ' Closed',
                                style: TextStyle(
                                    color: market == true
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
                          orderAll = {};
                          stockData1 = {};
                          totalProfit = 0;

                          _navBar = value;
                          orderAll = {};
                          fetchOrders();
                          print(value);
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
                                itemBuilder: (BuildContext context, int index) {
                                  String key1 = orderAll.keys.elementAt(index);

                                  String price1 = orderAll[key1]!['price'];
                                  String quantity = orderAll[key1]!['quantity'];
                                  String symbol = orderAll[key1]!['name'];
                                  String user = orderAll[key1]!['id'];

                                  String intradayLongterm =
                                      orderAll[key1]!['intradayLongterm'];

                                  String instrument_token =
                                      orderAll[key1]!['instrument_token'];

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
                                        child: _buildStockItemWatchlist(
                                            symbol,
                                            user,
                                            instrument_token,
                                            key1,
                                            key1,
                                            price1,
                                            quantity,
                                            intradayLongterm,
                                            latest_price.toString(),
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
                                }),
                          )
                        : Container(
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
                                itemBuilder: (BuildContext context, int index) {
                                  String key1 = orderAll.keys.elementAt(index);

                                  String instrument_token =
                                      orderAll[key1]!['instrument_token'];
                                  //print(instrument_token);

                                  String price1 = orderAll[key1]!['price'];
                                  String user = orderAll[key1]!['id'];
                                  String symbol = orderAll[key1]!['name'];
                                  String quantity = orderAll[key1]!['quantity'];

                                  String intradayLongterm =
                                      orderAll[key1]!['intradayLongterm'];

                                  double latest_price =
                                      stockData1[instrument_token]
                                              ?['last_price'] ??
                                          0.0;

                                  //double value = 11.0;
                                  //  print(value);
                                  //   double latest_price = 3.22;

                                  // endPrice = value.toString();
                                  return Column(
                                    children: [
                                      InkWell(
                                        child: _buildStockItemWatchlist(
                                            symbol,
                                            user,
                                            instrument_token,
                                            key1,
                                            key1,
                                            price1,
                                            quantity,
                                            intradayLongterm,
                                            latest_price.toString(),
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
                                }),
                          ),
                  ),

                  /*  Container(
                // alignment: Alignment.centerLeft,
                child: TabBar(
                  isScrollable: true,
                  indicatorColor: Colors.blue,
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.black,
                  tabs: [
                    Tab(text: 'Watchlist 1'),
                    Tab(text: 'Watchlist 2'),
                    Tab(text: 'Watchlist 3'),
                    Tab(text: 'Watchlist 4'),
                    Tab(text: 'Watchlist 5'),
                    Tab(text: 'Watchlist 6'),
                    Tab(text: 'Watchlist 7'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // Your content for each tab goes here
                     Center(child: Text('Content for Watchlist 2')),
                    Center(child: Text('Content for Watchlist 3')),
                    Center(child: Text('Content for Watchlist 4')),
                    Center(child: Text('Content for Watchlist 5')),
                    Center(child: Text('Content for Watchlist 6')),
                    Center(child: Text('Content for Watchlist 7')),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      padding: EdgeInsets.only(
                        left: width * 0.01,
                        right: width * 0.01,
                        top: height * 0.02,
                      ),
                      margin: EdgeInsets.only(top: height * 0.05),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: ListView.builder(
                          itemCount: stockData1.length,
                          itemBuilder: (BuildContext context, int index) {
                            String key = stockData1.keys.elementAt(index);
                            double value = stockData1[key]!;
                            return Column(
                              children: [
                                InkWell(
                                  child: _buildStockItem(
                                      '${key}',
                                      'NSE',
                                      '${value}',
                                      '+1.10 (+0.07%)',
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
                          }),
                    ),
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
                        decoration: InputDecoration(
                          hintText: 'Search & add to watchlist',
                          hintStyle: TextStyle(
                              color: Color.fromRGBO(146, 146, 168, 1),
                              fontSize: 13,
                              fontFamily: 'M-semiBold'),
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
                  ],
                ),
              )*/
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
  }

  Map<String, double> profitMap = {};
  Map<String, double> profitMap1 = {};

  Widget _buildStockItemWatchlist(
      String symbol,
      String user,
      String instrument_token,
      String date,
      String name,
      String price,
      String quantity,
      String intradayLongterm,
      String latest_price,
      double width,
      double height) {
    Trade trade = Trade(
      instrument: Instrument(
          type: '${orderAll[name]!['instrument_type']}',
          segment: '${orderAll[name]!['segment']}'),
      entryPrice: double.parse(price),
      exitPrice: _navBar == 0
          ? double.parse(latest_price)
          : double.parse(latest_price) / 5,
      quantity: int.parse(quantity),
    );
    String error = '';

    double profitLoss = TradeCalculator.calculateProfitLoss(trade);

    return Container(
        padding: EdgeInsets.only(left: 17, right: 17, top: 5, bottom: 15),
        child: Column(
          children: [
            Row(
              children: [
                Text('$user',
                    style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'M-regular',
                        fontWeight: FontWeight.w600)),
                Expanded(child: Container()),
                TextButton(
                    onPressed: () {},
                    child: Text(
                      ' ',
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontFamily: 'M-regular',
                          fontWeight: FontWeight.w600),
                    ))
              ],
            ),
            Divider(
              color: Color.fromARGB(20, 0, 0, 0),
              thickness: 0.8,
              height: 0,
            ),
            SizedBox(
              height: 6,
            ),
            Row(
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
                    Text('${symbol}',
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
                                ? '${double.parse(latest_price).toStringAsFixed(2)}'
                                : '${(double.parse(latest_price) / 5).toStringAsFixed(2)}',
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
                    Text('Avg. ${double.parse(price).toStringAsFixed(2)}',
                        style: TextStyle(
                            color: Colors.grey,
                            fontFamily: 'M-regular',
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ],
        ));
  }

  String intradayLongterm1 = '';

  Widget _buildCustomButton(
      BuildContext context, String text, bool isSelected) {
    return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 4.0,
        ),
        child: InkWell(
          onTap: () {
            setState(() {
              intradayLongterm1 = text.toLowerCase();
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
