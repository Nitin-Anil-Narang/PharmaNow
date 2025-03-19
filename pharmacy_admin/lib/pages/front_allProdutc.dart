import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:admin/pages/product_deatil.dart';
import 'edit_product.dart';

class ProductListScreen extends StatefulWidget {
  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<dynamic> productList = [];

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    const String apiUrl = 'http://localhost:4000/allproduct';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        if (Platform.isAndroid) {
          for (var product in data) {
            if (product['image'] != null &&
                product['image'].contains('localhost')) {
              product['image'] =
                  product['image'].replaceAll('localhost', '10.0.2.2');
            }
          }
        }

        if (mounted) {
          setState(() {
            productList = data;
          });
        }
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      print("Error fetching products: $e");
    }
  }

  Future<void> removeProduct(int index, int id, String productId) async {
    final String apiUrl = 'http://localhost:4000/removeproduct';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": id, "name": productId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['sucess'] == true) {
          setState(() {
            productList.removeAt(index);
          });
        }
      }
    } catch (e) {
      print("Exception: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade300,
      appBar: AppBar(title: Text('Product List')),
      body: productList.isEmpty
          ? Center(child: Text('No products found.'))
          : ListView.builder(
              itemCount: productList.length,
              itemBuilder: (context, index) {
                var product = productList[index];
                int id = product['id'] ?? null;
                String name = product['name'] ?? 'No Name';
                double price = product['new_price']?.toDouble() ?? 0.0;
                // String description = product['description'] ?? 'No description';
                int stock = product['stock'] ?? 0;
                String imageUrl = product['image'] ?? '';

                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: imageUrl.isNotEmpty
                        ? Image.network(imageUrl,
                            width: 50, height: 50, fit: BoxFit.cover)
                        : Icon(Icons.image, size: 50),
                    title: Text(name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('₨ ${price.toStringAsFixed(2)}'),
                        Text('Stock: $stock'),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProductDetailScreen(product: product),
                        ),
                      );
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () async {
                            bool? updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditProductScreen(product: product),
                              ),
                            );

                            if (updated == true) {
                              fetchProducts();
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => removeProduct(index, id, name),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
