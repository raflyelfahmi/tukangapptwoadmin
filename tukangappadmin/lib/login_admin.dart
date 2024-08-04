import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginAdminView extends StatefulWidget {
  @override
  _LoginAdminViewState createState() => _LoginAdminViewState();
}

class _LoginAdminViewState extends State<LoginAdminView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _loginAdmin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        final User? user = userCredential.user;
        if (user != null) {
          // Verifikasi apakah user memiliki role admin
          final DatabaseReference userRef = FirebaseDatabase.instance.ref().child('users').child(user.uid);
          final DataSnapshot snapshot = await userRef.get();
          if (snapshot.exists && snapshot.child('role').value == 'admin') {
            Navigator.pushReplacementNamed(context, '/adminDashboard');
          } else {
            _showErrorSnackBar('Anda tidak memiliki hak akses admin');
            await FirebaseAuth.instance.signOut();
          }
        } else {
          _showErrorSnackBar('Login gagal');
        }
      } on FirebaseAuthException catch (e) {
        _showErrorSnackBar(e.message ?? 'Login gagal');
      } catch (e) {
        _showErrorSnackBar('Terjadi kesalahan yang tidak terduga');
      }
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ));
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blue),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: Colors.blue),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: Colors.blue, width: 2.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 50),
                  Icon(Icons.admin_panel_settings, size: 100, color: Colors.blue),
                  SizedBox(height: 30),
                  Text(
                    'Admin Login',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),
                  TextFormField(
                    controller: _emailController,
                    decoration: _inputDecoration('Email', Icons.email),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Masukkan email Anda';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    decoration: _inputDecoration('Password', Icons.lock),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Masukkan password Anda';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _loginAdmin,
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Login', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () => Navigator.pushNamed(context, '/registerAdmin'),
                    child: Text('Daftar Admin', style: TextStyle(fontSize: 18)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red, side: BorderSide(color: Colors.red),
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}