import 'package:flutter/material.dart';
import 'package:pharmacy/home_upgrade.dart';
import 'package:pharmacy/login_page.dart';
import 'package:pharmacy/orders_page.dart';
import 'package:pharmacy/sign_up.dart';
import 'package:pharmacy/splash_screen.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';
import 'product_provider.dart';
import 'product_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'order_provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');
  // print("Token retrieved: ${token ?? 'No token found'}");
  runApp(MyApp(token: token??""));
}

class MyApp extends StatelessWidget {
  final String token;
  MyApp({required this.token});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => ProductProvider()),
        ChangeNotifierProvider(create: (ctx) => CartProvider()),
        ChangeNotifierProvider(create: (context) => OrderProvider()),
      ],
      child: MaterialApp(
        title: 'Wellness Pharma',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        debugShowCheckedModeBanner: false,
        
        routes: {
          '/': (context) => SplashScreen(),
          '/login': (context) => LoginPage(),
          '/signup': (context) => SignUpPage(),
          '/home': (context) => ProductPages(),
          '/products': (context) => ProductPage(),
          '/Orders': (context) => OrdersPage()
        },
      ),
    );
  }
}
