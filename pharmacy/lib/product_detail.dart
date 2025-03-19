import 'package:flutter/material.dart';
import 'package:pharmacy/cart_page.dart';
import 'package:pharmacy/cart_provider.dart';
import 'package:provider/provider.dart';
import 'product_provider.dart'; // Assuming the provider is in this file

class ProductDetailPage extends StatelessWidget {
  final Product product;
  final String token;

  ProductDetailPage({required this.product, required this.token});

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => CartPage(token: token),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: productProvider.fetchProducts(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: <Widget>[
                    Center(
                      child: Container(
                        color: Colors.transparent,
                        child: Image.network(
                          product.image,
                          height: 250,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      product.name,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '₨${product.price}',
                      style: TextStyle(fontSize: 30, color: Colors.green),
                    ),
                    SizedBox(height: 16),
                    Text(
                      product.description,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Category - ${product.category}",
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    // **Ingredients Section**
                    Text(
                      "Ingredients:",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      product.ingredients.isNotEmpty ? product.ingredients : "No ingredients available.",
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    Provider.of<CartProvider>(context, listen: false)
                        .addItemToCart(product.id, );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.name} added to cart!'),
                      ),
                    );
                  },
                  child: Text('Add to Cart'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                    backgroundColor: Colors.blue,
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
