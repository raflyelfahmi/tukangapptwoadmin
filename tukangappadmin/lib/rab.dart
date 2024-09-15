import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RabPage extends StatefulWidget {
  final Map<dynamic, dynamic> order;

  RabPage({required this.order});

  @override
  _RabPageState createState() => _RabPageState();
}

class _RabPageState extends State<RabPage> {
  final DatabaseReference _ordersReference = FirebaseDatabase.instance.ref().child('orders');
  final TextEditingController _luasController = TextEditingController();
  final TextEditingController _pekerjaanController = TextEditingController();
  final TextEditingController _kebutuhanController = TextEditingController();
  final TextEditingController _tanggalMulaiController = TextEditingController();
  final TextEditingController _tanggalBerakhirController = TextEditingController();
  final TextEditingController _jumlahTukangController = TextEditingController(); // Tambahkan controller untuk jumlah tukang

  void _submitRab() {
    final String luas = _luasController.text;
    final String pekerjaan = _pekerjaanController.text;
    final String kebutuhan = _kebutuhanController.text;
    final String tanggalMulai = _tanggalMulaiController.text;
    final String tanggalBerakhir = _tanggalBerakhirController.text;
    final String jumlahTukang = _jumlahTukangController.text; // Ambil nilai dari controller jumlah tukang

    if (luas.isNotEmpty && pekerjaan.isNotEmpty && kebutuhan.isNotEmpty && tanggalMulai.isNotEmpty && tanggalBerakhir.isNotEmpty && jumlahTukang.isNotEmpty) {
      _ordersReference.child(widget.order['id']).update({
        'totalLuas': luas,
        'pekerjaan': pekerjaan,
        'totalKebutuhan': kebutuhan,
        'tanggalMulai': tanggalMulai,
        'tanggalBerakhir': tanggalBerakhir,
        'jumlahTukang': jumlahTukang, // Simpan jumlah tukang di database
        'status': 'menunggu',
      }).then((_) {
        print('RAB updated for order ${widget.order['id']}');
        Navigator.pop(context);
      }).catchError((error) {
        print('Error updating RAB: $error');
      });
    } else {
      print('Please fill in all fields');
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(), // Tidak bisa memilih tanggal yang sudah lewat
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  Widget _buildInfoText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rencana Anggaran Biaya'),
        backgroundColor: Colors.blue[700],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informasi Pesanan',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    _buildInfoText('Alamat', widget.order['alamat']),
                    _buildInfoText('Tanggal', widget.order['tanggal']),
                    _buildInfoText('Status', widget.order['status']),
                    _buildInfoText('Status Pembayaran', widget.order['paymentStatus'] ?? 'Belum ada status pembayaran'),
                    _buildInfoText('Nama Pemesan', widget.order['pemesanName']),
                    _buildInfoText('Tukang yang Dipilih', widget.order['tukangName']),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Detail RAB',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _luasController,
              decoration: InputDecoration(
                labelText: 'Total Luas yang Perlu Dikerjakan',
                border: OutlineInputBorder(),
                suffixText: 'm',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _pekerjaanController,
              decoration: InputDecoration(
                labelText: 'Pekerjaan yang dibutuhkan',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _kebutuhanController,
              decoration: InputDecoration(
                labelText: 'Total Biaya Kebutuhan',
                border: OutlineInputBorder(),
                suffixText: 'Rp',
                helperText: 'Contoh: keramik, cat, atap, dll. termasuk jasa pengerjaan',
              ),
              keyboardType: TextInputType.text,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _tanggalMulaiController,
              decoration: InputDecoration(
                labelText: 'Tanggal Mulai Pekerjaan',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () => _selectDate(context, _tanggalMulaiController),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _tanggalBerakhirController,
              decoration: InputDecoration(
                labelText: 'Tanggal Berakhir Pekerjaan',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () => _selectDate(context, _tanggalBerakhirController),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _jumlahTukangController, // Tambahkan TextField untuk jumlah tukang
              decoration: InputDecoration(
                labelText: 'Jumlah Tukang yang Dibutuhkan',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _submitRab,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  child: Text(
                    'Kirim RAB',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}