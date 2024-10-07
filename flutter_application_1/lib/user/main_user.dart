import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/admin/main_admin.dart';

import 'package:flutter_application_1/user/orders_user.dart';

import 'package:flutter_application_1/user/portfolio_user.dart';
import 'package:flutter_application_1/user/profile_user.dart';
import 'package:flutter_application_1/user/watchlist_user.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../global.dart' as globals;

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  void initState() {
    super.initState();
    if (globals.adminId != '') {
      _signIn();
    } else {}
    _checkPortfolio();
    uploadCsvDataToFirebase();
  }

  Future<void> uploadCsvDataToFirebase() async {
    // Read the CSV file from assets
    print('start');
    final String csvData =
        await rootBundle.loadString('assets/instruments.csv');

    // Parse CSV data
    List<List<dynamic>> rowsAsListOfValues =
        const CsvToListConverter().convert(csvData);

    int count = 0;

    List<dynamic> instrument_token = [];

    Map<String, dynamic> dataMap = {};

    print('start');
    for (final row in rowsAsListOfValues) {
      // Create a map from the CSV data, assuming the first 3 columns are ID, Name, and Description
      // final Map<String, dynamic>

      if (count <= 1000) {
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
        /*await firestore
          .collection('stock_data_master')
          .doc() // Using the company symbol as the document ID
          .set(dataMap);*/
        if (count == 0) {
        } else {
          globals.instrumentsAll[row[2]] = dataMap;
        }

        count++;
        print(count);
        continue;
      } else {
        break;
      }
    }

    print(globals.instrumentsAll);
    print('end');
  }

  _signIn() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    globals.userId = globals.adminId;
    await _auth.signInWithEmailAndPassword(
      email: globals.adminId,
      password: globals.adminPass,
    );
  }

  _checkPortfolio() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      DocumentReference docRef = firestore
          .collection('users')
          .doc(globals.userId)
          .collection('order_holding_position')
          .doc('position');

      DocumentSnapshot snapshot = await docRef.get();
      if (snapshot.exists) {
        Map<String, dynamic> currentData =
            snapshot.data() as Map<String, dynamic>;
        //print(currentData);
        for (var i in currentData.entries) {
          if ('${i.value['date']}' !=
              '${DateFormat('dd MM yyyy').format(DateTime.now())}') {
            docRef.update({i.key: FieldValue.delete()});
          }
        }
      }

      DocumentReference docRef1 = firestore
          .collection('users')
          .doc(globals.userId)
          .collection('order_holding_position')
          .doc('holdings');

      DocumentSnapshot snapshot1 = await docRef1.get();
      if (snapshot1.exists) {
        Map<String, dynamic> currentData1 =
            snapshot1.data() as Map<String, dynamic>;
        //    print(currentData1);
        for (var i in currentData1.entries) {
          if ('${i.value['date']}' !=
              '${DateFormat('dd MM yyyy').format(DateTime.now())}') {
            docRef1.update({i.key: FieldValue.delete()});
          }
        }
      }
    } catch (e) {}
  }

  var _bottomNavIndex = 0; //default index of a first screen

  final iconList = <IconData>[
    FontAwesomeIcons.bookmark,
    FontAwesomeIcons.book,
    FontAwesomeIcons.briefcase,
    FontAwesomeIcons.user,
  ];

  @override
  void dispose() {
    super.dispose();
  }

  int Index = 0;
  @override
  Widget build(BuildContext context) {
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
          appBar: globals.admin
              ? AppBar(
                  leading: IconButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        globals.userId = 'admin@stockup.com';
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AdminPage()),
                        );
                      },
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 30,
                      )),
                  title: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {},
                    child: Text('Admin View (${globals.userId})'),
                  ),
                  backgroundColor: Colors.black,
                  elevation: 5,
                )
              : null,
          bottomNavigationBar: AnimatedBottomNavigationBar.builder(
            scaleFactor: 0.1,
            itemCount: iconList.length,
            tabBuilder: (int index, bool isActive) {
              final color = isActive
                  ? const Color.fromRGBO(65, 132, 243, 1)
                  : const Color.fromRGBO(66, 66, 80, 1);

              return Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 1),
                  Icon(
                    iconList[index],
                    size: 22,
                    color: color,
                  ),
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      index == 0
                          ? "Watchlist"
                          : index == 1
                              ? "Orders"
                              : index == 2
                                  ? "Portfolio"
                                  : "Settings",
                      maxLines: 1,

                      style: TextStyle(
                          color: color,
                          fontFamily: 'Helvetica',
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                      //group: autoSizeGroup,
                    ),
                  ),
                  const SizedBox(height: 1),
                ],
              );
            },
            backgroundColor: const Color.fromRGBO(254, 255, 254, 1),
            activeIndex: _bottomNavIndex,
            splashColor: Colors.black,
            splashRadius: 0,
            gapLocation: GapLocation.none,
            leftCornerRadius: 0,
            rightCornerRadius: 0,
            onTap: (index) {
              setState(() {
                _bottomNavIndex = index;

                setState(() {});
              });
            },
            shadow: const BoxShadow(
              offset: Offset(0, 1),
              blurRadius: 12,
              spreadRadius: 0.5,
              color: Color.fromRGBO(66, 66, 80, 255),
            ),
          ),
          body: _bottomNavIndex == 0
              ? const WatchList()
              : _bottomNavIndex == 1
                  ? const Orders()
                  : _bottomNavIndex == 2
                      ? const Portfolio()
                      : const Profile(),
        ),
      ),
    );
  }
}
