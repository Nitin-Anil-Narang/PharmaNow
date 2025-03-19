import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:pharmacy/cart_page.dart';
import 'package:pharmacy/orders_page.dart';
import 'package:pharmacy/product_detail.dart';
import 'package:provider/provider.dart';
import 'product_provider.dart';
import 'cart_provider.dart';
import 'order_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductPages extends StatefulWidget {
  const ProductPages({Key? key}) : super(key: key);

  @override
  _ProductPageStates createState() => _ProductPageStates();
}

class _ProductPageStates extends State<ProductPages> {
  String? token;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token');
    });
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);

    // Function to handle logout
    void logout(BuildContext context) async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');

      // Clear orders when logging out
      Provider.of<OrderProvider>(context, listen: false).clearOrders();

      // Navigate to login screen
      Navigator.pushReplacementNamed(context, '/login');
    }

    void orders() {
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please log in first.")),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrdersPage(), // Pass token
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Products", style: TextStyle(fontSize: 30)),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              if (token == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Please log in first.")),
                );

                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => CartPage(token: token!),
                ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text("User Name"),
              accountEmail: Text("user@example.com"),
              decoration: BoxDecoration(color: Colors.blueAccent),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.blue),
              ),
            ),
            ListTile(
              leading: Icon(MdiIcons.clipboardText),
              title: Text("My Orders"),
              onTap: orders,
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text("Logout"),
              onTap: () {
                logout(context);
              },
            ),
          ],
        ),
      ),
      body: FutureBuilder(
        future: productProvider.fetchProducts(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          List recentProducts = List.from(productProvider.products);
          recentProducts = recentProducts.length > 6
              ? recentProducts.sublist(recentProducts.length - 4)
              : recentProducts;

          return Column(
            children: [
              Expanded(
                flex: 8,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    height: 300,
                    child: Card(
                      color: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 120,
                              child: Image.network(
                                'https://achievece.com/_next/image?url=https://images.ctfassets.net/3cze0entj8bw/7wtcdGmMyxEhCrrVgA6Z9S/0c28e829bd11a34c32903222d988fea1/The_Opioid_Epidemic_Searching_for_Solutions.jpg&w=3840&q=75',
                                fit: BoxFit.contain,
                              ),
                            ),
                            SizedBox(height: 15),
                            Text(
                              "Medicines for All Your Health Needs",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Find the best medicines from trusted brands. We offer a wide variety of health products to keep you in top condition.",
                              style:
                                  TextStyle(fontSize: 14, color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 2),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/products');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.blueAccent,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                              ),
                              child: Text("Explore Products"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: Text(
                  "Most Recent Products",
                  style: TextStyle(fontSize: 25),
                ),
              ),
              Expanded(
                flex: 9,
                child: GridView.builder(
                  itemCount: recentProducts.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 40.0,
                    mainAxisSpacing: 10.0,
                    mainAxisExtent: 320,
                  ),
                  padding: EdgeInsets.all(10.0),
                  itemBuilder: (ctx, index) {
                    final product = recentProducts[index];
                    String desc = product.description.length > 50
                        ? product.description.substring(0, 40) + '...'
                        : product.description;
                    return GestureDetector(
                      onTap: () {
                        if (token == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Please log in first.")),
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailPage(
                                product: product, token: token!),
                          ),
                        );
                      },
                      child: GridTile(
                        child: Column(
                          children: [
                            SizedBox(
                              width: 150.0,
                              height: 150.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade500,
                                    width: 2,
                                  ),
                                ),
                                child: Image.network(
                                  product.image,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Text(product.name),
                            SizedBox(height: 4),
                            Text(desc,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.black)),
                            Text(product.category,
                                style: TextStyle(
                                    fontSize: 10, color: Colors.black)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Text('₹${product.price}',
                                    style: TextStyle(fontSize: 15)),
                                IconButton(
                                  icon: Icon(Icons.add_shopping_cart, size: 35),
                                  onPressed: () {
                                    if (token == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content:
                                                Text("Please log in first.")),
                                      );
                                      return;
                                    }
                                    Provider.of<CartProvider>(context,
                                            listen: false)
                                        .addItemToCart(product.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              '${product.name} added to cart!')),
                                    );
                                  },
                                ),
                              ],
                            )
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
