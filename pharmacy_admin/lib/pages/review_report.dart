import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';

class AdminReviewReportPage extends StatefulWidget {
  @override
  _AdminReviewReportPageState createState() => _AdminReviewReportPageState();
}

class _AdminReviewReportPageState extends State<AdminReviewReportPage> {
  List<dynamic> reviewReports = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchReviewReports();
  }

  Future<void> fetchReviewReports() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:4000/review-report'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          reviewReports = data['reports'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load review reports');
      }
    } catch (error) {
      print('Error fetching review reports: $error');
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<void> generatePDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Review Reports", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              for (var report in reviewReports)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Date: ${report['_id']['date']}", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text("Product ID: ${report['_id']['productId']}", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text("Total Reviews: ${report['totalReviews']}"),
                    pw.Text("Average Rating: ${report['averageRating'].toStringAsFixed(1)} ⭐"),
                    pw.SizedBox(height: 10),
                  ],
                ),
            ],
          );
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final filePath = "${directory.path}/review_report.pdf";
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    OpenFile.open(filePath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Review Reports")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: generatePDF,
            child: Text("Download Report as PDF"),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : hasError
                    ? Center(child: Text("Failed to load reports"))
                    : Column(
                        children: [
                          SizedBox(height: 200, child: buildChart()),
                          Expanded(
                            child: ListView.builder(
                              itemCount: reviewReports.length,
                              itemBuilder: (context, index) {
                                final report = reviewReports[index];
                                double avg = report['averageRating'].roundToDouble();
                                return Card(
                                  margin: EdgeInsets.all(10),
                                  child: ListTile(
                                    title: Text("Date: ${report['_id']['date']}", style: TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Product ID: ${report['_id']['productId']}", style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text("Total Reviews: ${report['totalReviews']}"),
                                        Text("Rating: ${avg.toString()} ⭐"),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget buildChart() {
    Map<int, int> productRatings = {};
    Map<int, int> productReviewCount = {};

    for (var report in reviewReports) {
      int productId = report['_id']['productId'];
      int totalRating = (report['averageRating'] * report['totalReviews']).round();
      int totalReviews = report['totalReviews'];

      productRatings.update(productId, (value) => value + totalRating, ifAbsent: () => totalRating);
      productReviewCount.update(productId, (value) => value + totalReviews, ifAbsent: () => totalReviews);
    }

    List<BarChartGroupData> barGroups = productRatings.entries.map((entry) {
      int productId = entry.key;
      double overallAvg = (productRatings[productId]! / productReviewCount[productId]!).roundToDouble() - 1;
      return BarChartGroupData(
        x: productId,
        barRods: [
          BarChartRodData(
            toY: overallAvg,
            color: Colors.blue,
            width: 16,
          ),
        ],
      );
    }).toList();

    return Padding(
      padding: EdgeInsets.all(10),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barGroups: barGroups,
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 1, getTitlesWidget: (value, meta) {
                return Text("${value.toInt() + 1}", style: TextStyle(fontSize: 10));
              }),
            ),
            
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Text("ID: ${value.toInt()}", style: TextStyle(fontSize: 10));
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
        ),
      ),
    );
  }
}
