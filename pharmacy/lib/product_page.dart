import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pharmacy/cart_page.dart';
import 'package:pharmacy/product_detail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'product_provider.dart';
import 'cart_provider.dart';

class ProductPage extends StatefulWidget {
  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  String? token;
  String selectedCategory = 'All';
  late Future<void> _fetchProductsFuture;

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
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      _fetchProductsFuture = productProvider.fetchProducts();
    } else {
      // Handle case where token is missing (e.g., navigate to login)
      print("No token found! Redirecting to login...");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (token == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()), // Show loading until token is fetched
      );
    }

    final productProvider = Provider.of<ProductProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Products"),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => CartPage(token: token!)),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: _fetchProductsFuture,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          List filteredProducts = selectedCategory == 'All'
              ? productProvider.products
              : productProvider.products.where((product) => product.category == selectedCategory).toList();

          return Column(
            children: [
              // Category buttons
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Medicine', 'Tools', 'Vitamins'].map((category) {
                      return CategoryButton(
                        label: category,
                        isSelected: selectedCategory == category,
                        onPressed: () {
                          setState(() => selectedCategory = category);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Product grid
              Expanded(
                child: GridView.builder(
                  itemCount: filteredProducts.length,
                  padding: EdgeInsets.all(10.0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10.0,
                    mainAxisSpacing: 10.0,
                    childAspectRatio: 0.7,
                    mainAxisExtent: 350,
                  ),
                  itemBuilder: (ctx, index) {
                    final product = filteredProducts[index];
                    String desc = product.description.length > 30
                        ? product.description.substring(0, 30) + '...'
                        : product.description;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            transitionDuration: Duration(milliseconds: 500),
                            opaque: false,
                            pageBuilder: (context, animation, secondaryAnimation) =>
                                ProductDetailPage(product: product, token: token!),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return Stack(
                                children: [
                                  BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                    child: Container(color: Colors.black.withOpacity(0.1)),
                                  ),
                                  FadeTransition(opacity: animation, child: child),
                                ],
                              );
                            },
                          ),
                        );
                      },
                      child: GridTile(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade500, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Image.network(product.image, fit: BoxFit.cover),
                            ),
                            SizedBox(height: 5),
                            Text(
                              product.name,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(product.category, style: TextStyle(fontSize: 14, color: Colors.grey)),
                            Text(desc, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Text('₹${product.price}', style: TextStyle(fontSize: 16)),
                                IconButton(
                                  icon: Icon(Icons.add_shopping_cart, size: 30),
                                  onPressed: () {
                                    Provider.of<CartProvider>(context, listen: false).addItemToCart(product.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${product.name} added to cart!')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CategoryButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const CategoryButton({
    required this.label,
    required this.onPressed,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: isSelected ? Colors.blue.shade900 : Colors.blue.shade700,
        ),
        child: Text(label),
      ),
    );
  }
}
