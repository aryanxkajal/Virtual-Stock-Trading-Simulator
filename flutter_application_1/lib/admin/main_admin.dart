import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/admin/position_admin.dart';
import 'package:flutter_application_1/admin/settings_admin.dart';
import 'package:flutter_application_1/admin/user_admin.dart';
import 'package:flutter_application_1/admin/withdraw_admin.dart';
import 'package:flutter_application_1/user/orders_user.dart';
import 'package:flutter_application_1/user/portfolio_user.dart';
import 'package:flutter_application_1/user/profile_user.dart';
import 'package:flutter_application_1/user/watchlist_user.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '/global.dart' as globals;

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  @override
  void initState() {
    super.initState();
  }

  var _bottomNavIndex = 0; //default index of a first screen

  final iconList = <IconData>[
    FontAwesomeIcons.user,
    FontAwesomeIcons.wallet,
    FontAwesomeIcons.briefcase,
    FontAwesomeIcons.signIn,
  ];

  @override
  void dispose() {
    super.dispose();
  }
  String currentPage = 'Manage Users';

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
            appBar: AppBar(
              actions: <Widget>[
            PopupMenuButton<String>(
              onSelected: (String value) {
                // Handle the selected value
                setState(() {
                  currentPage = value;
                });
              },
              color: Colors.white,
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'Manage Users',
                  child: Text('Manage Users', style: TextStyle(color: Colors.black, fontFamily: 'M-regular', fontSize: 15)),
                ),
                const PopupMenuItem<String>(
                  value: 'Withdraw Requests',
                  child: Text('Withdraw Requests', style: TextStyle(color: Colors.black, fontFamily: 'M-regular', fontSize: 15)),
                ),
                const PopupMenuItem<String>(
                  value: 'Open Positions',
                  child: Text('Open Positions', style: TextStyle(color: Colors.black, fontFamily: 'M-regular', fontSize: 15)),
                ),
                const PopupMenuItem<String>(
                  value: 'Settings',
                  child: Text('Settings', style: TextStyle(color: Colors.black, fontFamily: 'M-regular', fontSize: 15)),
                ),
              ],
            ),
          ],
              leading: IconButton(
                  onPressed: () async {
                    globals.admin = false;
                    globals.adminId = '';
                    globals.adminPass = '';
                    await FirebaseAuth.instance.signOut();
                  },
                  icon: Icon(
                    Icons.logout,
                    color: Colors.white,
                  )),
              title: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {},
                child: Text('Admin View'),
              ),
              backgroundColor: Colors.black,
              elevation: 5,
            ),
            /* bottomNavigationBar: AnimatedBottomNavigationBar.builder(
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
                            ? "users"
                            : index == 1
                                ? "withdraw"
                                : index == 2
                                    ? "positions"
                                    : "kite API",
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
              // hideAnimationController: _hideBottomBarAnimationController,
              shadow: const BoxShadow(
                offset: Offset(0, 1),
                blurRadius: 12,
                spreadRadius: 0.5,
                color: Color.fromRGBO(66, 66, 80, 255),
              ),
            ),
           */
            body: currentPage == 'Manage Users'
                ? const UserAdmin()
                : currentPage == 'Withdraw Requests'
                    ? WithdrawAdmin()
                    : currentPage == 'Open Positions'
                        ? OpenPositionAdmin()
                        : currentPage == 'Settings' ? SettingAdmin() : Container(),
          )),
    );
  }
}
