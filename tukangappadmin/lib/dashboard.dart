import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'navbar.dart'; // Import Sidebar dari navbar.dart
import 'detildatatukang.dart'; // Import halaman detail tukang

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  AdminDashboardState createState() => AdminDashboardState();
}

class AdminDashboardState extends State<AdminDashboard> {
  final DatabaseReference _usersReference = FirebaseDatabase.instance.ref().child('users');
  final DatabaseReference _ordersReference = FirebaseDatabase.instance.ref().child('orders');
  List<Map<dynamic, dynamic>> _userList = [];
  Map<String, int> _orderCount = {};
  Map<String, double> _overallRating = {};

  @override
  void initState() {
    super.initState();
    _fetchUsersAndOrders();
  }

  void _fetchUsersAndOrders() async {
    await _fetchOrders();
    _fetchUsers();
  }

  Future<void> _fetchOrders() async {
    _ordersReference.once().then((DatabaseEvent event) {
      final snapshot = event.snapshot;
      if (snapshot.value != null) {
        final orders = snapshot.value as Map;
        Map<String, int> tempOrderCount = {};
        Map<String, double> tempOverallRating = {};
        Map<String, int> ratingCount = {};

        orders.forEach((key, value) {
          final tukangId = value['tukangId'];
          if (tukangId != null) {
            // Hitung jumlah pesanan selesai
            if (value['status'] == 'selesai') {
              if (tempOrderCount.containsKey(tukangId)) {
                tempOrderCount[tukangId] = tempOrderCount[tukangId]! + 1;
              } else {
                tempOrderCount[tukangId] = 1;
              }
            }

            // Hitung rating keseluruhan
            if (value['rating'] != null) {
              if (tempOverallRating.containsKey(tukangId)) {
                tempOverallRating[tukangId] = tempOverallRating[tukangId]! + value['rating'];
                ratingCount[tukangId] = ratingCount[tukangId]! + 1;
              } else {
                tempOverallRating[tukangId] = value['rating'].toDouble();
                ratingCount[tukangId] = 1;
              }
            }
          }
        });

        // Hitung rata-rata rating
        tempOverallRating.forEach((key, value) {
          tempOverallRating[key] = value / ratingCount[key]!;
        });

        setState(() {
          _orderCount = tempOrderCount;
          _overallRating = tempOverallRating;
        });
      }
    }).catchError((error) {
      print('Error fetching orders: $error'); // Logging untuk error
    });
  }

  void _fetchUsers() {
    _usersReference.orderByChild('role').equalTo('tukang').once().then((DatabaseEvent event) {
      List<Map<dynamic, dynamic>> tempList = [];
      final snapshot = event.snapshot;
      if (snapshot.value != null) {
        (snapshot.value as Map).forEach((key, value) {
          value['id'] = key; // Tambahkan ID pengguna ke data
          tempList.add(value);
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
    _usersReference.child(userId).update({'status': 'approved'}).then((_) {
      print('User $userId approved'); // Logging untuk debugging
      setState(() {
        // Refresh user list after approval
        _fetchUsers();
      });
    }).catchError((error) {
      print('Error approving user: $error'); // Logging untuk error
    });
  }

  void _rejectUser(String userId) {
    _usersReference.child(userId).update({'status': 'rejected'}).then((_) {
      print('User $userId rejected'); // Logging untuk debugging
      setState(() {
        // Refresh user list after rejection
        _fetchUsers();
      });
    }).catchError((error) {
      print('Error rejecting user: $error'); // Logging untuk error
    });
  }

  void _deactivateUser(String userId) {
    _usersReference.child(userId).update({
      'rolesKeunggulan': null,
      'statusAkun': 'nonaktif',
    }).then((_) {
      print('User $userId deactivated'); // Logging untuk debugging
      setState(() {
        // Refresh user list after deactivation
        _fetchUsers();
      });
    }).catchError((error) {
      print('Error deactivating user: $error'); // Logging untuk error
    });
  }

  void _showDeactivateConfirmationDialog(String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Nonaktifkan Akun'),
          content: const Text('Anda yakin ingin nonaktifkan akun ini?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                _deactivateUser(userId);
                Navigator.of(context).pop(); // Tutup dialog
              },
              child: const Text('Yakin'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(Map<dynamic, dynamic> user) {
    final TextEditingController nameController = TextEditingController(text: user['name']);
    final TextEditingController teamCountController = TextEditingController(text: user['teamCount']?.toString());
    final TextEditingController whatsappController = TextEditingController(text: user['whatsapp']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Akun'),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: teamCountController,
                  decoration: const InputDecoration(labelText: 'Team Count'),
                ),
                TextField(
                  controller: whatsappController,
                  decoration: const InputDecoration(labelText: 'WhatsApp'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                _updateUser(user['id'], nameController.text, teamCountController.text, whatsappController.text);
                Navigator.of(context).pop(); // Tutup dialog
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _updateUser(String userId, String name, String teamCount, String whatsapp) {
    _usersReference.child(userId).update({
      'name': name,
      'teamCount': int.tryParse(teamCount) ?? 0,
      'whatsapp': whatsapp,
    }).then((_) {
      print('User $userId updated'); // Logging untuk debugging
      setState(() {
        // Refresh user list after update
        _fetchUsers();
      });
    }).catchError((error) {
      print('Error updating user: $error'); // Logging untuk error
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

  void _navigateToDetailTukang(String userId) {
    final orderCount = _orderCount[userId] ?? 0;
    final overallRating = _overallRating[userId] ?? 0.0;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailDataTukang(userId: userId, orderCount: orderCount, overallRating: overallRating),
      ),
    );
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
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 20, // Persempit jarak antar kolom
                  columns: const [
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('PDF')),
                    DataColumn(label: Text('Approve')),
                    DataColumn(label: Text('Reject')),
                    DataColumn(label: Text('Nonaktifkan Akun')),
                    DataColumn(label: Text('Edit Akun')),
                    DataColumn(label: Text('Detail Tukang')),
                  ],
                  rows: _userList.map((user) {
                    final isApproved = user['status'] == 'approved';
                    final isRejected = user['status'] == 'rejected';
                    final isNonaktif = user['statusAkun'] == 'nonaktif';
                    return DataRow(cells: [
                      DataCell(Text(user['email'] ?? '')),
                      DataCell(Text(user['name'] ?? '')),
                      DataCell(
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
                      ),
                      DataCell(
                        ElevatedButton(
                          onPressed: isApproved || isRejected ? null : () => _approveUser(user['id']),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: isApproved ? Colors.green : Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(isApproved ? 'Approved' : 'Approve'),
                        ),
                      ),
                      DataCell(
                        ElevatedButton(
                          onPressed: isApproved || isRejected ? null : () => _rejectUser(user['id']),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: isRejected ? Colors.red : Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(isRejected ? 'Rejected' : 'Reject'),
                        ),
                      ),
                      DataCell(
                        ElevatedButton(
                          onPressed: isNonaktif ? null : () => _showDeactivateConfirmationDialog(user['id']),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: isNonaktif ? Colors.grey : Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Nonaktifkan Akun'),
                        ),
                      ),
                      DataCell(
                        ElevatedButton(
                          onPressed: isNonaktif ? null : () => _showEditDialog(user),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: isNonaktif ? Colors.grey : Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Edit Akun'),
                        ),
                      ),
                      DataCell(
                        ElevatedButton(
                          onPressed: () => _navigateToDetailTukang(user['id']),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Detail Tukang'),
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
      ),
    );
  }
}