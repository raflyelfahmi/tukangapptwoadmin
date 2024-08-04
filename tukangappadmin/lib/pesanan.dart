import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'navbar.dart';
import 'rab.dart';

class PesananPage extends StatefulWidget {
  @override
  _PesananPageState createState() => _PesananPageState();
}

class _PesananPageState extends State<PesananPage> {
  final DatabaseReference _ordersReference = FirebaseDatabase.instance.ref().child('orders');
  final DatabaseReference _usersReference = FirebaseDatabase.instance.ref().child('users');
  List<Map<dynamic, dynamic>> _orderList = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  void _fetchOrders() {
    _ordersReference.onValue.listen((event) {
      List<Map<dynamic, dynamic>> tempList = [];
      final snapshot = event.snapshot;
      if (snapshot.value != null) {
        Map<dynamic, dynamic> orders = snapshot.value as Map<dynamic, dynamic>;
        orders.forEach((key, value) {
          if (['pending', 'approved', 'menunggu'].contains(value['status'])) {
            value['id'] = key;
            tempList.add(value);
          }
        });
      }
      setState(() {
        _orderList = tempList;
      });
      print('Fetched orders: $_orderList');
    }, onError: (error) {
      print('Error fetching orders: $error');
    });
  }

  Future<String> _getUserName(String userId) async {
    final snapshot = await _usersReference.child(userId).once();
    if (snapshot.snapshot.value != null) {
      return (snapshot.snapshot.value as Map)['name'] ?? 'Unknown';
    }
    return 'Unknown';
  }

  void _updateOrderStatus(String orderId, String status) {
    _ordersReference.child(orderId).update({'status': status}).then((_) {
      print('Order $orderId updated to $status');
      setState(() {
        _fetchOrders();
      });
    }).catchError((error) {
      print('Error updating order: $error');
    });
  }

  void _navigateToRabPage(Map<dynamic, dynamic> order) async {
    final pemesanName = await _getUserName(order['pemesanId']);
    final tukangName = await _getUserName(order['tukangId']);
    order['pemesanName'] = pemesanName;
    order['tukangName'] = tukangName;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RabPage(order: order)),
    );
  }

  Widget _buildOrderCard(Map<dynamic, dynamic> order) {
    final isApproved = order['status'] == 'approved';
    final isWaiting = order['status'] == 'menunggu';

    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alamat: ${order['alamat']}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Tanggal: ${order['tanggal']}'),
            Text('Status: ${order['status']}',
                style: TextStyle(
                  color: isApproved
                      ? Colors.green
                      : isWaiting
                          ? Colors.orange
                          : Colors.blue,
                  fontWeight: FontWeight.bold,
                )),
            SizedBox(height: 8),
            FutureBuilder(
              future: _getUserName(order['pemesanId']),
              builder: (context, snapshot) {
                return Text(
                  'Nama Pemesan: ${snapshot.connectionState == ConnectionState.waiting ? 'Loading...' : snapshot.data}',
                  style: TextStyle(fontStyle: FontStyle.italic),
                );
              },
            ),
            FutureBuilder(
              future: _getUserName(order['tukangId']),
              builder: (context, snapshot) {
                return Text(
                  'Tukang yang Dipilih: ${snapshot.connectionState == ConnectionState.waiting ? 'Loading...' : snapshot.data}',
                  style: TextStyle(fontStyle: FontStyle.italic),
                );
              },
            ),
            SizedBox(height: 16),
            if (!isWaiting)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: isApproved ? null : () => _updateOrderStatus(order['id'], 'approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isApproved ? Colors.grey : Colors.blue,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(isApproved ? 'Approved' : 'Approve', style: TextStyle(color: Colors.white)),
                  ),
                  SizedBox(width: 8),
                  if (isApproved)
                    ElevatedButton(
                      onPressed: () => _navigateToRabPage(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text('Proses', style: TextStyle(color: Colors.white)),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('Building UI with _orderList: $_orderList');
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Pesanan'),
        backgroundColor: Colors.blue[700],
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: Sidebar(),
      body: _orderList.isEmpty
          ? Center(
              child: Text(
                'Belum ada pesanan yang perlu dikelola.',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            )
          : ListView.builder(
              itemCount: _orderList.length,
              itemBuilder: (context, index) {
                return _buildOrderCard(_orderList[index]);
              },
            ),
    );
  }
}