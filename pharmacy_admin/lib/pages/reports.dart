import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ProfitGraphScreen(),
    );
  }
}

class ProfitGraphScreen extends StatefulWidget {
  @override
  _ProfitGraphScreenState createState() => _ProfitGraphScreenState();
}

class _ProfitGraphScreenState extends State<ProfitGraphScreen> {
  Map<String, dynamic>? apiResponse;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final response =
        await http.get(Uri.parse('http://localhost:4000/calculate-profit-pdf'));
    if (response.statusCode == 200) {
      setState(() {
        apiResponse = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<void> generatePdf() async {
    if (apiResponse == null) return;

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Profit Report",
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(children: [
                    pw.Text("Date",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text("Product Name",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text("Profit",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ]),
                  ...apiResponse!['profitData']
                      .map((product) => pw.TableRow(children: [
                            pw.Text(product['date']),
                            pw.Text(product['productName']),
                            pw.Text("${product['profit']}")
                          ])),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text("Daily Stats",
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(children: [
                    pw.Text("Date",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text("Total Profit",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text("Total Sold",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ]),
                  ...apiResponse!['dailyStats']
                      .map((day) => pw.TableRow(children: [
                            pw.Text(day['date']),
                            pw.Text("${day['profit']}"),
                            pw.Text("${day['totalSold']}")
                          ])),
                ],
              ),
            ],
          );
        },
      ),
    );

    final directory = Platform.isAndroid
        ? await getExternalStorageDirectory()
        : await getApplicationDocumentsDirectory();
    final file = File("${directory!.path}/profit_report.pdf");
    await file.writeAsBytes(await pdf.save());

    OpenFile.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profit Graph")),
      body: apiResponse == null
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(height: 100),
                Expanded(flex: 2, child: buildGraph()),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: ElevatedButton(
                      onPressed: generatePdf,
                      child: Text("Download PDF"),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget buildGraph() {
    if (apiResponse == null) return Container();

    List<FlSpot> spots = [];
    List<int> profits = [];
    int index = 0;
    for (var day in apiResponse!['dailyStats']) {
      spots.add(FlSpot(index.toDouble(), (day['profit'] as int).toDouble()));
      profits.add(day['profit']);
      index++;
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          titlesData: FlTitlesData(
            // leftTitles: AxisTitles(
            //   sideTitles: SideTitles(
            //     showTitles: true,
            //     reservedSize: 40,
            //     getTitlesWidget: (value, meta) {
            //       return Text("${value.toInt()}", style: TextStyle(fontSize: 10));
            //     },
            //   ),
            // ),
            // bottomTitles: AxisTitles(
            //   sideTitles: SideTitles(
            //     showTitles: true,
            //     reservedSize: 30,
            //     getTitlesWidget: (value, meta) {
            //       return Text("${value.toInt()}", style: TextStyle(fontSize: 10));
            //     },
            //   ),
            // ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            // rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 4,
              gradient:
                  LinearGradient(colors: [Colors.blue, Colors.blueAccent]),
              belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(colors: [
                    Colors.blue.withOpacity(0.3),
                    Colors.blueAccent.withOpacity(0.3)
                  ])),
              dotData: FlDotData(show: true),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 10,
              tooltipRoundedRadius: 8,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    "Profit: ${profits[spot.spotIndex]}",
                    TextStyle(color: Colors.white),
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
          ),
        ),
      ),
    );
  }
}
