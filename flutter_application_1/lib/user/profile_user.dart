import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

import '../global.dart' as globals;

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  @override
  void initState() {
    super.initState();
    _updateWallet();
  }

  final firestore = FirebaseFirestore.instance;

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

  Future<void> changePasswordWithReAuth({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    // Get the current user
    User? user = FirebaseAuth.instance.currentUser;

    // Check if the user is not null
    if (user != null) {
      // Create credential for re-authentication
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: oldPassword,
      );

      try {
        // Re-authenticate the user
        await user.reauthenticateWithCredential(credential);
        print("User re-authenticated successfully");

        // Proceed with the password change after re-authentication
        await user.updatePassword(newPassword);

        _handleSignUp(email, newPassword);
        setState(() {
          errorChange = 'Password changed successfully.';
        });

        print("Password changed successfully");
      } on FirebaseAuthException catch (e) {
        // Handle specific FirebaseAuthException errors
        if (e.code == 'weak-password') {
          setState(() {
            errorChange = 'The password provided is too weak.';
          });
          print('The password provided is too weak.');
        } else if (e.code == 'user-not-found') {
          print('No user found for that email.');
          setState(() {
            errorChange = 'No user found for that email.';
          });
        } else if (e.code == 'wrong-password') {
          setState(() {
            errorChange = 'Wrong password provided.';
          });
          print('Wrong password provided.');
        } else {
          setState(() {
            errorChange = e.toString();
          });
          print(e.toString());
        }
      } catch (e) {
        // Handle any other errors
        print(e.toString());
      }
    } else {
      setState(() {
        errorChange = 'No user is signed in';
      });
      print("No user is signed in");
    }
  }

  _handleSignUp(String id, String password) async {
    try {
      await firestore
          .collection('users_details')
          .doc('${id}')
          .set({'id': '${id}', 'password': '${password}'});
    } catch (e) {
      print(e);
    }
  }

  String errorChange = '';

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
                    '${globals.userId}',
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
                      '${globals.userId[0].toUpperCase()}',
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
                    _wallet(height),
                    _withdraw(height, width),
                    _password(height, width),
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

  TextEditingController oldPasswordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();

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
                    controller: oldPasswordController,
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
                    controller: newPasswordController,
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
                SizedBox(height: height * 0.02),
                Container(
                  child: Text(
                    '${errorChange}',
                    style: TextStyle(
                      color: errorChange != 'Password changed successfully.'
                          ? Colors.red
                          : Colors.green,
                      fontSize: 10,
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
                        if (oldPasswordController.text != '' &&
                            newPasswordController.text != '') {
                          changePasswordWithReAuth(
                              email: globals.userId,
                              oldPassword: oldPasswordController.text,
                              newPassword: newPasswordController.text);

                          oldPasswordController.clear();
                          newPasswordController.clear();
                        } else {
                          errorChange = 'Please enter complete details.';
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
                await FirebaseAuth.instance.signOut();
              },
              icon: const Icon(Icons.logout))),
    );
  }
}
