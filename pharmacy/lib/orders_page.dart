import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pharmacy/order_details-page.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'order_provider.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<Map<String, dynamic>> orders = [];
  String? token;

  @override
  void initState() {
    super.initState();
    _initializeToken();
  }

  Future<void> _initializeToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedToken = prefs.getString('token');

    if (storedToken != null) {
      setState(() {
        token = storedToken;
      });
      fetchOrders(storedToken);
    } else {
      print("No token found! Redirecting to login...");
      // Handle missing token case (e.g., redirect to login)
    }
  }

  Future<void> fetchOrders(String token) async {
    final url = Uri.parse('http://localhost:4000/myorders');
    final response = await http.get(
      url,
      headers: {
        "Accept": 'application/json',
        'auth-token': token,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        orders = List<Map<String, dynamic>>.from(data['orders']);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load orders")),
      );
    }
  }

  Future<void> submitFeedback(String orderId, String feedback) async {
    if (token == null) return;

    final response = await http.post(
      Uri.parse('http://localhost:4000/test'),
      headers: {
        "Accept": 'application/json',
        'auth-token': token!,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "order_id": orderId,
        "feedback": feedback,
      }),
    );

    if (response.statusCode == 200) {
      Provider.of<OrderProvider>(context, listen: false)
          .updateOrderFeedback(orderId, feedback);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Feedback submitted successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to submit feedback")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (token == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()), // Wait for token
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Orders"),
        leading: IconButton(
          onPressed: () {
            Navigator.pushNamed(context, "/home");
          },
          icon: Icon(Icons.arrow_back),
        ),
      ),
      body: orders.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  margin: EdgeInsets.all(10),
                  child: ListTile(
                    title: Text("Order ID: ${order['order_id']}"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Status: ${order['status']}"),
                        Text("Amount: ₹${order['amount']}"),
                        Text("Payment ID: ${order['payment_id']}"),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              OrderDetailPage(order: order, token: token!),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
