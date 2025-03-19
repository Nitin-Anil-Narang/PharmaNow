import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'product_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrderDetailPage extends StatefulWidget {
  final Map<String, dynamic> order;
  final String token;

  const OrderDetailPage({Key? key, required this.order, required this.token})
      : super(key: key);

  @override
  _OrderDetailPageState createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Map<String, List<Map<String, dynamic>>> productReviews = {};

  @override
  void initState() {
    super.initState();
    fetchAllReviews();
  }

  Future<void> fetchAllReviews() async {
    for (var itemId in widget.order['items'].keys) {
      await fetchReviews(itemId);
    }
  }

  Future<void> fetchReviews(String productId) async {
    final response = await http.get(
      Uri.parse('http://localhost:4000/reviews/$productId'),
      headers: {
        "Accept": 'application/json',
        'auth-token': widget.token,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        productReviews[productId] =
            List<Map<String, dynamic>>.from(data['reviews']);
      });
      print(productReviews);
    } else {
      // print("Failed to fetch reviews for product ID: $productId");
    }
  }

  Future<void> submitReview(
      String productId, int rating, String comment) async {
    print("order_review ${widget.order['order_id']}");
    final response = await http.post(
      Uri.parse('http://localhost:4000/submit-review'),
      headers: {
        "Accept": 'application/json',
        'auth-token': widget.token,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        // "userId": "USER_ID_PLACEHOLDER", // Replace with actual user ID
        "orderId": widget.order['_id'],
        "productId": int.parse(productId),
        "rating": rating,
        "comment": comment,
      }),
    );

    if (response.statusCode == 200) {
      fetchReviews(productId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Review submitted successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to submit review")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text("Order Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Info
            Text("Order ID: ${widget.order['order_id']}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Status: ${widget.order['status']}"),
            Text("Amount: ₹${widget.order['amount']}"),
            Text("Payment ID: ${widget.order['payment_id']}"),
            Text("Date: ${widget.order['date']}"),
            SizedBox(height: 10),
            Text("Items:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),

            // Order Items List
            Expanded(
              child: ListView(
                children: (widget.order['items'] as Map<String, dynamic>)
                    .entries
                    .where((entry) => entry.value > 0) // Ignore empty items
                    .map<Widget>((entry) {
                  int itemId = int.parse(entry.key);
                  int quantity = entry.value;

                  return Consumer<ProductProvider>(
                    builder: (context, productProvider, child) {
                      final product =
                          productProvider.getProductById(itemId.toString());
                      return product != null
                          ? Card(
                              margin: EdgeInsets.symmetric(vertical: 5),
                              child: ListTile(
                                leading: product.image.isNotEmpty
                                    ? Image.network(product.image,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover)
                                    : Icon(Icons.image, size: 50),
                                title: Text(product.name),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Quantity: $quantity"),
                                    Text("Price: ₹${product.price}"),
                                    if (productReviews.containsKey(product.id))
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: productReviews[product.id]!
                                            .where((review) =>
                                                review['orderId'] ==
                                                widget.order[
                                                    '_id']) // Filter reviews by order ID
                                            .map((review) {
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4.0),
                                            child: Text(
                                              "⭐ ${review['rating']} - ${review['comment']}",
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  fontStyle: FontStyle.italic),
                                            ),
                                          );
                                        }).toList(),
                                      )
                                    else
                                      Text("No reviews yet",
                                          style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        int selectedRating = 5;
                                        TextEditingController
                                            commentController =
                                            TextEditingController();
                                        return StatefulBuilder(
                                          builder: (context, setDialogState) {
                                            return AlertDialog(
                                              title: Text("Submit Review"),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  DropdownButton<int>(
                                                    value: selectedRating,
                                                    items: [1, 2, 3, 4, 5]
                                                        .map((int value) {
                                                      return DropdownMenuItem<
                                                          int>(
                                                        value: value,
                                                        child: Text(
                                                            "$value Stars"),
                                                      );
                                                    }).toList(),
                                                    onChanged: (value) {
                                                      setDialogState(() {
                                                        selectedRating = value!;
                                                      });
                                                    },
                                                  ),
                                                  TextField(
                                                    controller:
                                                        commentController,
                                                    decoration: InputDecoration(
                                                        hintText:
                                                            "Enter your review"),
                                                  ),
                                                ],
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    submitReview(
                                                        product.id,
                                                        selectedRating,
                                                        commentController.text);
                                                    Navigator.pop(context);
                                                  },
                                                  child: Text("Submit"),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                  child: Text("Review"),
                                ),
                              ),
                            )
                          : ListTile(
                              title: Text("Loading product..."),
                              subtitle: Text("Item ID: $itemId"),
                            );
                    },
                  );
                }).toList(),
              ),
            ),

            SizedBox(height: 15),
          ],
        ),
      ),
    );
  }
}
