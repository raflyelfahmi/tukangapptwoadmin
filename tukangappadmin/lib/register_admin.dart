import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class RegisterAdminView extends StatefulWidget {
  @override
  _RegisterAdminViewState createState() => _RegisterAdminViewState();
}

class _RegisterAdminViewState extends State<RegisterAdminView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _registerAdmin() async {
    if (_formKey.currentState!.validate()) {
      try {
        final UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        final User? user = userCredential.user;
        if (user != null) {
          // Simpan data admin ke Realtime Database
          await FirebaseDatabase.instance.ref().child('users').child(user.uid).set({
            'email': _emailController.text,
            'role': 'admin',
          }).then((_) {
            print('Admin data saved successfully');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Admin registered successfully')),
            );
          }).catchError((error) {
            print('Failed to save admin data: $error');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to save admin data: $error')),
            );
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Admin registration failed')),
          );
        }
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Registration failed')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred')),
        );
      }
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register Admin'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: _inputDecoration('Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                decoration: _inputDecoration('Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _registerAdmin,
                child: Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}