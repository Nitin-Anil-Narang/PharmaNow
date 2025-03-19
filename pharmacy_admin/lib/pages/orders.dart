import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:admin/pages/order_detail.dart';
import 'dart:convert';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      final url = Uri.parse('http://localhost:4000/allorders');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('orders')) {
          setState(() {
            orders = List<Map<String, dynamic>>.from(data['orders']);
            isLoading = false;
          });
        } else {
          setState(() {
            hasError = true;
            isLoading = false;
          });
        }
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
        title: Text("Orders"),
        leading: IconButton(
          onPressed: () {
            Navigator.pushNamed(context, "/home");
          },
          icon: Icon(Icons.arrow_back),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : hasError
              ? Center(
                  child: Text(
                    "Failed to load orders. Please try again.",
                    style: TextStyle(color: Colors.red),
                  ),
                )
              : orders.isEmpty
                  ? Center(
                      child: Text(
                        "No orders found.",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    )
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
                                      OrderDetailPage(order: order),
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
