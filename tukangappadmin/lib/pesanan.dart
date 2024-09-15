import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'detildatapesanan.dart'; // Import halaman detail pesanan
import 'navbar.dart';
import 'rab.dart';

class PesananPage extends StatefulWidget {
  @override
  _PesananPageState createState() => _PesananPageState();
}

class _PesananPageState extends State<PesananPage> {
  final DatabaseReference _ordersReference =
      FirebaseDatabase.instance.ref().child('orders');
  final DatabaseReference _usersReference =
      FirebaseDatabase.instance.ref().child('users');
  List<Map<dynamic, dynamic>> _orderList = [];
  Map<String, String> _userNames = {};

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  void _fetchOrders() {
    _ordersReference.onValue.listen((event) async {
      List<Map<dynamic, dynamic>> tempList = [];
      final snapshot = event.snapshot;
      if (snapshot.value != null) {
        Map<dynamic, dynamic> orders = snapshot.value as Map<dynamic, dynamic>;
        for (var key in orders.keys) {
          var value = orders[key];
          value['id'] = key;
          value['pemesanName'] = await _getUserName(value['pemesanId']);
          value['tukangName'] = await _getUserName(value['tukangId']);
          tempList.add(value);
        }
      }
      setState(() {
        _orderList = tempList;
      });
      print('Fetched orders: $_orderList');
    }, onError: (error) {
      print('Error fetching orders: $error');
    });
  }

  Future<String> _getUserName(String userId) async {
    if (_userNames.containsKey(userId)) {
      return _userNames[userId]!;
    }
    final snapshot = await _usersReference.child(userId).once();
    if (snapshot.snapshot.value != null) {
      final name = (snapshot.snapshot.value as Map)['name'] ?? '-';
      _userNames[userId] = name;
      return name;
    }
    return '-';
  }

  void _updateOrderStatus(String orderId, String status) {
    _ordersReference.child(orderId).update({'status': status}).then((_) {
      print('Order $orderId updated to $status');
      setState(() {
        _fetchOrders();
      });
    }).catchError((error) {
      print('Error updating order: $error');
    });
  }

