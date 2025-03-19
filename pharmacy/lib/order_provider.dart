import 'package:flutter/material.dart';

class OrderProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _orders = [];

  List<Map<String, dynamic>> get orders => _orders;

  void setOrders(List<Map<String, dynamic>> orders) {
    _orders = orders;
    notifyListeners();
  }

  void clearOrders() {
    _orders.clear();
    notifyListeners();
  }

  void updateOrderFeedback(String orderId, String feedback) {
    for (var order in _orders) {
      if (order['order_id'] == orderId) {
        order['feedback'] = feedback;
        notifyListeners();
        break;
      }
    }
  }
}
