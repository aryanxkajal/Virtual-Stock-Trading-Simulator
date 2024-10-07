import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_application_1/model_calculation.dart';
import 'package:flutter_application_1/user/main_user.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '/global.dart' as globals;

class UserAdmin extends StatefulWidget {
  const UserAdmin({super.key});

  @override
  State<UserAdmin> createState() => _UserAdminState();
}

class _UserAdminState extends State<UserAdmin> {
  @override
  void initState() {
    super.initState();

    _fetchWatchlist();
    globals.adminId = '';
    globals.adminPass = '';

    // _handleSignUp('hi', '11');
  }

  _signIn() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    globals.userId = globals.adminId;
    await _auth.signInWithEmailAndPassword(
      email: globals.adminId,
      password: globals.adminPass,
    );
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
  final TextEditingController _priceController = TextEditingController();
  bool market = true;

  bool search = false;
  String error = '';
  List<StreamSubscription<DatabaseEvent>> _subscriptions = [];
  final TextEditingController _searchController = TextEditingController();
  FocusNode _SearchFocusNode = FocusNode();
  double funds = 0;

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

  /* void _fetchWatchlist() async {
   
    try {
      await firestore
          .collection('users_details')
          .snapshots()
          .forEach((element) async {
        final data = element.docs.map((doc) => doc.data()).toList();
        for (var i in data) {
          //print(i['id']);
          //if(i['id' != 'admin@stockup.com']) {

          await firestore
              .collection('users')
              .doc(i['id'])
              .collection('details')
              .doc('wallet')
              .get()
              .then((value) {
            funds = double.tryParse(value.data()!['available_fund'])!;
            //print(funds);
            
            print(funds);

            //print(funds);
          });
          userDataAll[i['id']] = {
              'id': i['id'],
              'funds': funds.toString(),
            };

          //print(i['id']);
        }
      });
      // print('ss${userDataAll}');

      /* get()
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
      });*/
    } catch (e) {
      print(e);
    }
    
    print('ss${userDataAll}');
  }
