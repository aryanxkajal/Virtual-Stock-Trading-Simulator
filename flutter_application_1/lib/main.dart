import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/admin/main_admin.dart';
import 'package:flutter_application_1/admin/user_admin.dart';

import 'package:flutter_application_1/user/orders_user.dart';
import 'package:flutter_application_1/user/portfolio_user.dart';
import 'package:flutter_application_1/user/profile_user.dart';
import 'package:flutter_application_1/user/main_user.dart';
import 'package:flutter_application_1/user/watchlist_user.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';
import 'global.dart' as globals;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool error = false;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    error = false;
  } catch (e) {
    error = true;
    print('error firbaseddd $e');
  }

  if (error == false) {
    runApp(MainPage());
  } else {
    runApp(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Error'),
        ),
      ),
    ));
  }
  // runApp(MyApp()
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            // globals.userId = FirebaseAuth.instance.currentUser!.email!;
            // Check if the snapshot has a user
            User? user = snapshot.data;
            if (user == null) {
              // User is not signed in, show the sign-in screen
              return SignInPage();
            }
            //print(user.email);
            globals.userId = user.email!;
            // User is signed in, show the main app screen
            return user.email != 'admin@stockup.com' ? MainPage() : AdminPage();
          }
          // Waiting for authentication state to be available
          return CircularProgressIndicator();
        },
      ),
    );
  }
}
/*
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  void initState() {
    super.initState();
    _checkPortfolio();
  }

  _checkPortfolio() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    DocumentReference docRef = firestore
        .collection('users')
        .doc(globals.userId)
        .collection('order_holding_position')
        .doc('position');

    DocumentSnapshot snapshot = await docRef.get();
    if (snapshot.exists) {
      Map<String, dynamic> currentData =
          snapshot.data() as Map<String, dynamic>;
      if (currentData['date'] ==
          '${DateFormat('dd MM yyyy').format(DateTime.now())}') {
        docRef.delete();
      }
    }

    DocumentReference docRef1 = firestore
        .collection('users')
        .doc(globals.userId)
        .collection('order_holding_position')
        .doc('holdings');

    DocumentSnapshot snapshot1 = await docRef.get();
    if (snapshot1.exists) {
      Map<String, dynamic> currentData1 =
          snapshot1.data() as Map<String, dynamic>;
      if (currentData1['date'] ==
          '${DateFormat('dd MM yyyy').format(DateTime.now())}') {
        docRef1.delete();
      }
    }
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
            // hideAnimationController: _hideBottomBarAnimationController,
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
                      : Profile(),
        ),
      ),
    );
  }
}
*/
////AUTH

class SignInPage extends StatefulWidget {
  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _signInWithEmailAndPassword() async {
    try {
      final User? user = (await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      ))
          .user;

      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully signed in as ${user.email}'),
          ),
        );
        globals.userId = '${_emailController.text}';
        // Navigate to MainPage
        //  Navigator.of(context).pushReplacement(
        //  MaterialPageRoute(builder: (context) => const MainPage()),
        // );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to sign in with Email & Password'),
          ),
        );
      }
    } catch (e) {
      errorSignIn = e.toString();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to sign in with Email & Password'),
        ),
      );
    }
  }

  String errorSignIn = '';

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      body:

          /*Container(
          padding: EdgeInsets.all(35),

          width: double.infinity,
          //height: height * 0.2,
          // margin: const EdgeInsets.only(left: 20, right: 20, top: 10),
          color: Colors.white,
          alignment: Alignment.center,
          child: Column(
            children: [
              SizedBox(
                height: 40,
              ),
              Container(
                alignment: AlignmentDirectional.center,
                child: Text(
                  'Sign In',
                  style: TextStyle(
                      fontFamily: 'M-bold',
                      fontSize: 30,
                      fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                height: 80,
              ),
              Container(
                width: width * 0.6,
                margin: const EdgeInsets.only(left: 40, right: 40),
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Enter Id, eg. xxyy@stockup.com',
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
                 // obscureText: true,
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
                  '${errorSignIn}',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontFamily: 'M-regular',
                  ),
                ),
              ),
              SizedBox(height: height * 0.02),
              Container(
                  width: width * 0.6,
                  height: height * 0.06,
                  margin: const EdgeInsets.only(left: 33, right: 34),
                  child: ElevatedButton(
                    onPressed: () => _signInWithEmailAndPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text('Sign In',
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
        )*/
          Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              height: 40,
            ),
            Container(
              alignment: AlignmentDirectional.center,
              child: Text(
                'Sign In',
                style: TextStyle(
                    fontFamily: 'M-bold',
                    fontSize: 30,
                    fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 80,
            ),
            Container(
              width: width * 0.6,
              margin: const EdgeInsets.only(left: 40, right: 40),
              child: TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  hintText: 'Enter Id, eg. xxyy@stockup.com',
                  hintStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    color: Color.fromARGB(74, 0, 0, 0),
                    fontFamily: 'M-regular',
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            Container(
              width: width * 0.6,
              margin: const EdgeInsets.only(left: 40, right: 40),
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
                obscureText: true,
              ),
            ),
            SizedBox(height: height * 0.02),
            Container(
              child: Text(
                '${errorSignIn}',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontFamily: 'M-regular',
                ),
              ),
            ),
            SizedBox(height: height * 0.02),
            Container(
              width: width * 0.6,
              height: height * 0.06,
              margin: const EdgeInsets.only(left: 33, right: 33),
              child: ElevatedButton(
                onPressed: _signInWithEmailAndPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text('Sign In',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Colors.white,
                      fontFamily: 'M-regular',
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