  void _navigateToRabPage(Map<dynamic, dynamic> order) async {
    final pemesanName = await _getUserName(order['pemesanId']);
    final tukangName = await _getUserName(order['tukangId']);
    order['pemesanName'] = pemesanName;
    order['tukangName'] = tukangName;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RabPage(order: order)),
    );
  }

  Future<void> _showTukangList(String orderId) async {
    final orderSnapshot = await _ordersReference.child(orderId).get();
    final orderData = orderSnapshot.value as Map<dynamic, dynamic>;
    final int requiredTeamCount = int.parse(orderData['jumlahTukang']);

    final snapshot =
        await _usersReference.orderByChild('role').equalTo('tukang').once();
    final tukangList = (snapshot.snapshot.value as Map<dynamic, dynamic>)
        .values
        .where((tukang) => int.parse(tukang['teamCount']?.toString() ?? '0') >= requiredTeamCount)
        .toList();

    if (tukangList.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Pilih Tukang'),
            content: Text('Tidak ada tukang dengan jumlah yang sesuai'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Pilih Tukang'),
            content: Container(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: tukangList.length,
                itemBuilder: (BuildContext context, int index) {
                  final tukang = tukangList[index];
                  return ListTile(
                    title: Text(tukang['name']),
                    subtitle: Text('Team Count: ${tukang['teamCount'] ?? '-'}'),
                    onTap: () {
                      _updateTukang(orderId, tukang['id']);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          );
        },
      );
    }
  }

  void _updateTukang(String orderId, String tukangId) {
    _ordersReference.child(orderId).update({
      'tukangId': tukangId,
      'konfirmasiTukang': 'pending',
      'alasanPenolakan': null,
    }).then((_) {
      print('Order $orderId tukang updated to $tukangId');
      setState(() {
        _fetchOrders();
      });
    }).catchError((error) {
      print('Error updating tukang: $error');
    });
  }

  Future<void> _uploadFileRincian(String orderId) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      PlatformFile file = result.files.first;
      String fileName = file.name;
      String filePath = 'rincian_files/$orderId/$fileName';

      try {
        // Upload file to Firebase Storage
        if (file.bytes != null) {
          await FirebaseStorage.instance.ref(filePath).putData(file.bytes!);
        } else if (file.path != null) {
          await FirebaseStorage.instance
              .ref(filePath)
              .putFile(File(file.path!));
        } else {
          throw Exception('File path and bytes are both null');
        }

        // Get the download URL
        String downloadURL =
            await FirebaseStorage.instance.ref(filePath).getDownloadURL();

        // Save the download URL to Realtime Database
        await _ordersReference
            .child(orderId)
            .child('rincianFiles')
            .push()
            .set(downloadURL);

        print('File uploaded and URL saved to database');
      } catch (e) {
        print('Error uploading file: $e');
      }
    } else {
      // User canceled the picker
      print('File picker canceled');
    }
  }

  void _navigateToDetailPesanan(Map<dynamic, dynamic> order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailDataPesanan(order: order),
      ),
    );
  }

  void _showTransferTukangDialog(String orderId) {
    final TextEditingController nominalController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Transfer Tukang'),
          content: TextField(
            controller: nominalController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Masukkan Nominal'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
              },
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                _transferTukang(orderId, nominalController.text);
                Navigator.of(context).pop(); // Tutup dialog
              },
              child: Text('Kirim'),
            ),
          ],
        );
      },
    );
  }

  void _transferTukang(String orderId, String nominal) {
    _ordersReference.child(orderId).update({
      'transferTukang': nominal,
      'tukangPayment': 'lunas',
    }).then((_) {
      print('Order $orderId updated with transferTukang: $nominal and tukangPayment: lunas');
      setState(() {
        _fetchOrders();
      });
    }).catchError((error) {
      print('Error updating order: $error');
    });
  }

  Widget _buildOrderTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20, // Persempit jarak antar kolom
        columns: const [
          DataColumn(label: Text('Pemesan')),
          DataColumn(label: Text('Tukang')),
          DataColumn(label: Text('Alamat')),
          DataColumn(label: Text('Tanggal')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Pekerjaan')),
          DataColumn(label: Text('Total Kebutuhan')),
          DataColumn(label: Text('Status Payment')),
          DataColumn(label: Text('Status Pekerjaan')),
          DataColumn(label: Text('Bukti Images')),
          DataColumn(label: Text('File Rincian')),
          DataColumn(label: Text('Aksi')),
        ],
        rows: _orderList.map((order) {
          final isApproved = order['status'] == 'approved';
          final isPending = order['status'] == 'pending';
          final isSelesai = order['statusPekerjaan'] == 'selesai';
          final isOrderSelesai = order['status'] == 'selesai';
          final isMenungguDitolak = order['status'] == 'menunggu' ||
              order['konfirmasiTukang'] == 'ditolak';
          final isTukangPaymentLunas = order['tukangPayment'] == 'lunas';
          return DataRow(cells: [
            DataCell(Text(order['pemesanName'] ?? '-')),
            DataCell(Text(order['tukangName'] ?? '-')),
            DataCell(Text(order['alamat'] ?? '-')),
            DataCell(Text(order['tanggal'] ?? '-')),
            DataCell(Text(order['status'] ?? '-')),
            DataCell(Text(order['pekerjaan'] ?? '-')),
            DataCell(Text(order['totalKebutuhan']?.toString() ?? '-')),
            DataCell(Text(order['statusPayment'] ?? '-')),
            DataCell(Text(order['statusPekerjaan'] ?? '-')),
            DataCell(
              InkWell(
                onTap: () async {
                  final urls =
                      (order['buktiImages'] as Map<dynamic, dynamic>?)?.values;
                  if (urls != null) {
                    for (var url in urls) {
                      if (await canLaunch(url)) {
                        await launch(url);
                      } else {
                        print('Could not launch $url');
                      }
                    }
                  }
                },
                child: Text('Lihat Progress',
                    style: TextStyle(color: Colors.blue)),
              ),
            ),
            DataCell(
              InkWell(
                onTap: () async {
                  final urls =
                      (order['rincianFiles'] as Map<dynamic, dynamic>?)?.values;
                  if (urls != null) {
                    for (var url in urls) {
                      if (await canLaunch(url)) {
                        await launch(url);
                      } else {
                        print('Could not launch $url');
                      }
                    }
                  }
                },
                child:
                    Text('Lihat Rincian', style: TextStyle(color: Colors.blue)),
              ),
            ),
            DataCell(
              Row(
                children: [
                  ElevatedButton(
                    onPressed: isPending
                        ? () => _updateOrderStatus(order['id'], 'approved')
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPending ? Colors.blue : Colors.grey,
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(isPending ? 'Approve' : 'Approved',
                        style: TextStyle(color: Colors.white)),
                  ),
                  SizedBox(width: 8),
                  if (isApproved)
                    ElevatedButton(
                      onPressed: () => _navigateToRabPage(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child:
                          Text('Proses', style: TextStyle(color: Colors.white)),
                    ),
                  SizedBox(width: 8),
                  if (isSelesai && !isOrderSelesai)
                    ElevatedButton(
                      onPressed: () =>
                          _updateOrderStatus(order['id'], 'selesai'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text('Selesai',
                          style: TextStyle(color: Colors.white)),
                    ),
                  SizedBox(width: 8),
                  if (isMenungguDitolak)
                    ElevatedButton(
                      onPressed: () => _showTukangList(order['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text('Ubah Tukang',
                          style: TextStyle(color: Colors.white)),
                    ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _uploadFileRincian(order['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text('Upload File Rincian',
                        style: TextStyle(color: Colors.white)),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _navigateToDetailPesanan(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text('Detail Pesanan',
                        style: TextStyle(color: Colors.white)),
                  ),
                  SizedBox(width: 8),
                  if (isOrderSelesai && !isTukangPaymentLunas)
                    ElevatedButton(
                      onPressed: () => _showTransferTukangDialog(order['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text('Transfer Tukang',
                          style: TextStyle(color: Colors.white)),
                    ),
                ],
              ),
            ),
          ]);
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('Building UI with _orderList: $_orderList');
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Pesanan'),
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
      body: _orderList.isEmpty
          ? Center(
              child: Text(
                'Belum ada pesanan yang perlu dikelola.',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            )
          : _buildOrderTable(),
    );
  }
}
