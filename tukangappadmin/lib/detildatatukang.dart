import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class DetailDataTukang extends StatelessWidget {
  final String userId;
  final int orderCount;
  final double overallRating;

  DetailDataTukang({required this.userId, required this.orderCount, required this.overallRating});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Tukang'),
        backgroundColor: Colors.blue[700],
      ),
      body: FutureBuilder<DataSnapshot>(
        future: FirebaseDatabase.instance.ref().child('users').child(userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('Data tidak ditemukan'));
          } else {
            final user = snapshot.data!.value as Map<dynamic, dynamic>;
            return Padding(
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
                      _buildDetailTile('Email', user['email']),
                      _buildDetailTile('Name', user['name']),
                      _buildDetailTile('Team Count', user['teamCount']?.toString()),
                      _buildDetailTile('WhatsApp', user['whatsapp']),
                      _buildRolesKeunggulanTile('Roles Keunggulan', user['rolesKeunggulan']),
                      _buildDetailTile('Status Akun', user['statusAkun']),
                      _buildDetailTile('Tanggal Mulai Tersedia', user['tanggalTersedia']),
                      _buildDetailTile('Berapa Kali Dipesan', orderCount.toString()),
                      _buildDetailTile('Rating Keseluruhan', overallRating.toStringAsFixed(1)),
                      // Tambahkan status lain yang ingin ditampilkan di sini
                    ],
                  ),
                ),
              ),
            );
          }
        },
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

  Widget _buildRolesKeunggulanTile(String title, List<dynamic>? roles) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: roles?.map((role) => Text(role)).toList() ?? [Text('-')],
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
    );
  }
}