import 'dart:convert';
import 'dart:io';
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
      if (Platform.isAndroid) {
        // Replace 'localhost', '127.0.0.1' or '192.168.x.x' with '10.0.2.2' for Android devices
        for (var product in data) {
          if (product['image'] != null &&
              product['image'].contains('localhost')) {
            product['image'] =
                product['image'].replaceAll('localhost', '10.0.2.2');
          }
          if (product['image'] != null &&
              product['image'].contains('127.0.0.1')) {
            product['image'] =
                product['image'].replaceAll('127.0.0.1', '10.0.2.2');
          }
          if (product['image'] != null &&
              product['image'].contains('192.168')) {
            product['image'] = product['image']
                .replaceAll(RegExp(r'192\.168\.\d+\.\d+'), '10.0.2.2');
          }
        }
      }

      print(data);
      _products = data.map((item) => Product.fromJson(item)).toList();
      // print("provider");
      print(_products);
      _lastFetchTime = DateTime.now();
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
  final String description;
  final String ingredients;
  final String category;

  Product({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.description,
    required this.ingredients,
    required this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      price: (json['new_price'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      ingredients: json['ingredients'] ?? '',
    );
  }
}
