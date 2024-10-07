import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:intl/intl.dart';

import '../global.dart' as globals;

class Orders extends StatefulWidget {
  const Orders({super.key});

  @override
  State<Orders> createState() => _OrdersState();
}

class _OrdersState extends State<Orders> {
  final firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();

    fetchOrders(DateTime.now());
  }

  Map<String, Map<String, dynamic>> orderAll = {};

  bool loading = false;
  DateTime selectedDate = DateTime.now();

  void fetchOrders(DateTime date) async {
    setState(() {
      loading = true;
    });

    orderAll = {};
    try {
      await firestore
          .collection('users')
          .doc('${globals.userId}')
          .collection('order_holding_position')
          .doc('order')
          .collection('${DateFormat('dd MM yyyy').format(date)}')
          .get()
          .then((value) {
        for (var i in value.docs) {
          orderAll[
              '${((i.data().map((key, value) => MapEntry(key, value)).keys)).toString().replaceAll(RegExp(r'[()]'), '').trim()}'] = {
            'symbol':
                '${(i.data().map((key, value) => MapEntry(key, value)).values.map((e) => e['symbol'])).toString().replaceAll(RegExp(r'[()]'), '').trim()}',
            'price':
                '${(i.data().map((key, value) => MapEntry(key, value)).values.map((e) => e['price'])).toString().replaceAll(RegExp(r'[()]'), '').trim()}',
            'quantity':
                '${(i.data().map((key, value) => MapEntry(key, value)).values.map((e) => e['quantity'])).toString().replaceAll(RegExp(r'[()]'), '').trim()}',
            'buySell':
                '${(i.data().map((key, value) => MapEntry(key, value)).values.map((e) => e['buySell'])).toString().replaceAll(RegExp(r'[()]'), '').trim()}',
            'intradayLongterm':
                '${(i.data().map((key, value) => MapEntry(key, value)).values.map((e) => e['intradayLongterm'])).toString().replaceAll(RegExp(r'[()]'), '').trim()}',
            'exchange':
                '${(i.data().map((key, value) => MapEntry(key, value)).values.map((e) => e['exchange'])).toString().replaceAll(RegExp(r'[()]'), '').trim()}',
            'instrument_type':
                '${(i.data().map((key, value) => MapEntry(key, value)).values.map((e) => e['instrument_type'])).toString().replaceAll(RegExp(r'[()]'), '').trim()}',
          };
        }
        orderAll = sortTransactionsByTime(orderAll);
      });

      // Assuming 'dateTime' is a field in each document
    } catch (e) {
      // Handle the error
      print('Error fetching orders: $e');
    }

    setState(() {});
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime now = DateTime.now();
    DateTime initialDate = DateTime(now.year, now.month, now.day);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate, // Refer step 3
      firstDate: DateTime(2020),
      lastDate: initialDate,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.white, // header background color
              onPrimary: Colors.black, // header text color
              surface: Colors.white, // background color
              onSurface: Colors.black, // body text color
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue, // button text color
              ),
            ),
            dialogTheme: const DialogTheme(
              shape: RoundedRectangleBorder(
                // Slightly rounded corners
                borderRadius: BorderRadius.all(Radius.circular(0)),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        fetchOrders(picked);
        //  print(picked);
      });
    }
  }

  Map<String, Map<String, dynamic>> sortTransactionsByTime(
      Map<String, Map<String, dynamic>> transactions) {
    var dateFormat = DateFormat('HH mm ss');

    // Sort the keys based on time in descending order
    var sortedKeys = transactions.keys.toList()
      ..sort((a, b) {
        var dateTimeA = dateFormat.parse('$a');
        var dateTimeB = dateFormat.parse('$b');
        return dateTimeB.compareTo(dateTimeA); // For descending order
      });

    // Create a new map to hold sorted transactions
    Map<String, Map<String, dynamic>> sortedTransactions = {};
    for (var key in sortedKeys) {
      sortedTransactions[key] = transactions[key]!;
    }

    setState(() {
      loading = false;
    });

    return sortedTransactions;
  }

  @override
  void dispose() {
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
                body: loading == false
                    ? Column(
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
                                          text: 'Orders',
                                          style: TextStyle(
                                              fontSize: 20,
                                              color:
                                                  Color.fromRGBO(63, 63, 63, 1),
                                              fontFamily: 'M-regular',
                                              fontWeight: FontWeight.w900),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(child: Container()),
                                  IconButton(
                                      onPressed: () {
                                        _selectDate(context);
                                      },
                                      icon: const Icon(Icons.sort)),
                                ],
                              )),
                          const Divider(
                            color: Color.fromARGB(22, 0, 0, 0),
                            thickness: 0.8,
                            height: 0,
                          ),
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.only(
                                left: width * 0.01,
                                right: width * 0.01,
                                top: 0,
                              ),
                              child: ListView.builder(
                                  itemCount: orderAll.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    String key1 =
                                        orderAll.keys.elementAt(index);
                                    String name = orderAll[key1]!['symbol'];
                                    String price = orderAll[key1]!['price'];
                                    String quantity =
                                        orderAll[key1]!['quantity'];
                                    String buySell = orderAll[key1]!['buySell'];
                                    String intradayLongterm =
                                        orderAll[key1]!['intradayLongterm'];

                                    return Column(
                                      children: [
                                        InkWell(
                                          child: _buildStockItemWatchlist(
                                              key1,
                                              name,
                                              double.parse(price)
                                                  .toStringAsFixed(2),
                                              quantity,
                                              buySell,
                                              intradayLongterm,
                                              orderAll[key1]!['exchange'],
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
                        ],
                      )
                    :  Center(child: Container(
                                    alignment: Alignment.center,
                                    child: const CircularProgressIndicator(
                                      color: Colors.blue,
                                      strokeWidth: 3,
                                    ),
                                  ),
                    )
                    )
                    )
                    );
  }

  Widget _buildStockItemWatchlist(
      String date,
      String name,
      String price,
      String quantity,
      String buySell,
      String intradayLongterm,
      String exchange,
      double width,
      double height) {
    return Container(
        padding:
            const EdgeInsets.only(left: 17, right: 17, top: 15, bottom: 15),
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
                      color:
                          buySell == 'sell' ? Colors.red[50] : Colors.blue[50],
                      // padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      alignment: Alignment.center,
                      child: Text(
                        '${buySell.toUpperCase()}',
                        style: TextStyle(
                            color: buySell == 'sell' ? Colors.red : Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'M-regular',
                            fontSize: 9),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${quantity}/${quantity}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'M-regular',
                            fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 10),
                Text('${name}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontFamily: 'M-regular',
                    )),
                const SizedBox(height: 4),
                Text('${exchange.toUpperCase()}',
                    style: const TextStyle(
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
                    Text('${date.replaceAll(' ', ':')}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'M-regular',
                            fontSize: 10)),
                    const SizedBox(width: 8),
                    Container(
                      width: width * 0.15,
                      height: height * 0.026,
                      color: Colors.green[50],
                      // padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      alignment: Alignment.center,
                      child: const Text(
                        'COMPLETED',
                        style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'M-regular',
                            fontSize: 9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('${price}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'M-regular',
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('${intradayLongterm.toUpperCase()}',
                    style: const TextStyle(
                        color: Colors.grey,
                        fontFamily: 'M-regular',
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ));
  }
}
