import 'package:flutter/material.dart';

class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> product;

  ProductDetailScreen({required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product['name'] ?? 'Product Details')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            product['image'] != null && product['image'].isNotEmpty
                ? Image.network(product['image'], height: 200, fit: BoxFit.cover)
                : Icon(Icons.image, size: 100),
            SizedBox(height: 20),
            Text(
              product['name'] ?? 'No Name',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Description: ${product['description'] ?? 'No description'}',
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text('Ingredients: ${product['ingredients'] ?? 'No description'}',
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text('New Price: ₨ ${product['new_price']?.toStringAsFixed(2) ?? '0.00'}',
                style: TextStyle(fontSize: 18, color: Colors.green)),
            SizedBox(height: 10),
            Text('Original Price: ₨ ${product['original_price']?.toStringAsFixed(2) ?? '0.00'}',
                style: TextStyle(fontSize: 18, color: Colors.red)),
            SizedBox(height: 10),
            Text('Stock: ${product['stock'] ?? 0}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
