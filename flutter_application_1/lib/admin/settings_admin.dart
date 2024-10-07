import 'dart:html';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_application_1/main.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '/global.dart' as globals;

class SettingAdmin extends StatefulWidget {
  const SettingAdmin({super.key});

  @override
  State<SettingAdmin> createState() => _SettingAdminState();
}

class _SettingAdminState extends State<SettingAdmin> {
  @override
  void initState() {
    super.initState();
    _fetchWatchlist();
    //_checkLimit();
    //_updateWallet();
  }

  List<String> userWatchlistAll = [];
  List<String> globalWatchlistAll = [];

  final firestore = FirebaseFirestore.instance;
  void _fetchWatchlist() async {
    userWatchlistAll = [];
    globalWatchlistAll = [];
    setState(() {
      loading1 = true;
    });
    try {
      final querySnapshot = await firestore.collection('users_details').get();
      List<Future<void>> operations = []; // List to hold all async operations

      for (var doc in querySnapshot.docs) {
        final data = doc.data();

        await firestore
            .collection('users')
            .doc('${data['id']}')
            .get()
            .then((DocumentSnapshot documentSnapshot) async {
          if (documentSnapshot.exists) {
            Map<String, dynamic> data =
                documentSnapshot.data() as Map<String, dynamic>;

            // Access watchlist1
            List<String> watchlist1 = List<String>.from(data['watchlist1']);

            for (var i in data['watchlist1']) {
              if (userWatchlistAll.contains(i) == false) {
                userWatchlistAll.add(i);
              }
            }

            //stocksToFetch = watchlist1;
          } else {
            print('Document does not exist on the database');
          }
        });
      }
      _checkLimit();
    } catch (e) {}
    // print(userWatchlistAll);
  }

