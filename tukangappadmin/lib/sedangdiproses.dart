import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:tukangappadmin/navbar.dart';

class SedangDiprosesPage extends StatefulWidget {
  @override
  _SedangDiprosesPageState createState() => _SedangDiprosesPageState();
}

class _SedangDiprosesPageState extends State<SedangDiprosesPage> {
  final DatabaseReference _ordersReference =
      FirebaseDatabase.instance.ref().child('orders');
  final DatabaseReference _usersReference =
      FirebaseDatabase.instance.ref().child('users');
  List<Map<dynamic, dynamic>> _orderList = [];
  Map<String, String> _userNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('initState dipanggil');
    _fetchUserNames().then((_) => _fetchOrders());
  }

  Future<void> _fetchUserNames() async {
    print('Mengambil nama pengguna...');
    final snapshot = await _usersReference.once();
    if (snapshot.snapshot.value != null) {
      final users = snapshot.snapshot.value as Map<dynamic, dynamic>;
      users.forEach((key, value) {
        _userNames[key] = value['name'] ?? 'Unknown';
      });
    }
    print('Jumlah nama pengguna yang diambil: ${_userNames.length}');
  }

  void _fetchOrders() {
    print('Mulai mengambil pesanan...');
    _ordersReference.onValue.listen((event) {
      print('Data diterima dari Firebase');
      List<Map<dynamic, dynamic>> tempList = [];
      final snapshot = event.snapshot;
      if (snapshot.value != null) {
        print('Snapshot value: ${snapshot.value}');
        Map<dynamic, dynamic> orders = snapshot.value as Map<dynamic, dynamic>;
        orders.forEach((key, value) {
          print('Memeriksa pesanan: $key, status: ${value['status']}');
          if (value['status'] == 'proses') {
            print('Pesanan $key memiliki status proses');
            value['id'] = key;
            tempList.add(value);
          }
        });
      } else {
        print('Snapshot value is null');
      }
      setState(() {
        _orderList = tempList;
        _isLoading = false;
      });
      print('Jumlah pesanan yang diproses: ${_orderList.length}');
    }, onError: (error) {
      print('Error fetching orders: $error');
      setState(() {
        _isLoading = false;
      });
    });
  }

  void _updateOrderStatus(String orderId) {
    _ordersReference.child(orderId).update({'status': 'selesai'}).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status pesanan berhasil diperbarui menjadi selesai')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui status pesanan: $error')),
      );
    });
  }

  Widget _buildOrderCard(Map<dynamic, dynamic> order) {
    final pemesanName = _userNames[order['pemesanId']] ?? 'Unknown';
    final tukangName = _userNames[order['tukangId']] ?? 'Unknown';

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
            _buildInfoRow('Status', order['status'], color: Colors.blue),
            _buildInfoRow('Nama Pemesan', pemesanName),
            _buildInfoRow('Tukang yang Dipilih', tukangName),
            _buildInfoRow('Total Luas', order['totalLuas']),
            _buildInfoRow('Estimasi Pengerjaan', order['estimasi']),
            _buildInfoRow('Konfirmasi Tukang', order['konfirmasiTukang']),
            _buildInfoRow('Pekerjaan', order['pekerjaan']),
            _buildInfoRow('Status Pembayaran', order['statusPayment'] ?? 'Belum dibayar'),
            _buildInfoRow('Tanggal Mulai Pengerjaan', order['tanggalMulai']),
            _buildInfoRow('Total Biaya Kebutuhan', order['totalKebutuhan']),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () => _updateOrderStatus(order['id']),
                child: Text('Selesai', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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
    print('Building UI with _orderList: $_orderList');
    return Scaffold(
      appBar: AppBar(
        title: Text('Pesanan Sedang Diproses'),
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _orderList.isEmpty
              ? Center(
                  child: Text(
                    'Tidak ada pesanan yang sedang diproses.',
                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                )
              : ListView.builder(
                  itemCount: _orderList.length,
                  itemBuilder: (context, index) {
                    print('Building order card for index $index: ${_orderList[index]['id']}');
                    return _buildOrderCard(_orderList[index]);
                  },
                ),
    );
  }
}