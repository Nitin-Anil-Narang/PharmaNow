import 'package:flutter/material.dart';
import 'package:admin/pages/home.dart';
import 'package:admin/pages/orders.dart';
import 'package:admin/pages/reports.dart';
import 'package:admin/pages/splash_screen.dart';
import 'package:admin/pages/front_allProdutc.dart';
import 'package:admin/backend/add_product.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
     MyApp(),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pharama Admin',
      routes: {
        '/': (context) => SplashScreen(),
        '/home': (context) => Home(),
        '/add_product': (context) => ImageUploadScreen(),
        '/list_product': (context) => ProductListScreen(),
        '/reports': (context) => ProfitGraphScreen(),
        '/orders': (context) => OrdersPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