  int numberOfFields1 = 0;
  _checkLimit() async {
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
      globalWatchlistAll = liveWatchlist.keys.toList().cast<String>();

      //  print("Number of fields in 'live_watchlist': $globalWatchlistAll");

      _findUnique();
    } else {
      // print("'live_watchlist' does not exist or is empty.");
    }
  }

  _findUnique() {
    List<String> uniqueElements =
        findUniqueElements(userWatchlistAll, globalWatchlistAll);
    numberOfFields1 = uniqueElements.length;
    setState(() {});
    print(uniqueElements); // [1, 2, 6, 7]
  }

  List<String> uniqueElements1 = [];

  List<String> findUniqueElements(
      List<String> firstList, List<String> liveWatchlist) {
    // Use .toSet() to convert lists to sets for efficient operation
    final Set<String> firstSet = firstList.toSet();
    final Set<String> liveWatchlistSet = liveWatchlist.toSet();

    // Use .difference() to find elements in 'liveWatchlistSet' that aren't in 'firstSet'
    final Set<String> uniqueElements = liveWatchlistSet.difference(firstSet);

    // Convert the result back to a list if necessary
    return uniqueElements.toList();
  }

  String amount = '0';
  String pending = '0';

  _updateWallet() async {
    try {
      DocumentReference docRef = firestore
          .collection('users')
          .doc(globals.userId)
          .collection('details')
          .doc('wallet');
      DocumentSnapshot snapshot = await docRef.get();

      if (snapshot.exists) {
        Map<String, dynamic> currentData =
            snapshot.data() as Map<String, dynamic>;

        setState(() {
          amount = currentData['available_fund'];
          pending = currentData['current_request'];
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

  @override
  void dispose() {
    super.dispose();
  }

  _withdrawMoney(String amount, String upi) async {
    try {
      DocumentReference docRef = firestore
          .collection('users')
          .doc(globals.userId)
          .collection('details')
          .doc('wallet');
      DocumentSnapshot snapshot = await docRef.get();

      if (snapshot.exists) {
        Map<String, dynamic> currentData =
            snapshot.data() as Map<String, dynamic>;

        double currentAmount = double.parse(currentData['available_fund']);
        double withdrawAmount = double.parse(amount);

        if (currentAmount >= withdrawAmount) {
          //currentAmount -= withdrawAmount;
          await docRef.update({'current_request': amount.toString()});
          setState(() {
            // amount = currentAmount.toString();
            error =
                'Your withdraw request has been submitted. Your money will get deposit in next 24 hrs.';
            _updateWallet();
          });
        } else {
          error = 'Insufficient funds!';
          setState(() {});
        }
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

  String error = '';

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
                      bottom: height * 0.02),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      RichText(
                        text: const TextSpan(
                          children: <TextSpan>[
                            TextSpan(
                              text: 'Account',
                              style: TextStyle(
                                  fontSize: 20,
                                  color: Color.fromRGBO(63, 63, 63, 1),
                                  fontFamily: 'M-regular',
                                  fontWeight: FontWeight.w900),
                            ),
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
                        color: Color.fromARGB(70, 158, 158, 158),
                        // Color of the shadow
                        offset: Offset.zero, // Offset of the shadow
                        blurRadius: 6, // Spread or blur radius of the shadow
                        spreadRadius: 0, // How much the shadow should spread
                      )
                    ]),
                alignment: Alignment.center,
                child: ListTile(
                  title: Text(
                    'Admin',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Color.fromARGB(140, 0, 0, 0),
                      fontFamily: 'M-regular',
                    ),
                  ),
                  trailing: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    foregroundColor: Colors.blue,
                    child: Text(
                      'A',
                      //'${globals.adminId[0].toUpperCase()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'M-regular',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: ListView(
                  children: <Widget>[
                    _clear(height),
                    
                    _logout(height)
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool loading1 = false;

  Widget _clear(double height) {
    return Container(
      width: double.infinity,
      height: height * 0.068,
      margin: const EdgeInsets.only(left: 20, right: 20, top: 10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(70, 158, 158, 158),
              // Color of the shadow
              offset: Offset.zero, // Offset of the shadow
              blurRadius: 6, // Spread or blur radius of the shadow
              spreadRadius: 0, // How much the shadow should spread
            )
          ]),
      alignment: Alignment.center,
      child: ListTile(
          title: RichText(
            text: TextSpan(
              children: <TextSpan>[
                const TextSpan(
                  text: 'Clear Watchlist',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Color.fromARGB(140, 0, 0, 0),
                    fontFamily: 'M-regular',
                  ),
                ),
                const TextSpan(
                  text: '\n',
                  style: TextStyle(
                      fontSize: 1,
                      color: Color.fromARGB(140, 0, 0, 0),
                      fontFamily: 'M-regular',
                      fontWeight: FontWeight.w300),
                ),
                TextSpan(
                  text: '\nCurrent Watchlist Cache : ${numberOfFields1}',
                  style: const TextStyle(
                      fontSize: 9,
                      color: Color.fromARGB(140, 0, 0, 0),
                      fontFamily: 'M-regular',
                      fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
          trailing: IconButton(
              onPressed: () async {
                _clearGlobalWatchlist();
              },
              icon: const Icon(Icons.delete))),
    );
  }

  _clearGlobalWatchlist() {
    final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
    for (var i in uniqueElements1) {
      dbRef.child('live_watchlist/${i}').remove();
    }

    _fetchWatchlist();
    setState(() {
      numberOfFields1 = 0;
    });
  }

  Widget _wallet(double height) {
    return Container(
      width: double.infinity,
      height: height * 0.06,
      margin: const EdgeInsets.only(left: 20, right: 20, top: 20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(70, 158, 158, 158),
              // Color of the shadow
              offset: Offset.zero, // Offset of the shadow
              blurRadius: 6, // Spread or blur radius of the shadow
              spreadRadius: 0, // How much the shadow should spread
            )
          ]),
      alignment: Alignment.center,
      child: ListTile(
        title: const Text(
          'Wallet',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: Color.fromARGB(140, 0, 0, 0),
            fontFamily: 'M-regular',
          ),
        ),
        trailing: Text(
          '₹${double.parse(amount).toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: Color.fromARGB(140, 0, 0, 0),
            fontFamily: 'M-regular',
          ),
        ),
      ),
    );
  }

  bool withdraw = false;

  TextEditingController amountController = TextEditingController();
  TextEditingController upiController = TextEditingController();

  Widget _withdraw(double height, double width) {
    return withdraw == false
        ? Container(
            width: double.infinity,
            height: height * 0.068,
            margin: const EdgeInsets.only(left: 20, right: 20, top: 10),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromARGB(70, 158, 158, 158),
                    // Color of the shadow
                    offset: Offset.zero, // Offset of the shadow
                    blurRadius: 6, // Spread or blur radius of the shadow
                    spreadRadius: 0, // How much the shadow should spread
                  )
                ]),
            alignment: Alignment.center,
            child: ListTile(
                title: RichText(
                  text: TextSpan(
                    children: <TextSpan>[
                      const TextSpan(
                        text: 'Withdraw Funds',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Color.fromARGB(140, 0, 0, 0),
                          fontFamily: 'M-regular',
                        ),
                      ),
                      const TextSpan(
                        text: '\n',
                        style: TextStyle(
                            fontSize: 1,
                            color: Color.fromARGB(140, 0, 0, 0),
                            fontFamily: 'M-regular',
                            fontWeight: FontWeight.w300),
                      ),
                      TextSpan(
                        text:
                            '\nPending Requested Amt. : ₹${double.parse(pending).toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 9,
                            color: Color.fromARGB(140, 0, 0, 0),
                            fontFamily: 'M-regular',
                            fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ),
                trailing: IconButton(
                    onPressed: () {
                      setState(() {
                        withdraw = true;
                        error = '';
                      });
                    },
                    icon: const Icon(Icons.keyboard_arrow_down))),
          )
        : Container(
            width: double.infinity,
            //height: height * 0.2,
            margin: const EdgeInsets.only(left: 20, right: 20, top: 10),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromARGB(70, 158, 158, 158),
                    // Color of the shadow
                    offset: Offset.zero, // Offset of the shadow
                    blurRadius: 6, // Spread or blur radius of the shadow
                    spreadRadius: 0, // How much the shadow should spread
                  )
                ]),
            alignment: Alignment.center,
            child: Column(
              children: [
                ListTile(
                    title: RichText(
                      text: TextSpan(
                        children: <TextSpan>[
                          const TextSpan(
                            text: 'Withdraw Funds',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Color.fromARGB(140, 0, 0, 0),
                              fontFamily: 'M-regular',
                            ),
                          ),
                          const TextSpan(
                            text: '\n',
                            style: TextStyle(
                                fontSize: 1,
                                color: Color.fromARGB(140, 0, 0, 0),
                                fontFamily: 'M-regular',
                                fontWeight: FontWeight.w300),
                          ),
                          TextSpan(
                            text:
                                '\nPending Requested Amt. : ₹${double.parse(pending).toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 9,
                                color: Color.fromARGB(140, 0, 0, 0),
                                fontFamily: 'M-regular',
                                fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                    ),
                    trailing: IconButton(
                        onPressed: () {
                          setState(() {
                            withdraw = false;
                            error = '';
                          });
                        },
                        icon: const Icon(Icons.keyboard_arrow_up))),
                Container(
                  width: width * 0.6,
                  margin: const EdgeInsets.only(left: 40, right: 40),
                  child: TextFormField(
                    controller: amountController,
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
                Container(
                  width: width * 0.6,
                  margin: const EdgeInsets.only(left: 40, right: 40),
                  child: TextFormField(
                    controller: upiController,
                    decoration: const InputDecoration(
                      hintText: 'Enter UPI ID',
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
                if (error != '')
                  Container(
                    width: width * 0.6,
                    margin: const EdgeInsets.only(left: 40, right: 40),
                    child: Text(
                      '$error',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        color: error == 'Insufficient funds!'
                            ? Colors.red
                            : Colors.green,
                        fontFamily: 'M-regular',
                      ),
                    ),
                  ),
                SizedBox(height: height * 0.02),
                Container(
                    width: width * 0.6,
                    margin: const EdgeInsets.only(left: 40, right: 40),
                    child: ElevatedButton(
                      onPressed: () {
                        if (amountController.text != '' &&
                            upiController.text != '') {
                          _withdrawMoney(
                              amountController.text, upiController.text);

                          amountController.clear();
                          upiController.clear();
                        } else {
                          error = 'Please enter amount and UPI ID';
                        }
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text('Withdraw',
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
          );
  }

  bool password = false;

  Widget _password(double height, double width) {
    return password == false
        ? Container(
            width: double.infinity,
            height: height * 0.06,
            margin: const EdgeInsets.only(left: 20, right: 20, top: 10),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromARGB(70, 158, 158, 158),
                    // Color of the shadow
                    offset: Offset.zero, // Offset of the shadow
                    blurRadius: 6, // Spread or blur radius of the shadow
                    spreadRadius: 0, // How much the shadow should spread
                  )
                ]),
            alignment: Alignment.center,
            child: ListTile(
                title: const Text(
                  'Change Password',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Color.fromARGB(140, 0, 0, 0),
                    fontFamily: 'M-regular',
                  ),
                ),
                trailing: IconButton(
                    onPressed: () {
                      setState(() {
                        password = true;
                      });
                    },
                    icon: const Icon(Icons.keyboard_arrow_down))),
          )
        : Container(
            width: double.infinity,
            //height: height * 0.2,
            margin: const EdgeInsets.only(left: 20, right: 20, top: 10),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromARGB(70, 158, 158, 158),
                    // Color of the shadow
                    offset: Offset.zero, // Offset of the shadow
                    blurRadius: 6, // Spread or blur radius of the shadow
                    spreadRadius: 0, // How much the shadow should spread
                  )
                ]),
            alignment: Alignment.center,
            child: Column(
              children: [
                ListTile(
                    title: const Text(
                      'Change Password',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Color.fromARGB(140, 0, 0, 0),
                        fontFamily: 'M-regular',
                      ),
                    ),
                    trailing: IconButton(
                        onPressed: () {
                          setState(() {
                            password = false;
                          });
                        },
                        icon: const Icon(Icons.keyboard_arrow_up))),
                Container(
                  width: width * 0.6,
                  margin: const EdgeInsets.only(left: 40, right: 40),
                  child: TextFormField(
                    decoration: const InputDecoration(
                      hintText: 'Enter Old Password',
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
                  margin: const EdgeInsets.only(left: 40, right: 40),
                  child: TextFormField(
                    decoration: const InputDecoration(
                      hintText: 'Enter New Password',
                      hintStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        color: Color.fromARGB(74, 0, 0, 0),
                        fontFamily: 'M-regular',
                      ),
                    ),
                  ),
                ),
                SizedBox(height: height * 0.04),
                Container(
                    width: width * 0.6,
                    margin: const EdgeInsets.only(left: 40, right: 40),
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text('Change Password',
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
          );
  }

  bool kite = false;

  TextEditingController kiteController = TextEditingController();

  Widget _kiteAPI(double height, double width) {
    return kite == false
        ? Container(
            width: double.infinity,
            height: height * 0.06,
            margin: const EdgeInsets.only(left: 20, right: 20, top: 10),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromARGB(70, 158, 158, 158),
                    // Color of the shadow
                    offset: Offset.zero, // Offset of the shadow
                    blurRadius: 6, // Spread or blur radius of the shadow
                    spreadRadius: 0, // How much the shadow should spread
                  )
                ]),
            alignment: Alignment.center,
            child: ListTile(
                title: const Text(
                  'Kite API',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Color.fromARGB(140, 0, 0, 0),
                    fontFamily: 'M-regular',
                  ),
                ),
                trailing: IconButton(
                    onPressed: () {
                      setState(() {
                        kite = true;
                      });
                    },
                    icon: const Icon(Icons.keyboard_arrow_down))),
          )
        : Container(
            width: double.infinity,
            //height: height * 0.2,
            margin: const EdgeInsets.only(left: 20, right: 20, top: 10),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromARGB(70, 158, 158, 158),
                    // Color of the shadow
                    offset: Offset.zero, // Offset of the shadow
                    blurRadius: 6, // Spread or blur radius of the shadow
                    spreadRadius: 0, // How much the shadow should spread
                  )
                ]),
            alignment: Alignment.center,
            child: Column(
              children: [
                ListTile(
                    title: const Text(
                      'Kite API',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Color.fromARGB(140, 0, 0, 0),
                        fontFamily: 'M-regular',
                      ),
                    ),
                    trailing: IconButton(
                        onPressed: () {
                          setState(() {
                            kite = false;
                          });
                        },
                        icon: const Icon(Icons.keyboard_arrow_up))),
                Container(
                  width: width * 0.6,
                  margin: const EdgeInsets.only(left: 40, right: 40),
                  child: TextFormField(
                    controller: kiteController,
                    decoration: const InputDecoration(
                      hintText: 'Enter Kite API Request Token',
                      hintStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        color: Color.fromARGB(74, 0, 0, 0),
                        fontFamily: 'M-regular',
                      ),
                    ),
                  ),
                ),
                SizedBox(height: height * 0.04),
                Container(
                    width: width * 0.6,
                    margin: const EdgeInsets.only(left: 40, right: 40),
                    child: ElevatedButton(
                      onPressed: () {
                        if (kiteController.text != '') {
                          final DatabaseReference dbRef =
                              FirebaseDatabase.instance.ref();

                          dbRef.child('credentials').update(
                              {'request_token': '${kiteController.text}'});

                          kiteController.clear();
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
                      child: const Text('Update token',
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
          );
  }

  Widget _logout(double height) {
    return Container(
      width: double.infinity,
      height: height * 0.06,
      margin: const EdgeInsets.only(left: 20, right: 20, top: 10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(70, 158, 158, 158),
              // Color of the shadow
              offset: Offset.zero, // Offset of the shadow
              blurRadius: 6, // Spread or blur radius of the shadow
              spreadRadius: 0, // How much the shadow should spread
            )
          ]),
      alignment: Alignment.center,
      child: ListTile(
          title: const Text(
            'Logout',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Color.fromARGB(140, 0, 0, 0),
              fontFamily: 'M-regular',
            ),
          ),
          trailing: IconButton(
              onPressed: () async {
                globals.admin = false;
                globals.adminId = '';
                globals.adminPass = '';
                await FirebaseAuth.instance.signOut();
              },
              icon: const Icon(Icons.logout))),
    );
  }
}
