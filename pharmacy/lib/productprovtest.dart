import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  DateTime? _lastFetchTime; // Track the last fetch time

  List<Product> get products => _products;

  // Fetch products from the backend
  Future<void> fetchProducts() async {
    final currentTime = DateTime.now();

    // Check if data was fetched less than 2 minutes ago
    if (_lastFetchTime != null &&
        currentTime.difference(_lastFetchTime!).inMinutes < 2) {
      print("Data fetched too recently, skipping fetch.");
      return; // Skip fetch if data was fetched within the last 2 minutes
    }

    final url = Uri.parse('http://localhost:4000/allproduct');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      _products = data.map((item) => Product.fromJson(item)).toList();
      _lastFetchTime = DateTime.now(); // Update the timestamp of the last fetch
      notifyListeners();
    } else {
      throw Exception('Failed to load products');
    }
  }

  // Get a product by its ID
  Product? getProductById(String id) {
    return _products
        .map((product) => (product))
        .firstWhere((product) => product.id == id);
  }
}

class Product {
  final String id;
  final String name;
  final String image;
  final double price;

  Product({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['name'],
      image: json['image'],
      price: json['new_price'].toDouble(),
    );
  }
}
