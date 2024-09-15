import 'package:flutter/material.dart';

import 'dashboard.dart'; // Import halaman dashboard
import 'pesanan.dart';  // Import halaman pesanan

class Sidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            child: Text('Menu'),
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
          ),
          ListTile(
            title: Text('Dashboard'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminDashboard()),
              );
            },
          ),
          ListTile(
            title: Text('Kelola Pesanan'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PesananPage()),
              );
            },
          ),
          // ListTile(
          //   title: Text('Pesanan Sedang Diproses'),
          //   onTap: () {
          //     Navigator.pushNamed(context, '/sedangdiproses');
          //   },
          // ),
          // ListTile(
          //   title: Text('Pesanan Ditolak'),
          //   onTap: () {
          //     Navigator.pushNamed(context, '/pesananditolak');
          //   },
          // ),
          // ListTile(
          //   title: Text('Riwayat Pesanan'),
          //   onTap: () {
          //     Navigator.pushNamed(context, '/riwayat');
          //   },
          // ),
        ],
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Your App Title'),
        ),
        drawer: Sidebar(), // Tambahkan ini untuk menampilkan sidebar
        body: Center(
          child: Text('Selamat datang di aplikasi Anda!'),
        ),
      ),
    );
  }
}

void main() {
  runApp(MyApp());
}