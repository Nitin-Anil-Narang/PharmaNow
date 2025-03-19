import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

class ImageUploadScreen extends StatefulWidget {
  @override
  _ImageUploadScreenState createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  File? _image;
  String? _responseMessage;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _originalPriceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _ingredientsController = TextEditingController(); // New ingredients field

  String _selectedCategory = 'Medicine';

  final ImagePicker _picker = ImagePicker();
  final Dio _dio = Dio();

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
    if (_image == null) return null;

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

  /// Submit product data
  Future<void> _addProduct() async {
    if (_image == null ||
        _nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _originalPriceController.text.isEmpty ||
        _stockController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _ingredientsController.text.isEmpty) { // Validate ingredients
      setState(() {
        _responseMessage = 'Please provide all details!';
      });
      return;
    }

    String? imageUrl = await _uploadImage(); // Upload image first

    if (imageUrl == null) {
      setState(() {
        _responseMessage = 'Image upload failed!';
      });
      return;
    }

    const String apiUrl = 'http://localhost:4000/addproduct';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": _nameController.text,
          "new_price": double.parse(_priceController.text),
          "original_price": double.parse(_originalPriceController.text),
          "stock": int.parse(_stockController.text),
          "description": _descriptionController.text,
          "ingredients": _ingredientsController.text, // Include ingredients
          "category": _selectedCategory,
          "image": imageUrl,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product added successfully!'))
        );
        Navigator.pushNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add product!'))
        );
      }
    } catch (e) {
      setState(() {
        _responseMessage = 'Error: $e';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    _ingredientsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade300,
      appBar: AppBar(title: Text('Add Product')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Image Preview
            _image == null
                ? Text('No image selected.')
                : Image.file(_image!, height: 200, fit: BoxFit.cover),
            SizedBox(height: 10),

            // Pick Image Button
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Select Image'),
            ),
            SizedBox(height: 20),

            // Product Name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),

            // New Price
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'New Price',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),

            // Original Price
            TextField(
              controller: _originalPriceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Original Price',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),

            // Stock
            TextField(
              controller: _stockController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Stock Quantity',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),

            // Description
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Product Description',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),

            // Ingredients (New Field)
            TextField(
              controller: _ingredientsController,
              decoration: InputDecoration(
                labelText: 'Ingredients',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),

            // Category Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: ['Medicine', 'Tools', 'Vitamins']
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
              decoration: InputDecoration(
                labelText: 'Select Category',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),

            // Submit Button
            ElevatedButton(
                onPressed: _addProduct, child: Text('Add Product')),
            SizedBox(height: 20),

            _responseMessage == null
                ? Container()
                : Text(
                    _responseMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.blue),
                  ),
          ],
        ),
      ),
    );
  }
}
