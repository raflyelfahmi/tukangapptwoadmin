import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class DetilSedangDiprosesPage extends StatelessWidget {
  final Map<dynamic, dynamic> order;

  DetilSedangDiprosesPage({required this.order});

  final DatabaseReference _ordersReference =
      FirebaseDatabase.instance.ref().child('orders');

  void _updateOrderStatus(BuildContext context, String orderId) {
    _ordersReference.child(orderId).update({'status': 'selesai'}).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status pesanan berhasil diperbarui menjadi selesai')),
      );
      Navigator.pop(context);
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui status pesanan: $error')),
      );
    });
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

  Widget _buildBuktiImages(String orderId) {
    return FutureBuilder<DatabaseEvent>(
      future: _ordersReference.child(orderId).child('buktiImages').once(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return Center(child: Text('Tidak ada bukti proses yang diunggah'));
        }

        final buktiImages = snapshot.data!.snapshot.value as Map<dynamic, dynamic>?;
        if (buktiImages == null || buktiImages.isEmpty) {
          return Center(child: Text('Tidak ada bukti proses yang diunggah'));
        }

        return Column(
          children: buktiImages.values.map<Widget>((imageUrl) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Image.network(imageUrl, height: 200),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Pesanan'),
        backgroundColor: Colors.blue[700],
      ),
      body: SingleChildScrollView(
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
            _buildInfoRow('Total Luas', order['totalLuas']),
            _buildInfoRow('Estimasi Pengerjaan', order['estimasi']),
            _buildInfoRow('Konfirmasi Tukang', order['konfirmasiTukang']),
            _buildInfoRow('Pekerjaan', order['pekerjaan']),
            _buildInfoRow('Status Pembayaran', order['statusPayment'] ?? 'Belum dibayar'),
            _buildInfoRow('Tanggal Mulai Pengerjaan', order['tanggalMulai']),
            _buildInfoRow('Total Biaya Kebutuhan', order['totalKebutuhan']),
            if (order['statusPekerjaan'] != null) // Tambahkan kondisi untuk status pekerjaan
              _buildInfoRow('Status Pekerjaan', order['statusPekerjaan']),
            SizedBox(height: 16),
            Text(
              'Bukti Proses:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            _buildBuktiImages(order['id']),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () => _updateOrderStatus(context, order['id']),
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
}