*/

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

  Map<String, Map<String, dynamic>> userDataAll = {};
  Map<String, Map<String, dynamic>> userDataAllFiltered = {};

  Map<String, Map<String, dynamic>> filterUserData(String searchText) {
    Map<String, Map<String, dynamic>> filteredData = {};

    // Convert searchText to lower case for case-insensitive comparison
    String searchLower = searchText.toLowerCase();

    userDataAll.forEach((key, value) {
      // Check if the key contains the search text.
      // Assuming you're searching in the key. If you need to search within values, you'll need to adjust this logic.
      if (key.toLowerCase().contains(searchLower)) {
        filteredData[key] = value;
      }
    });

    return filteredData;
  }

  void _updateSearchResults(String searchText) {
    setState(() {
      userDataAllFiltered = filterUserData(searchText);
    });
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
          .collection('stock_data')
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
          .collection('stock_data')
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

  _addFunds(
    String key,
    String amount,
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
          'debitCredit': 'credit',
          'amount': '${amount}',
          'userAdmin': 'admin',
          'symbol': ' ',
          'price': ' ',
          'quantity': ' ',
        },
      });

      DocumentReference docRef = firestore
          .collection('users')
          .doc(key)
          .collection('details')
          .doc('wallet');
      DocumentSnapshot snapshot = await docRef.get();

      if (snapshot.exists) {
        Map<String, dynamic> currentData =
            snapshot.data() as Map<String, dynamic>;

        //print(currentData['available_fund']);
        double currentAmount = double.tryParse(currentData['available_fund'])!;
        double newAmount = currentAmount + double.tryParse(amount)!;
        await docRef.update({
          'available_fund': newAmount.toString(),
        });
      }
      _fetchWatchlist();
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

  @override
  void dispose() {
    _searchController.dispose();
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  _removeUser(String key) {
    try {
      firestore.collection('users').doc(key).delete();
      firestore.collection('users_details').doc(key).delete();
    } catch (e) {
      print(e);
    }
  }

  Future<User?> signUpWithEmailPassword(String email, String password) async {
    try {
      final FirebaseAuth _auth = FirebaseAuth.instance;
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      //await _auth.signOut();
      final User? user = userCredential.user;
      return user;
    } on FirebaseAuthException catch (e) {
      // Handle errors, e.g., email already in use or weak password
      errorSignUp = e.toString();
      setState(() {});
      print(e.toString());
      return null;
    }
  }

  _handleSignUp(String id, String password) async {
    try {
      await firestore
          .collection('users')
          .doc('${id}')
          .collection('details')
          .doc('wallet')
          .set({'available_fund': '0'});

      await firestore
          .collection('users_details')
          .doc('${id}')
          .set({'id': '${id}', 'password': '${password}'});
    } catch (e) {
      print(e);
    }
  }

  String errorSignUp = '';

  bool addUser = false;
  TextEditingController _idController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

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
                body: Column(
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
                                    text: 'Users',
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
                      child: TextFormField(
                        // enabled: false,
                        onChanged: (value) {
                          _updateSearchResults(value);
                        },
                        decoration: InputDecoration(
                          hintText: 'Search Users',
                          hintStyle: const TextStyle(
                              color: Color.fromRGBO(146, 146, 168, 1),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'M-regular'),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color.fromRGBO(146, 146, 168, 1),
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _idController.clear();
                                _passwordController.clear();
                                addUser = true;
                              });
                            },
                            icon: const Icon(
                              Icons.add,
                              color: Color.fromRGBO(146, 146, 168, 1),
                            ),
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
                    if (addUser == true)
                      Container(
                        width: double.infinity,
                        //height: height * 0.2,
                        margin:
                            const EdgeInsets.only(left: 20, right: 20, top: 10),
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
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            ListTile(
                                title: const Text(
                                  'Add User',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: Color.fromARGB(140, 0, 0, 0),
                                    fontFamily: 'M-regular',
                                  ),
                                ),
                                trailing: IconButton(
                                    onPressed: () {
                                      _idController.clear();
                                      _passwordController.clear();
                                      setState(() {
                                        addUser = false;
                                      });
                                    },
                                    icon: const Icon(Icons.close))),
                            Container(
                              width: width * 0.6,
                              margin:
                                  const EdgeInsets.only(left: 40, right: 40),
                              child: TextFormField(
                                controller: _idController,
                                decoration: const InputDecoration(
                                  hintText:
                                      'Enter User Id, eg. xyx@stockup.com',
                                  hintStyle: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                    color: Color.fromARGB(74, 0, 0, 0),
                                    fontFamily: 'M-regular',
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: width * 0.6,
                              margin:
                                  const EdgeInsets.only(left: 40, right: 40),
                              child: TextFormField(
                                controller: _passwordController,
                                decoration: const InputDecoration(
                                  hintText: 'Enter Password',
                                  hintStyle: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                    color: Color.fromARGB(74, 0, 0, 0),
                                    fontFamily: 'M-regular',
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: height * 0.02),
                            Container(
                              child: Text(
                                '${errorSignUp}',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 10,
                                  fontFamily: 'M-regular',
                                ),
                              ),
                            ),
                            SizedBox(height: height * 0.02),
                            Container(
                                width: width * 0.6,
                                margin:
                                    const EdgeInsets.only(left: 40, right: 40),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final user = await signUpWithEmailPassword(
                                      _idController.text,
                                      _passwordController.text,
                                    );
                                    if (user != null) {
                                      setState(() {
                                        globals.adminId = 'admin@stockup.com';
                                        globals.adminPass = 'admin1';
                                        // errorSignUp = 'Sign up successful';
                                        _handleSignUp(_idController.text,
                                            _passwordController.text);
                                        //addUser = false;
                                        _idController.clear;
                                        _passwordController.clear;

                                        //_fetchWatchlist();
                                      });

                                      print("Sign up successful");
                                      // Navigate to your app's home screen or another appropriate screen
                                    } else {
                                      error = 'Sign up failed';
                                      setState(() {});
                                      print("Sign up failed");
                                      // Show an error message
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  child: const Text('Add User',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontFamily: 'M-regular',
                                      )),
                                )),
                            SizedBox(height: height * 0.04),
                          ],
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
                          child: ListView.builder(
                              itemCount: userDataAllFiltered.length,
                              itemBuilder: (BuildContext context, int index) {
                                // print(userDataAll);
                                String key =
                                    userDataAllFiltered.keys.elementAt(index);

                                String funds =
                                    userDataAllFiltered[key]!['funds']!;
                                String id = userDataAllFiltered[key]!['id']!;
                                String password =
                                    userDataAllFiltered[key]!['password']!;

                                // print(stockData1[key]!);
                                return Column(
                                  children: [
                                    _buildStockItemWatchlist(
                                        '${key}',
                                        '${id}',
                                        '${funds}',
                                        '${password}',
                                        width,
                                        height),
                                    const Divider(
                                      color: Color.fromARGB(22, 0, 0, 0),
                                      thickness: 0.8,
                                      height: 0,
                                    ),
                                  ],
                                );
                              })),
                    )
                  ],
                )
                /* : Column(
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
                    ))),
   */
                )));
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
          onPressed: () {
            if (stocksToFetch.contains('${instrument_token}')) {
              _updateWatchlistUser(title, 'delete', instrument_token);

              _fetchWatchlist();
              // stocksToFetch.remove('${instrument_token}');
            } else {
              _updateWatchlistGlobal(title, 'write', instrument_token);
              _updateWatchlistUser(title, 'write', instrument_token);

              _fetchWatchlist();
            }

            setState(() {});
          }),
    );
  }

  bool openWatchlist = false;
  bool addFunds = false;

  String _tapStock = '';
  String buySellStockSymbol = '';
  String buySellStockPrice = '';
  TextEditingController _amountController = TextEditingController();

  Widget _buildStockItemWatchlist(String key, String id, String funds,
      String password, double width, double height) {
    return _tapStock != key
        ? InkWell(
            child: Container(
              padding: EdgeInsets.all(
                  16.0), // Add padding to match ListTile's default padding
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey[200],
                    child: Text(id[0]), // Assuming 'id' is a non-empty String
                  ),
                  SizedBox(width: 10), // Space between the avatar and the text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          id, // Directly using 'id' without string interpolation
                          style: const TextStyle(
                            fontFamily: 'M-regular',
                            fontSize: 13,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'password: "${password}"',
                          style: const TextStyle(
                            fontFamily: 'M-semiBold',
                            fontSize: 10,
                            color: Color.fromRGBO(146, 146, 168, 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: RichText(
                      textAlign: TextAlign.end,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${double.parse(funds).toStringAsFixed(2)}\n',
                            style: TextStyle(
                              color: Colors.green,
                              fontFamily: 'M-semiBold',
                              fontSize: 14,
                            ),
                          ),
                          TextSpan(
                            text:
                                ' \n', // Intentional space for layout purposes
                            style: TextStyle(
                              fontSize: 5,
                            ),
                          ),
                          const TextSpan(
                            text: 'Funds',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color.fromRGBO(146, 146, 168, 1),
                              fontFamily: 'M-semiBold',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 13),
                  IconButton(
                      onPressed: () {
                        setState(() {
                          _tapStock = key;
                        });
                        /*globals.userId = id;
                        globals.admin = true;
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const MainPage()));*/
                      },
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.blue,
                        size: 20,
                      ))
                ],
              ),
            ),
            onTap: () {
              if (_tapStock == '') {
                setState(() {
                  _tapStock = key;
                });
              } else {
                setState(() {
                  _tapStock = '';
                });
              }
            },
          )
        : Container(
            padding: EdgeInsets.all(
                16.0), // Add padding to match ListTile's default padding
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.grey[200],
                      child: Text(id[0]), // Assuming 'id' is a non-empty String
                    ),
                    SizedBox(
                        width: 10), // Space between the avatar and the text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            id, // Directly using 'id' without string interpolation
                            style: const TextStyle(
                              fontFamily: 'M-regular',
                              fontSize: 13,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            'password: "${password}"',
                            style: const TextStyle(
                              fontFamily: 'M-semiBold',
                              fontSize: 10,
                              color: Color.fromRGBO(146, 146, 168, 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RichText(
                        textAlign: TextAlign.end,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  '${double.parse(funds).toStringAsFixed(2)}\n',
                              style: TextStyle(
                                color: Colors.green,
                                fontFamily: 'M-semiBold',
                                fontSize: 14,
                              ),
                            ),
                            TextSpan(
                              text:
                                  ' \n', // Intentional space for layout purposes
                              style: TextStyle(
                                fontSize: 5,
                              ),
                            ),
                            const TextSpan(
                              text: 'Funds',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color.fromRGBO(146, 146, 168, 1),
                                fontFamily: 'M-semiBold',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 13),
                    IconButton(
                        onPressed: () {
                          setState(() {
                            _tapStock = '';
                          });
                        },
                        icon: Icon(
                          Icons.keyboard_arrow_up,
                          color: Colors.blue,
                          size: 20,
                        ))
                  ],
                ),
                SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Text(' '), // Assuming 'id' is a non-empty String
                    ),
                    SizedBox(
                        width: 10), // Space between the avatar and the text
                    Expanded(
                      child: Text(
                        'Open Admin View', // Directly using 'id' without string interpolation
                        style: const TextStyle(
                          fontFamily: 'M-semiBold',
                          fontSize: 10,
                          color: Color.fromRGBO(146, 146, 168, 1),
                        ),
                      ),
                    ),

                    IconButton(
                        onPressed: () {
                          globals.userId = id;
                          globals.admin = true;
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const MainPage()));
                        },
                        icon: Icon(
                          Icons.exit_to_app,
                          color: Colors.black,
                          size: 20,
                        )),
                    SizedBox(
                      width: width * 0.1,
                    )
                  ],
                ),
                SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Text(' '), // Assuming 'id' is a non-empty String
                    ),
                    SizedBox(
                        width: 10), // Space between the avatar and the text
                    Expanded(
                      child: Text(
                        'Add Funds', // Directly using 'id' without string interpolation
                        style: const TextStyle(
                          fontFamily: 'M-semiBold',
                          fontSize: 10,
                          color: Color.fromRGBO(146, 146, 168, 1),
                        ),
                      ),
                    ),

                    IconButton(
                        onPressed: () {
                          setState(() {
                            addFunds = !addFunds;
                            _amountController.clear();
                          });
                        },
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.black,
                          size: 20,
                        )),
                    SizedBox(
                      width: width * 0.1,
                    )
                  ],
                ),
                if (addFunds)
                  Container(
                    width: width * 0.3,
                    margin: const EdgeInsets.only(left: 40, right: 40),
                    child: TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        hintText: 'Enter Amount',
                        hintStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          color: Color.fromARGB(74, 0, 0, 0),
                          fontFamily: 'M-regular',
                        ),
                      ),
                    ),
                  ),
                if (addFunds) SizedBox(height: height * 0.03),
                if (addFunds)
                  Container(
                      width: width * 0.3,
                      margin: const EdgeInsets.only(left: 40, right: 40),
                      child: ElevatedButton(
                        onPressed: () {
                          _addFunds(key, _amountController.text);
                          setState(() {
                            addFunds = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text('Add Funds',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Colors.white,
                              fontFamily: 'M-regular',
                            )),
                      )),
                if (addFunds) SizedBox(height: height * 0.01),
                // SizedBox(height: height * 0.04),
                SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Text(' '), // Assuming 'id' is a non-empty String
                    ),
                    SizedBox(
                        width: 10), // Space between the avatar and the text
                    Expanded(
                      child: Text(
                        'Remove User', // Directly using 'id' without string interpolation
                        style: const TextStyle(
                          fontFamily: 'M-semiBold',
                          fontSize: 10,
                          color: Color.fromRGBO(146, 146, 168, 1),
                        ),
                      ),
                    ),

                    IconButton(
                        onPressed: () {
                          _removeUser(key);
                          setState(() {
                            _tapStock = '';
                          });

                          _fetchWatchlist();
                          setState(() {});
                        },
                        icon: Icon(
                          Icons.delete_forever,
                          color: Colors.black,
                          size: 20,
                        )),
                    SizedBox(
                      width: width * 0.1,
                    )
                  ],
                ),
              ],
            ),
          );

    /*InkWell(
      child:  ListTile(
        style: ListTileStyle.list,
        title: Text('${id}',
            style: const TextStyle(
                fontFamily: 'M-regular', fontSize: 13, color: Colors.black)),
        leading: CircleAvatar(
            backgroundColor: Colors.grey[200],
            child: Text(
              '${id[0]}',
            )),
        subtitle: Text('User',
            style: const TextStyle(
                fontFamily: 'M-semiBold',
                fontSize: 10,
                color: Color.fromRGBO(146, 146, 168, 1))),
        trailing: RichText(
          textAlign: TextAlign.end,
          text: TextSpan(
            children: [
              TextSpan(
                text: '${double.parse(funds).toStringAsFixed(2)}\n',
                style: TextStyle(
                  color: Colors.green,
                  fontFamily: 'M-semiBold',
                  fontSize: 14,
                ),
              ),
              TextSpan(
                text: ' \n',
                style: TextStyle(
                  fontSize: 5,
                ),
              ),
              const TextSpan(
                text: 'Funds',
                style: TextStyle(
                  fontSize: 12,
                  color: Color.fromRGBO(146, 146, 168, 1),
                  fontFamily: 'M-semiBold',
                ),
              ),
            ],
          ),
        ),
      ),
      onTap: () {
        setState(() {
          _tapStock = key;
        });
      },
    );*/
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
