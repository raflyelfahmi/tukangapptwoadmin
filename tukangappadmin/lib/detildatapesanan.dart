import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailDataPesanan extends StatelessWidget {
  final Map<dynamic, dynamic> order;

  DetailDataPesanan({required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Pesanan'),
        backgroundColor: Colors.blue[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                _buildDetailTile('Pemesan', order['pemesanName']),
                _buildDetailTile('Tukang', order['tukangName']),
                _buildDetailTile('Alamat', order['alamat']),
                _buildDetailTile('Tanggal', order['tanggal']),
                _buildDetailTile('Status', order['status']),
                _buildDetailTile('Pekerjaan', order['pekerjaan']),
                _buildDetailTile('Total Luas', order['totalLuas']?.toString()),
                _buildDetailTile('Jumlah Tukang yang Dibutuhkan', order['jumlahTukang']?.toString()),
                _buildDetailTile('Tanggal Mulai', order['tanggalMulai']),
                _buildDetailTile('Tanggal Berakhir Pekerjaan', order['tanggalBerakhir']),
                _buildDetailTile('Total Kebutuhan', order['totalKebutuhan']?.toString()),
                _buildDetailTile('Status Payment', order['statusPayment']),
                _buildDetailTile('Konfirmasi Tukang', order['konfirmasiTukang'] == 'ditolak'
                    ? 'Ditolak: ${order['alasanPenolakan'] ?? 'Tidak ada alasan'}'
                    : order['konfirmasiTukang']),
                _buildDetailTile('Status Pekerjaan', order['statusPekerjaan']),
                _buildDetailTile('Transfer Tukang', order['transferTukang']?.toString()),
                _buildDetailTile('Tukang Payment', order['tukangPayment']),
                _buildImageTile('Bukti Images', order['buktiImages']),
                _buildFileTile('File Rincian', order['rincianFiles']),
                _buildDetailTile('Review', order['review']),
                _buildDetailTile('Rating', order['rating']?.toString()),
                // Tambahkan status lain yang ingin ditampilkan di sini
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailTile(String title, String? subtitle) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subtitle ?? '-'),
      contentPadding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
    );
  }

  Widget _buildImageTile(String title, Map<dynamic, dynamic>? images) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: images?.values
                .map((url) => InkWell(
                      onTap: () async {
                        if (await canLaunch(url)) {
                          await launch(url);
                        } else {
                          print('Could not launch $url');
                        }
                      },
                      child: Text(
                        'Lihat Gambar',
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ))
                .toList() ??
            [Text('-')],
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
    );
  }

  Widget _buildFileTile(String title, Map<dynamic, dynamic>? files) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: files?.values
                .map((url) => InkWell(
                      onTap: () async {
                        if (await canLaunch(url)) {
                          await launch(url);
                        } else {
                          print('Could not launch $url');
                        }
                      },
                      child: Text(
                        'Lihat Rincian',
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ))
                .toList() ??
            [Text('-')],
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
    );
  }
}
