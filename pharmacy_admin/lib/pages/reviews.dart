import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

class AdminReviewsPage extends StatefulWidget {
  @override
  _AdminReviewsPageState createState() => _AdminReviewsPageState();
}

class _AdminReviewsPageState extends State<AdminReviewsPage> {
  List<dynamic> reviews = [];
  List<dynamic> allProducts = [];
  bool isLoading = true;
  bool hasError = false;
  int? selectedRating;

  @override
  void initState() {
    super.initState();
    fetchReviews();
    fetchProducts();
  }

  Future<void> fetchReviews() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:4000/reviews'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          reviews = data['reviews'];
        });
      } else {
        throw Exception('Failed to load reviews');
      }
    } catch (error) {
      print('Error fetching reviews: $error');
    }
  }

  Future<void> fetchProducts() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:4000/allproduct'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (Platform.isAndroid) {
          for (var product in data) {
            if (product['image'] != null && product['image'].contains('localhost')) {
              product['image'] = product['image'].replaceAll('localhost', '10.0.2.2');
            }
          }
        }
        setState(() {
          allProducts = data;
          isLoading = false;
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

  Map<String, dynamic>? getProductDetails(int productId) {
    return allProducts.firstWhere((product) => product['id'] == productId, orElse: () => null);
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> filteredReviews = selectedRating == null
        ? reviews
        : reviews.where((review) => review['rating'] == selectedRating).toList();

    return Scaffold(
      appBar: AppBar(title: Text("Admin - Reviews")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<int>(
              hint: Text("Filter by Rating"),
              value: selectedRating,
              items: [
                for (int i = 1; i <= 5; i++)
                  DropdownMenuItem(value: i, child: Text("$i Stars"))
              ],
              onChanged: (value) {
                setState(() {
                  selectedRating = value;
                });
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: filteredReviews.length,
                    itemBuilder: (context, index) {
                      final review = filteredReviews[index];
                      final product = getProductDetails(review['productId']);
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          leading: product != null && product['image'] != null
                              ? Image.network(product['image'], width: 50, height: 50, fit: BoxFit.cover)
                              : Icon(Icons.image_not_supported),
                          title: Text("${review['userId']['name']} (${review['userId']['email']})"),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Order ID: ${review['orderId']['_id']}"),
                              product != null
                                  ? Text("Product: ${product['name']}", style: TextStyle(fontWeight: FontWeight.bold))
                                  : Text("Product ID: ${review['productId']}", style: TextStyle(fontWeight: FontWeight.bold)),
                              Text("Rating: ${review['rating']} ⭐"),
                              Text("Comment: ${review['comment']}"),
                              Text("Date: ${DateTime.parse(review['date']).toLocal()}"),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
