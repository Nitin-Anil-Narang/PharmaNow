import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Admin"),
          backgroundColor: Colors.blueAccent,
        ),
        backgroundColor: Colors.grey.shade300,
        body: ListView(
          // mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/add_product');
                },
                child: Center(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: Image.network(
                          'https://cdn-icons-png.flaticon.com/512/10608/10608872.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                      Text(
                        "Add Products",
                        style: TextStyle(fontSize: 32),
                      ),
                    ],
                  ),
                ),
              ),
            ),SizedBox(height: 10,),
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/orders');
                },
                child: Center(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 190,
                        child: Image.network(
                          'https://cdn-icons-png.flaticon.com/128/3045/3045670.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                      Text(
                        "Orders",
                        style: TextStyle(fontSize: 32),
                      ),
                    ],
                  ),
                ),
              ),
            ),SizedBox(height: 10,)
            ,Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/reports');
                },
                child: Center(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: Image.network(
                          'https://cdn-icons-png.flaticon.com/128/3534/3534066.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                      Text(
                        "Reports",
                        style: TextStyle(fontSize: 32),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 10,),
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/list_product');
                },
                child: Center(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: Image.network(
                          'https://cdn-icons-png.freepik.com/256/2527/2527548.png?semt=ais_hybrid',
                          fit: BoxFit.cover,
                        ),
                      ),
                      Text(
                        "View Products",
                        style: TextStyle(fontSize: 32),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ));
  }
}
