import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tukangappadmin/register_admin.dart';
import 'package:tukangappadmin/riwayat.dart';

import 'dashboard.dart'; // Import halaman AdminDashboard
import 'login_admin.dart'; // Import halaman LoginAdminView
import 'pesananditolak.dart'; // Import halaman PesananDitolakPage
import 'sedangdiproses.dart'; // Import halaman SedangDiprosesPage

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyC2SHwGV5WkKx7VFgKPRqAOodmM_2VDM_Y",
      authDomain: "tukangapp-876e2.firebaseapp.com",
      databaseURL: "https://tukangapp-876e2-default-rtdb.firebaseio.com",
      projectId: "tukangapp-876e2",
      storageBucket: "tukangapp-876e2.appspot.com",
      messagingSenderId: "505748995222",
      appId: "1:505748995222:web:4bbb388f349d29394696b7",
      measurementId: "G-FS4NNNQTBL",
    ),
  ); // Inisialisasi Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/loginAdmin', // Set halaman login sebagai halaman awal
      routes: {
        '/loginAdmin': (context) =>
            LoginAdminView(), // Tambahkan rute untuk LoginAdminView
        '/registerAdmin': (context) =>
            RegisterAdminView(), // Tambahkan rute untuk RegisterAdminView
        '/adminDashboard': (context) =>
            AdminDashboard(), // Tambahkan rute untuk AdminDashboard
        '/pesananditolak': (context) =>
            PesananDitolakPage(), // Tambahkan rute untuk PesananDitolakPage
        '/sedangdiproses': (context) =>
            SedangDiprosesPage(), // Tambahkan rute untuk SedangDiprosesPage
        '/riwayat': (context) =>
            RiwayatPage(), // Tambahkan rute untuk Riwayat
      },
      debugShowCheckedModeBanner: false,
    );
  }
}