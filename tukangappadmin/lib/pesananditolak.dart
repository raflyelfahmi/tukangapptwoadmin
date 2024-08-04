import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:tukangappadmin/navbar.dart';

class PesananDitolakPage extends StatefulWidget {
  @override
  _PesananDitolakPageState createState() => _PesananDitolakPageState();
}

class _PesananDitolakPageState extends State<PesananDitolakPage> {
  final DatabaseReference _ordersReference =
      FirebaseDatabase.instance.ref().child('orders');
  final DatabaseReference _usersReference =
      FirebaseDatabase.instance.ref().child('users');
  List<Map<dynamic, dynamic>> _orderList = [];
  List<Map<dynamic, dynamic>> _tukangList = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _fetchTukang();
  }

  void _fetchOrders() {
    _ordersReference.once().then((DatabaseEvent event) {
      List<Map<dynamic, dynamic>> tempList = [];
      final snapshot = event.snapshot;
      if (snapshot.value != null) {
        (snapshot.value as Map).forEach((key, value) {
          if (value['konfirmasiTukang'] == 'ditolak') {
            value['id'] = key; // Tambahkan ID pesanan ke data
            tempList.add(value);
          }
        });
      }
      setState(() {
        _orderList = tempList;
      });
      print('Fetched orders: $_orderList'); // Logging untuk debugging
    }).catchError((error) {
      print('Error fetching orders: $error'); // Logging untuk error
    });
  }

  void _fetchTukang() {
    _usersReference
        .orderByChild('role')
        .equalTo('tukang')
        .once()
        .then((DatabaseEvent event) {
      List<Map<dynamic, dynamic>> tempList = [];
      final snapshot = event.snapshot;
      if (snapshot.value != null) {
        (snapshot.value as Map).forEach((key, value) {
          value['id'] = key; // Tambahkan ID tukang ke data
          tempList.add(value);
        });
      }
      setState(() {
        _tukangList = tempList;
      });
      print('Fetched tukang: $_tukangList'); // Logging untuk debugging
    }).catchError((error) {
      print('Error fetching tukang: $error'); // Logging untuk error
    });
  }

  Future<String> _getUserName(String userId) async {
    final snapshot = await _usersReference.child(userId).once();
    if (snapshot.snapshot.value != null) {
      return (snapshot.snapshot.value as Map)['name'];
    }
    return 'Unknown';
  }

  void _updateTukangId(String orderId, String newTukangId) {
    _ordersReference.child(orderId).update({
      'tukangId': newTukangId,
      'konfirmasiTukang':
          'pending', // Ubah status konfirmasiTukang menjadi pending
      'alasanPenolakan': null, // Hapus status alasanPenolakan
    }).then((_) {
      print(
          'Order $orderId updated with new tukangId $newTukangId, konfirmasiTukang set to pending, and alasanPenolakan removed'); // Logging untuk debugging
      setState(() {
        _fetchOrders(); // Refresh order list after update
      });
    }).catchError((error) {
      print('Error updating order: $error'); // Logging untuk error
    });
  }

  void _showTukangDialog(String orderId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pilih Tukang Baru'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _tukangList.length,
              itemBuilder: (context, index) {
                final tukang = _tukangList[index];
                return ListTile(
                  title: Text(tukang['name']),
                  onTap: () {
                    _updateTukangId(orderId, tukang['id']);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(Map<dynamic, dynamic> order, String pemesanName, String tukangName) {
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
            Divider(),
            _buildInfoRow('Tanggal', order['tanggal']),
            _buildInfoRow('Status', order['status'], color: Colors.red),
            _buildInfoRow('Nama Pemesan', pemesanName),
            _buildInfoRow('Tukang yang Dipilih', tukangName),
            _buildInfoRow('Total Luas', '${order['totalLuas']} m'),
            _buildInfoRow('Total Kebutuhan', 'Rp ${order['totalKebutuhan']}'),
            _buildInfoRow('Tanggal Mulai', order['tanggalMulai']),
            _buildInfoRow('Estimasi', order['estimasi']),
            _buildInfoRow('Alasan Penolakan', order['alasanPenolakan'], color: Colors.red),
            SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _showTukangDialog(order['id']),
                icon: Icon(Icons.edit),
                label: Text('Pilih Tukang Baru'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: color),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pesanan Ditolak'),
        backgroundColor: Colors.red[700],
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
                'Tidak ada pesanan yang ditolak.',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            )
          : ListView.builder(
              itemCount: _orderList.length,
              itemBuilder: (context, index) {
                final order = _orderList[index];
                return FutureBuilder(
                  future: Future.wait([
                    _getUserName(order['pemesanId']),
                    _getUserName(order['tukangId']),
                  ]),
                  builder: (context, AsyncSnapshot<List<String>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    final pemesanName = snapshot.data![0];
                    final tukangName = snapshot.data![1];
                    return _buildOrderCard(order, pemesanName, tukangName);
                  },
                );
              },
            ),
    );
  }
}