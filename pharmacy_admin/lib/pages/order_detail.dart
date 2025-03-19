import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrderDetailPage extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailPage({super.key, required this.order});

  @override
  _OrderDetailPageState createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  List<dynamic> allProducts = []; // Now using a dynamic list
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      final response =
          await http.get(Uri.parse('http://localhost:4000/allproduct'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (Platform.isAndroid) {
          for (var product in data) {
            if (product['image'] != null &&
                product['image'].contains('localhost')) {
              product['image'] =
                  product['image'].replaceAll('localhost', '10.0.2.2');
            }
          }
        }
        setState(() {
          allProducts = data; // Storing data in a dynamic list
          isLoading = false;
          print(allProducts);
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Order Details"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : hasError
              ? Center(
                  child: Text("Failed to load products. Please try again.",
                      style: TextStyle(color: Colors.red)))
              : Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailItem("Order ID", widget.order['order_id']),
                      _buildDetailItem("Status", widget.order['status']),
                      _buildDetailItem("Amount", "₹${widget.order['amount']}"),
                      _buildDetailItem(
                          "Payment ID", widget.order['payment_id']),
                      SizedBox(height: 20),
                      Text(
                        "Products Ordered:",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: ListView(
                          children:
                              (widget.order['items'] as Map<String, dynamic>)
                                  .entries
                                  .where((entry) =>
                                      entry.value > 0) // Ignore empty items
                                  .map<Widget>((entry) {
                            int itemId = int.parse(entry.key);
                            int quantity = entry.value;
                            print(itemId);

                            // Find the matching product from allProducts
                            final product = allProducts.firstWhere(
                              (prod) => prod['id'] == itemId,
                              orElse: () =>
                                  null, // Return null if product is not found
                            );



                            return product != null
                                ? Card(
                                    margin: EdgeInsets.symmetric(vertical: 5),
                                    child: ListTile(
                                      leading: product['image'] != null &&
                                              product['image'].isNotEmpty
                                          ? Image.network(product['image'],
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover)
                                          : Icon(Icons.image, size: 50),
                                      title: Text(
                                          product['name'] ?? "Unknown Product"),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text("Quantity: $quantity"),
                                          Text("Price: ₹${product['new_price']}"),
                                        ],
                                      ),
                                    ),
                                  )
                                : SizedBox(); // Skip if product is not found
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Text(
        "$label: $value",
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}
