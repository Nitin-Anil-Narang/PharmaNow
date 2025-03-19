import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Medicine Shop'),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              // Handle shopping cart button press here
              print('Shopping cart pressed');
            },
          ),
        ],
        backgroundColor:
            Colors.green, // Change the app bar color to your choice
      ),
      body: Stack(
        children: [
          // Background image of medicine
          Positioned.fill(
            child: Image.asset(
              'assets/medicine_background.jpg', // Add your image path here
              fit: BoxFit.cover,
            ),
          ),
          // Add other widgets here for your home page content
          Center(
            child: Text(
              'Welcome to Medicine Shop',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
