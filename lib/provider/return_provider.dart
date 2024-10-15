
import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart'as http;
import '../model/orders_model.dart';

class ReturnProvider extends ChangeNotifier{
  bool _isLoading = false;
  bool _selectAll = false;
  List<bool> _selectedProducts = [];
  List<Order> _orders = [];
  int _currentPage = 1; // Ensure this starts at 1
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

  Future<void> fetchOrdersWithStatus8() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    const url =
        'https://inventory-management-backend-s37u.onrender.com/orders?orderStatus=8&page=';

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
        initializeSelection();

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
  void goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    _currentPage = page;
    print('Current page set to: $_currentPage'); // Debugging line
    fetchOrdersWithStatus8();
    notifyListeners();
  }

  // Format date
  String formatDate(DateTime date) {
    String year = date.year.toString();
    String month = date.month.toString().padLeft(2, '0');
    String day = date.day.toString().padLeft(2, '0');
    return '$day-$month-$year';
  }

  List<Order> ordersReturned = []; // List of returned orders
  List<bool> selectedReturnedItems = []; // Selection state for returned orders
  bool selectAllReturned = false;

  void initializeSelection() {
    _selectedProducts = List<bool>.filled(_orders.length, false);
    selectedReturnedItems = List<bool>.filled(ordersReturned.length, false);
  }

  // Handle individual row checkbox change for orders
  void handleRowCheckboxChange(int index, bool isSelected) {
    _selectedProducts[index] = isSelected;
    notifyListeners();
  }

  // Handle individual row checkbox change for returned orders
  void handleRowCheckboxChangeForReturned(String? orderId, bool isSelected) {
    int index = ordersReturned.indexWhere((order) => order.orderId == orderId);
    if (index != -1) {
      selectedReturnedItems[index] = isSelected;
      ordersReturned[index].isSelected = isSelected;
      _updateSelectAllStateForReturned();
    }
    notifyListeners();
  }
  void _updateSelectAllStateForReturned() {
    selectAllReturned = selectedReturnedItems.every((item) => item);
    notifyListeners();
  }

  bool _isReturning = false;
  bool get isReturning => _isReturning;


  Future<void> returnSelectedOrders() async {

    _isReturning = true; // Set loading state
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    List<String> selectedOrderIds = [];

    // Collect the IDs of orders where trackingStatus is 'NA' (null or empty)
    for (int i = 0; i < _selectedProducts.length; i++) {
      if (_selectedProducts[i] && (_orders[i].trackingStatus?.isEmpty ?? true)) {
        selectedOrderIds.add(_orders[i].orderId);
      }
    }

    if (selectedOrderIds.isNotEmpty) {
      final url = 'https://inventory-management-backend-s37u.onrender.com/orders/return';

      try {
        final body = json.encode({
          'orderIds': selectedOrderIds,
           // This should send 'return' as the tracking status
        });

        //print('Request body: $body'); // Verify request body

        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: body,
        );

        print('Response status: ${response.statusCode}');
       // print('Response body: ${response.body}'); // Check for errors in the response

        if (response.statusCode == 200) {
          print('Orders returned successfully!');
          // Update local order tracking status
          for (int i = 0; i < _orders.length; i++) {
            if (_selectedProducts[i] && (_orders[i].trackingStatus?.isEmpty ?? true)) {
              _orders[i].trackingStatus = 'return'; // Update locally
            }
          }

          notifyListeners(); // Refresh UI
        } else {
          print('Failed to return orders: ${response.body}');
        }
      } catch (e) {
        print('Error: $e');
      }
      finally {
        _isReturning = false; // Reset loading state
        notifyListeners();
      }
    } else {
      print('No valid orders selected for return.');
    }
  }
  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isEmpty) {
        // If query is empty, reload all orders
        fetchOrdersWithStatus8();
      } else {
        searchOrders(query); // Trigger the search after the debounce period
      }
    });
  }

  Future<List<Order>> searchOrders(String query) async {
    if (query.isEmpty) {
      await fetchOrdersWithStatus8();
      return _orders;
    }

    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final url =
        'https://inventory-management-backend-s37u.onrender.com/orders?orderStatus=8&order_id=$query';

    print('Searching failed orders with term: $query');

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
        print('Response data: $jsonData');

        List<Order> orders = [];
        if (jsonData != null) {
          orders.add(Order.fromJson(jsonData));
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

}


