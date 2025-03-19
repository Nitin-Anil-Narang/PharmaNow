import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CartProvider with ChangeNotifier {
  Map<String, dynamic> _cartItems = {};
  double _totalPrice = 0.0;

  Map<String, dynamic> get cartItems => _cartItems;
  double get totalPrice => _totalPrice;

  // Fetch token from local storage
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // API endpoint to get the user's cart data
  Future<void> fetchCart() async {
    String? token = await _getToken();
    if (token == null) return;

    final url = Uri.parse('http://localhost:4000/getcart');
    print("getcart ${token}");
    try {
      final response = await http.post(
        url,
        headers: {
          "Accept": 'application/json',
          'auth-token': token,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);
        Map<String, dynamic> filteredResponse = Map.from(decodedJson)
          ..removeWhere((key, value) => value == 0 || value == null);

        if (!mapEquals(_cartItems, filteredResponse)) {
          _cartItems = filteredResponse;
          _calculateTotalPrice();
          notifyListeners();
        }
      } else {
        print("Error fetching cart: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception in fetchCart: $e");
    }
  }

  // Adding item to the cart
  Future<void> addItemToCart(String itemId) async {
    String? token = await _getToken();
    if (token == null) return;

    final url = Uri.parse('http://localhost:4000/addtocart');
    try {
      await http.post(
        url,
        headers: {
          "Accept": 'application/json',
          'auth-token': token,
          'Content-Type': 'application/json',
        },
        body: json.encode({'itemId': itemId}),
      );

      _cartItems[itemId] = (_cartItems[itemId] ?? 0) + 1;
      _calculateTotalPrice();
      notifyListeners();
    } catch (e) {
      print("Exception in addItemToCart: $e");
    }
  }

  // Removing item from the cart
  Future<void> removeItemFromCart(String itemId) async {
    String? token = await _getToken();
    if (token == null) return;

    final url = Uri.parse('http://localhost:4000/removefromcart');
    try {
      await http.post(
        url,
        headers: {
          "Accept": 'application/json',
          'auth-token': token,
          'Content-Type': 'application/json',
        },
        body: json.encode({'itemId': itemId}),
      );

      if (_cartItems.containsKey(itemId) && _cartItems[itemId]! > 0) {
        _cartItems[itemId] = _cartItems[itemId]! - 1;
        if (_cartItems[itemId] == 0) {
          _cartItems.remove(itemId);
        }
      }

      _calculateTotalPrice();
      notifyListeners();
    } catch (e) {
      print("Exception in removeItemFromCart: $e");
    }
  }

  // Clear Cart
  Future<void> clearCart() async {
    _cartItems.clear();
    _totalPrice = 0.0;
    notifyListeners();
  }

  // Calculate total price from cart
  void _calculateTotalPrice() {
    _totalPrice = 0.0;
    _cartItems.forEach((itemId, quantity) {
      _totalPrice += quantity * 100; // Assuming each item costs 100 for now
    });
  }
}
