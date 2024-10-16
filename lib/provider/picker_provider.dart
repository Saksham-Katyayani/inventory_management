import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:inventory_management/model/orders_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PickerProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _selectAll = false;
  List<bool> _selectedProducts = [];
  List<Order> _orders = [];
  int _currentPage = 1;
  int _totalPages = 1;
  PageController _pageController = PageController();
  TextEditingController _textEditingController = TextEditingController();
  Timer? _debounce;

  bool get selectAll => _selectAll;
  List<bool> get selectedProducts => _selectedProducts;
  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  PageController get pageController => _pageController;
  TextEditingController get textEditingController => _textEditingController;

  int get selectedCount =>
      _selectedProducts.where((isSelected) => isSelected).length;

  void toggleSelectAll(bool value) {
    _selectAll = value;
    _selectedProducts =
        List<bool>.generate(_orders.length, (index) => _selectAll);
    notifyListeners();
  }

  void toggleProductSelection(int index, bool value) {
    _selectedProducts[index] = value;
    _selectAll = selectedCount == _orders.length;
    notifyListeners();
  }

  Future<void> fetchOrdersWithStatus3() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    const url =
        'https://inventory-management-backend-s37u.onrender.com/orders?orderStatus=3&page=';

    try {
      final response = await http.get(Uri.parse('$url$_currentPage'), headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Order> orders = (data['orders'] as List)
            .map((order) => Order.fromJson(order))
            .toList();

        _totalPages = data['totalPages']; // Get total pages from response
        _orders = orders; // Set the orders for the current page

        // Initialize selected products list
        _selectedProducts = List<bool>.filled(_orders.length, false);

        // Print the total number of orders fetched from the current page
        print('Total Orders Fetched from Page $_currentPage: ${orders.length}');
      } else {
        // Handle non-success responses
        _orders = [];
        _totalPages = 1; // Reset total pages if there’s an error
      }
    } catch (e) {
      // Handle errors
      _orders = [];
      _totalPages = 1; // Reset total pages if there’s an error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isEmpty) {
        // If query is empty, reload all orders
        fetchOrdersWithStatus3();
      } else {
        searchOrders(query); // Trigger the search after the debounce period
      }
    });
  }

  Future<List<Order>> searchOrders(String query) async {
    if (query.isEmpty) {
      await fetchOrdersWithStatus3();
      return _orders;
    }

    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? ''; // Fetch the token

    final url =
        'https://inventory-management-backend-s37u.onrender.com/orders?orderStatus=3&order_id=$query';

    print('Searching orders with term: $query');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        List<Order> orders = [];
        // print('Response data: $jsonData');
        if (jsonData != null) {
          orders.add(Order.fromJson(jsonData));
          print('Response data: $jsonData');
        } else {
          print('No data found in response.');
        }

        _orders = orders;
        print('Orders fetched: ${orders.length}');
      } else {
        print('Failed to load orders: ${response.statusCode}');
        _orders = [];
      }
    } catch (error) {
      print('Error searching failed orders: $error');
      _orders = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return _orders;
  }
  // Future<Map<String, dynamic>?> searchByOrderId(String query) async {
  //   print("Searching for Order ID: $query");
  //   _isLoading = true;
  //   notifyListeners();
  //
  //   final url = Uri.parse('https://inventory-management-backend-s37u.onrender.com/orders?orderStatus=3&order_id=$query');
  //
  //   final prefs = await SharedPreferences.getInstance();
  //   final token = prefs.getString('token') ?? '';
  //
  //   try {
  //     final response = await http.get(url, headers: {
  //       'Authorization': 'Bearer $token', // Include token if needed
  //       'Content-Type': 'application/json',
  //     });
  //
  //     if (response.statusCode == 200) {
  //       final body = response.body;
  //       print("Response: $body");
  //
  //       if (body.isNotEmpty) {
  //         final Map<String, dynamic> jsonData = jsonDecode(body);
  //         if (jsonData.isNotEmpty) {
  //          // print("$jsonData");
  //           return jsonData;
  //
  //         } else {
  //           print('Response JSON is empty.');
  //           return null;
  //         }
  //       } else {
  //         print('Response body is empty.');
  //         return null;
  //       }
  //     } else {
  //       print('Failed to load order: ${response.statusCode}');
  //       print('Response body: ${response.body}');
  //       return null;
  //     }
  //   } catch (e) {
  //     print("Error fetching order: $e");
  //     return null;
  //   }
  //   finally{
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }

  void goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    _currentPage = page;
    print('Current page set to: $_currentPage');
    fetchOrdersWithStatus3();
    notifyListeners();
  }

  // Format date
  String formatDate(DateTime date) {
    String year = date.year.toString();
    String month = date.month.toString().padLeft(2, '0');
    String day = date.day.toString().padLeft(2, '0');
    return '$day-$month-$year';
  }
}
