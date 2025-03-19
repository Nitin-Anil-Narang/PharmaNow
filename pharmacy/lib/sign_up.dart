import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false; // Track password visibility
  String _errorMessage = '';
  bool _isLoading = false;

  Future<void> _signup() async {
    final name = _nameController.text;
    final email = _emailController.text;
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = "Please fill in all fields.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final url = Uri.parse('http://localhost:4000/signup');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': name,
        'email': email,
        'password': password,
      }),
    );

    final responseData = json.decode(response.body);

    if (response.statusCode == 200 && responseData['sucess'] == true) {
      // Show success message or navigate to login
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      setState(() {
        _errorMessage = responseData['errors'] ?? 'Signup failed';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent.shade700,
      appBar:
          AppBar(title: Text('Sign Up'), backgroundColor: Colors.grey.shade400),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Center(
              child: SizedBox(
                height: 300,
                child: Image.network(
                  'https://cdn-icons-png.freepik.com/512/169/169837.png',
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Username',
                labelStyle: TextStyle(
                    color: Colors.black87, fontWeight: FontWeight.bold),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(
                    color: Colors.black87, fontWeight: FontWeight.bold),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible, // Toggle password visibility
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(
                    color: Colors.black87, fontWeight: FontWeight.bold),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.black87,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible =
                          !_isPasswordVisible; // Toggle visibility
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _signup,
                    style: ElevatedButton.styleFrom(minimumSize: Size(70, 70)),
                    child: Text('Sign Up', style: TextStyle(fontSize: 20)),
                  ),
            SizedBox(height: 20),
            _errorMessage.isNotEmpty
                ? Text(_errorMessage, style: TextStyle(color: Colors.red))
                : Container(),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              child: Text('Already have an account? Login',
                  style: TextStyle(fontSize: 17, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
