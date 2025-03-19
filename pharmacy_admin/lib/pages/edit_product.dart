import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

class EditProductScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  EditProductScreen({required this.product});

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController descriptionController;
  late TextEditingController stockController;
  late TextEditingController originalPriceController;
  
  File? _image; // Selected image
  String? _imageUrl; // Existing image URL

  final ImagePicker _picker = ImagePicker();
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.product['name']);
    priceController = TextEditingController(text: widget.product['new_price'].toString());
    descriptionController = TextEditingController(text: widget.product['description']);
    stockController = TextEditingController(text: widget.product['stock'].toString());
    originalPriceController = TextEditingController(text: widget.product['original_price'].toString());
    _imageUrl = widget.product['image']; // Load existing image URL
  }

  /// Pick an image from the gallery
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  /// Upload image and return the URL
  Future<String?> _uploadImage() async {
    if (_image == null) return null; // No new image selected

    const String uploadUrl = 'http://localhost:4000/upload';

    try {
      FormData formData = FormData.fromMap({
        'product': await MultipartFile.fromFile(_image!.path),
      });

      var response = await _dio.post(uploadUrl, data: formData);

      if (response.statusCode == 200) {
        return response.data['image_url']; // Return new image URL
      } else {
        print("Image upload failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  /// Update product details, including the image, stock, and original price
  Future<void> updateProduct() async {
  final String apiUrl = 'http://localhost:4000/product/${widget.product['id']}';

  String? newImageUrl = await _uploadImage(); // Upload new image if selected

  try {
    final response = await http.put(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": nameController.text,
        "new_price": double.parse(priceController.text),
        "description": descriptionController.text,
        "stock": int.parse(stockController.text),
        "original_price": double.parse(originalPriceController.text),
        "image": newImageUrl ?? _imageUrl, // Use new or old image
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product updated successfully!'))
      );

      Navigator.pop(context, true); // Return true to refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update product'))
      );
    }
  } catch (e) {
    print("Error: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Product')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Image Preview
            _image != null
                ? Image.file(_image!, height: 200, fit: BoxFit.cover)
                : (_imageUrl != null
                    ? Image.network(_imageUrl!, height: 200, fit: BoxFit.cover)
                    : Text('No image selected')),
            SizedBox(height: 10),

            // Pick Image Button
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Change Image'),
            ),

            SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Product Name'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'New Price'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: originalPriceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Original Price'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Stock Quantity'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            SizedBox(height: 20),

            // Update Button
            ElevatedButton(
              onPressed: updateProduct,
              child: Text('Update Product'),
            ),
          ],
        ),
      ),
    );
  }
}
