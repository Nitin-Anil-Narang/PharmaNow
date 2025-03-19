import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'cart_provider.dart';
import 'product_provider.dart';
import 'home_upgrade.dart';

class CartPage extends StatefulWidget {
  final String token;

  CartPage({required this.token});

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late Razorpay _razorpay;
  final TextEditingController _phoneController = TextEditingController();
  String? _errorText;
  String? _phoneNumber; // Store phone number
  double? _amount; // Store amount

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _phoneController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_phoneNumber == null || _amount == null) {
      print("Missing phone number or amount data.");
      return;
    }

    print('Payment successful! Phone: $_phoneNumber, Amount: $_amount');

    final verifyResponse = await http.post(
      Uri.parse('http://localhost:4000/razorpay-webhook'),
      headers: {
        "Accept": 'application/json',
        'auth-token': widget.token,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "payment_id": response.paymentId,
        "order_id": response.orderId,
        "phone": _phoneNumber,
        "amount": _amount
      }),
    );

    final verifyData = jsonDecode(verifyResponse.body);
    print(verifyResponse.body);
    if (verifyResponse.statusCode == 200 &&
        verifyData["success"] == true &&
        verifyData["message"] == "Order placed successfully") {
      print("Payment verified and order placed successfully!");
      Provider.of<CartProvider>(context, listen: false).clearCart();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => ProductPages()),
        (route) => false,
      );
    } else {
      print("Payment verification failed.");
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print("Payment Error: ${response.message}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment failed! Please try again.")),
    );
  }

  void _openCheckout(double totalPrice) async {
    String phone = _phoneController.text.trim();

    if (phone.isEmpty ||
        phone.length != 10 ||
        !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      setState(() {
        _errorText = "Please enter a valid 10-digit phone number";
      });
      return;
    }

    setState(() {
      _errorText = null;
      _phoneNumber = phone; // Store phone number
      _amount = totalPrice; // Store amount
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:4000/create-order'),
        headers: {
          "Accept": 'application/json',
          'auth-token': widget.token,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"amount": totalPrice, "phone": phone}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String orderId = data['id'];

        var options = {
          'key': 'rzp_test_hqUNOWM9HyTUDD',
          'amount': (totalPrice * 100).toInt(),
          'name': 'Pharmacy',
          'description': 'Payment for Medicine',
          'order_id': orderId,
          'theme': {"color": '#2862ff'},
          'prefill': {'contact': phone},
          'method': {
            'upi': true,
            'qr': true,
            'wallet': false,
            'netbanking': true,
            'card': true,
          },
          'config': {
            'display': {
              'blocks': {
                'upi': {
                  'name': 'UPI',
                  'instruments': [
                    {
                      'method': 'upi',
                      'flows': ['collect', 'intent']
                    }
                  ]
                }
              },
              'sequence': ['block.upi']
            }
          }
        };

        _razorpay.open(options);
      } else {
        print("Failed to create order: ${response.body}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Cart", style: TextStyle(fontSize: 30)),
        backgroundColor: const Color.fromRGBO(41, 98, 255, 1),
      ),
      body: FutureBuilder(
        future: cartProvider.fetchCart(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          double totalPrice = 0.0;
          cartProvider.cartItems.forEach((itemId, quantity) {
            final product = productProvider.products.firstWhere(
              (product) => product.id == itemId,
              orElse: () => Product(
                id: itemId.toString(),
                name: 'Unknown Product',
                image: '',
                price: 0.0,
                description: '',
                category: '',
                ingredients: '',
              ),
            );

            totalPrice += product.price * quantity;
          });

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartProvider.cartItems.length,
                  itemBuilder: (ctx, index) {
                    final itemId = cartProvider.cartItems.keys.toList()[index];
                    final quantity = cartProvider.cartItems[itemId]!;

                    final product = productProvider.products.firstWhere(
                      (product) => product.id == itemId,
                      orElse: () => Product(
                        id: itemId,
                        name: 'Unknown Product',
                        image: '',
                        price: 0.0,
                        description: '',
                        category: '',
                        ingredients: '',
                      ),
                    );

                    return ListTile(
                      leading: Image.network(
                        product.image,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                      title: Text(product.name),
                      subtitle:
                          Text('Quantity: $quantity\nPrice: ₹${product.price}'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          cartProvider.removeItemFromCart(itemId.toString());
                        },
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Enter Phone Number",
                        errorText: _errorText,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    Center(
                      child: Text(
                        'Total: ₹${totalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(height: 10),
                    Center(
                      child: ElevatedButton(
                        onPressed: () => _openCheckout(totalPrice),
                        child: Text('Checkout'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
