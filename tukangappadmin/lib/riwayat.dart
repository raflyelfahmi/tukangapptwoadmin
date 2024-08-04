import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:tukangappadmin/navbar.dart';

class RiwayatPage extends StatefulWidget {
  @override
  _RiwayatPageState createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  List<Map> _historyOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistoryOrders();
  }

  void _loadHistoryOrders() async {
    DatabaseEvent event = await _database.child('orders').once();
    DataSnapshot snapshot = event.snapshot;
    if (snapshot.value != null) {
      Map ordersMap = snapshot.value as Map;
      List<Map> tempList = [];
      for (var entry in ordersMap.entries) {
        var order = entry.value as Map;
        order['orderId'] = entry.key;
        if (order['status'] == 'selesai') {
          // Mengambil nama pemesan dan tukang
          order['pemesanName'] = await _getUserName(order['pemesanId']);
          order['tukangName'] = await _getUserName(order['tukangId']);
          tempList.add(order);
        }
      }
      setState(() {
        _historyOrders = tempList;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<String> _getUserName(String userId) async {
    final snapshot = await _database.child('users').child(userId).once();
    if (snapshot.snapshot.value != null) {
      return (snapshot.snapshot.value as Map)['name'] ?? 'Unknown';
    }
    return 'Unknown';
  }

  Widget _buildOrderCard(Map order) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alamat: ${order['alamat']}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Divider(color: Colors.grey[300]),
            _buildInfoRow('Tanggal', order['tanggal']),
            _buildInfoRow('Status', order['status'], color: Colors.green),
            _buildInfoRow('Nama Pemesan', order['pemesanName']),
            _buildInfoRow('Tukang yang Dipilih', order['tukangName']),
            _buildInfoRow('Total Luas', '${order['totalLuas']} m²'),
            _buildInfoRow('Estimasi Pengerjaan', order['estimasi']),
            _buildInfoRow('Konfirmasi Tukang', order['konfirmasiTukang']),
            _buildInfoRow('Pekerjaan', order['pekerjaan']),
            _buildInfoRow('Status Pembayaran', order['statusPayment']),
            _buildInfoRow('Tanggal Mulai Pengerjaan', order['tanggalMulai']),
            _buildInfoRow('Total Biaya Kebutuhan', 'Rp ${order['totalKebutuhan']}'),
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
        title: Text('Riwayat Pesanan'),
        backgroundColor: Colors.blue[700],
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
      ),
      drawer: Sidebar(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _historyOrders.isEmpty
              ? Center(
                  child: Text(
                    'Tidak ada riwayat pesanan.',
                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                )
              : ListView.builder(
                  itemCount: _historyOrders.length,
                  itemBuilder: (context, index) {
                    return _buildOrderCard(_historyOrders[index]);
                  },
                ),
    );
  }
}