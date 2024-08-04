import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'navbar.dart'; // Import Sidebar dari navbar.dart

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  AdminDashboardState createState() => AdminDashboardState();
}

class AdminDashboardState extends State<AdminDashboard> {
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref().child('users');
  List<Map<dynamic, dynamic>> _userList = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  void _fetchUsers() {
    _databaseReference.orderByChild('role').equalTo('tukang').once().then((DatabaseEvent event) {
      List<Map<dynamic, dynamic>> tempList = [];
      final snapshot = event.snapshot;
      if (snapshot.value != null) {
        (snapshot.value as Map).forEach((key, value) {
          if (value['status'] != 'approved') { // Filter tukang yang belum disetujui
            value['id'] = key; // Tambahkan ID pengguna ke data
            tempList.add(value);
          }
        });
      }
      setState(() {
        _userList = tempList;
      });
      print('Fetched users: $_userList'); // Logging untuk debugging
    }).catchError((error) {
      print('Error fetching users: $error'); // Logging untuk error
    });
  }

  void _approveUser(String userId) {
    _databaseReference.child(userId).update({'status': 'approved'}).then((_) {
      print('User $userId approved'); // Logging untuk debugging
      setState(() {
        // Refresh user list after approval
        _fetchUsers();
      });
    }).catchError((error) {
      print('Error approving user: $error'); // Logging untuk error
    });
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                Scaffold.of(context).openDrawer(); // Buka sidebar saat tombol ditekan
              },
            );
          },
        ),
      ),
      drawer: Sidebar(), // Tambahkan ini untuk menampilkan sidebar
      body: Container(
        color: Colors.grey[100],
        child: _userList.isEmpty
            ? Center(
                child: Text('Belum ada pendaftar baru yang perlu di-acc.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              )
            : ListView.builder(
                itemCount: _userList.length,
                itemBuilder: (context, index) {
                  final user = _userList[index];
                  final isApproved = user['status'] == 'approved'; // Cek status persetujuan dari data pengguna
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['name'],
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text('Email: ${user['email']}'),
                          Text('WhatsApp: ${user['whatsapp']}'),
                          SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _launchURL(user['pdfUrl']),
                            child: const Text(
                              'Lihat PDF',
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: isApproved ? null : () => _approveUser(user['id']), // Nonaktifkan tombol jika sudah disetujui
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white, backgroundColor: isApproved ? Colors.green : Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(isApproved ? 'Approved' : 'Approve'), // Ubah teks tombol jika sudah disetujui
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}