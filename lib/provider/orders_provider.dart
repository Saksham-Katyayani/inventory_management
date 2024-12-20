import 'dart:developer';
import 'package:logger/logger.dart';
import 'package:flutter/material.dart';
import 'package:inventory_management/model/orders_model.dart'; // Ensure you have the Order model defined here
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrdersProvider with ChangeNotifier {
  bool allSelectedReady = false;
  bool allSelectedFailed = false;
  int selectedReadyItemsCount = 0;
  int selectedFailedItemsCount = 0;
  List<bool> _selectedReadyOrders = [];
  List<bool> _selectedFailedOrders = [];
  List<Order> readyOrders = []; // List to store fetched ready orders
  List<Order> failedOrders = []; // List to store fetched failed orders
  int totalFailedPages = 1; // Default value 1
  int totalReadyPages = 1;
  String? _selectedCourier;
  String? _selectedPayment;
  String? _selectedFilter;
  String? _selectedMarketplace;
  String _expectedDeliveryDate = '';
  String _paymentDateTime = '';
  String _normalDate = '';
  List<Order> filteredReadyOrders = [];
  List<Order> filteredFailedOrders = [];

  int currentPage = 1;
  int totalPages = 1;
  int currentPageReady = 1;
  int currentPageFailed = 1;

  // Loading state
  bool isLoading = false;

  // Public getters for selected orders
  List<bool> get selectedFailedOrders => _selectedFailedOrders;
  List<bool> get selectedReadyOrders => _selectedReadyOrders;

  final List<Order> _failedOrder = [];

  List<Order> get failedOrder => _failedOrder;

  String? get selectedCourier => _selectedCourier;
  String? get selectedPayment => _selectedPayment;
  String? get selectedMarketplace => _selectedMarketplace;
  String? get selectedFilter => _selectedFilter;
  String get expectedDeliveryDate => _expectedDeliveryDate;
  String get paymentDateTime => _paymentDateTime;
  String get normalDate => _normalDate;

  bool isConfirm = false;
  bool isCancel = false;
  bool isUpdating = false;

  void setUpdating(bool status) {
    isUpdating = status;
    notifyListeners();
  }

  void setConfirmStatus(bool status) {
    isConfirm = status;
    notifyListeners();
  }

  void setCancelStatus(bool status) {
    isCancel = status;
    notifyListeners();
  }

  void updateDate(String date) {
    _normalDate = date;
    notifyListeners();
  }

  void updateExpectedDeliveryDate(String date) {
    _expectedDeliveryDate = date;
    notifyListeners();
  }

  void updatePaymentDateTime(String dateTime) {
    _paymentDateTime = dateTime;
    notifyListeners();
  }

  // Method to set the selected payment mode
  void selectPayment(String? paymentMode) {
    _selectedPayment = paymentMode;
    notifyListeners();
  }

  // Method to set an initial value for pre-filling
  void setInitialPaymentMode(String? paymentMode) {
    _selectedPayment =
        (paymentMode == null || paymentMode.isEmpty) ? null : paymentMode;
    notifyListeners();
  }

  // Method to set the selected filter
  void selectFilter(String? filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  // Method to set an initial value for pre-filling
  void setInitialFilter(String? filter) {
    _selectedFilter = (filter == null || filter.isEmpty) ? null : filter;
    notifyListeners();
  }

  // Method to set the selected Marketplace
  void selectMarketplace(String? marketplace) {
    _selectedMarketplace = marketplace;
    notifyListeners();
  }

  // Method to set an initial value for pre-filling
  void setInitialMarketplace(String? marketplace) {
    _selectedMarketplace =
        (marketplace == null || marketplace.isEmpty) ? null : marketplace;
    notifyListeners();
  }

  // Method to set the selected courier
  void selectCourier(String? courier) {
    _selectedCourier = courier;
    notifyListeners();
  }

  // Method to set an initial value for pre-filling
  void setInitialCourier(String? courier) {
    _selectedCourier = (courier == null || courier.isEmpty) ? null : courier;
    notifyListeners();
  }

  // New method to reset selections and counts
  void resetSelections() {
    allSelectedReady = false;
    allSelectedFailed = false;

    selectedReadyOrders.fillRange(0, selectedReadyOrders.length, false);
    selectedFailedOrders.fillRange(0, selectedFailedOrders.length, false);

    // Reset counts
    selectedReadyItemsCount = 0;
    selectedFailedItemsCount = 0;

    notifyListeners();
  }

  // Function to update an order
  Future<void> updateOrder(String id, Map<String, dynamic> updatedData) async {
    // Get the auth token
    final token = await _getToken();

    // Check if the token is valid
    if (token == null || token.isEmpty) {
      isLoading = false;
      notifyListeners();
      print('Token is missing. Please log in again.');
      return;
    }

    final url =
        'https://inventory-management-backend-s37u.onrender.com/orders/$id';
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(updatedData),
      );

      if (response.statusCode == 200) {
        print('Order updated successfully');

        await fetchFailedOrders();
        await fetchReadyOrders();

        notifyListeners();
      } else if (response.statusCode == 400) {
        final responseBody = json.decode(response.body);
        if (responseBody['message'] == 'orderId and status are required.') {
          print('Error: Order ID and status are required.');
        }
      } else {
        print('Failed to update order: ${response.body}');
        return;
      }
    } catch (error) {
      print('Error updating order: $error');
      rethrow;
    }
    notifyListeners();
  }

  Future<void> fetchFailedOrders({int page = 1}) async {
    log("called");
    // Ensure the requested page number is valid
    if (page < 1 || page > totalFailedPages) {
      print('Invalid page number for failed orders: $page');
      return; // Exit if the page number is invalid
    }

    isLoading = true;
    notifyListeners();

    final String failedOrdersUrl =
        'https://inventory-management-backend-s37u.onrender.com/orders?orderStatus=0&page=$page';

    // Get the auth token
    final token = await _getToken();

    // Check if the token is valid
    if (token == null || token.isEmpty) {
      isLoading = false;
      notifyListeners();
      print('Token is missing. Please log in again.');
      return; // Stop execution if there's no token
    }

    try {
      // Fetch failed orders
      final responseFailed = await http.get(
        Uri.parse(failedOrdersUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (responseFailed.statusCode == 200) {
        log("Status: ${responseFailed.statusCode}");
        final jsonData = json.decode(responseFailed.body);

        log("jsonData: $jsonData");

        failedOrders = (jsonData['orders'] as List)
            .map((order) => Order.fromJson(order))
            .toList();

        // Check for null values before assigning
        totalFailedPages = (jsonData['totalPages'] as int?) ?? 1;

        // totalFailedPages = jsonData['totalPages'] ?? 1; // Default to 1 if null
        currentPageFailed = page; // Update the current page for failed orders

        log("failedOrders: $failedOrders");

        // Reset selections
        resetSelections();
        _selectedFailedOrders = List<bool>.filled(failedOrders.length, false);
        filteredFailedOrders = failedOrders;
      } else {
        throw Exception('Failed to load failed orders: ${responseFailed.body}');
      }
    } catch (e) {
      print('Error fetching failed orders: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Future<void> fetchFailedOrders({int page = 1}) async {
  //   log("called");
  //   // Ensure the requested page number is valid
  //   if (page < 1 || page > totalFailedPages) {
  //     print('Invalid page number for failed orders: $page');
  //     return; // Exit if the page number is invalid
  //   }

  //   isLoading = true;
  //   notifyListeners();

  //   final String failedOrdersUrl =
  //       'https://inventory-management-backend-s37u.onrender.com/orders?orderStatus=0&page=$page';

  //   // Get the auth token
  //   final token = await _getToken();

  //   // Check if the token is valid
  //   if (token == null || token.isEmpty) {
  //     isLoading = false;
  //     notifyListeners();
  //     print('Token is missing. Please log in again.');
  //     return; // Stop execution if there's no token
  //   }

  //   try {
  //     // Fetch failed orders
  //     final responseFailed = await http.get(
  //       Uri.parse(failedOrdersUrl),
  //       headers: {
  //         'Authorization': 'Bearer $token',
  //         'Content-Type': 'application/json',
  //       },
  //     );

  //     if (responseFailed.statusCode == 200) {
  //       log("Status: ${responseFailed.statusCode}");
  //       final jsonData = json.decode(responseFailed.body);

  //       log("jsonData: $jsonData");

  //       failedOrders = (jsonData['orders'] as List)
  //           .map((order) => Order.fromJson(order))
  //           .toList();
  //       totalFailedPages = jsonData['totalPages'] ?? 1; // Update total pages
  //       currentPageFailed = page; // Update the current page for failed orders

  //       log("failedOrders: $failedOrders");

  //       // Reset selections
  //       resetSelections();
  //       _selectedFailedOrders = List<bool>.filled(failedOrders.length, false);
  //       filteredFailedOrders = failedOrders;
  //     } else {
  //       throw Exception('Failed to load failed orders: ${responseFailed.body}');
  //     }
  //   } catch (e) {
  //     print('Error fetching failed orders: $e');
  //   } finally {
  //     isLoading = false;
  //     notifyListeners();
  //   }
  // }

  Future<void> fetchReadyOrders({int page = 1}) async {
    // Ensure the requested page number is valid
    if (page < 1 || page > totalReadyPages) {
      print('Invalid page number for ready orders: $page');
      return; // Exit if the page number is invalid
    }

    isLoading = true;
    notifyListeners();

    final String readyOrdersUrl =
        'https://inventory-management-backend-s37u.onrender.com/orders?orderStatus=1&page=$page';

    // Get the auth token
    final token = await _getToken();

    // Check if the token is valid
    if (token == null || token.isEmpty) {
      isLoading = false;
      notifyListeners();
      print('Token is missing. Please log in again.');
      return; // Stop execution if there's no token
    }

    try {
      // Fetch ready orders
      final responseReady = await http.get(Uri.parse(readyOrdersUrl), headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (responseReady.statusCode == 200) {
        final jsonData = json.decode(responseReady.body);
        readyOrders = (jsonData['orders'] as List)
            .map((order) => Order.fromJson(order))
            .toList();
        totalReadyPages = jsonData['totalPages'] ?? 1; // Update total pages
        currentPageReady = page; // Update the current page for ready orders

        // Reset selections
        resetSelections();
        _selectedReadyOrders = List<bool>.filled(readyOrders.length, false);
        filteredReadyOrders = readyOrders;
      } else {
        throw Exception('Failed to load ready orders: ${responseReady.body}');
      }
    } catch (e) {
      print('Error fetching ready orders: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String> confirmOrders(
      BuildContext context, List<String> orderIds) async {
    const String baseUrl =
        'https://inventory-management-backend-s37u.onrender.com';
    const String confirmOrderUrl = '$baseUrl/orders/confirm';
    final String? token = await _getToken();
    setConfirmStatus(true);
    notifyListeners();

    if (token == null) {
      return 'No auth token found';
    }

    // Headers for the API request
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    // Request body containing the order IDs
    final body = json.encode({
      'orderIds': orderIds,
    });

    try {
      // Make the POST request to confirm the orders
      final response = await http.post(
        Uri.parse(confirmOrderUrl),
        headers: headers,
        body: body,
      );

      print('Response status: ${response.statusCode}');
      //print('Response body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // After successful confirmation, fetch updated orders and notify listeners
        await fetchReadyOrders(); // Assuming fetchOrders is a function that reloads the orders
        resetSelections(); // Clear selected order IDs
        setConfirmStatus(false);
        notifyListeners(); // Notify the UI to rebuild

        return responseData['message'] ?? 'Orders confirmed successfully';
      } else {
        return responseData['message'] ?? 'Failed to confirm orders';
      }
    } catch (error) {
      setConfirmStatus(false);
      notifyListeners();
      print('Error during API request: $error');
      return 'An error occurred: $error';
    }
  }

  Future<String> cancelOrders(
      BuildContext context, List<String> orderIds) async {
    const String baseUrl =
        'https://inventory-management-backend-s37u.onrender.com';
    const String cancelOrderUrl = '$baseUrl/orders/cancel';
    final String? token = await _getToken();
    setCancelStatus(true);
    notifyListeners();

    if (token == null) {
      return 'No auth token found';
    }

    // Headers for the API request
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    // Request body containing the order IDs
    final body = json.encode({
      'orderIds': orderIds,
    });

    try {
      // Make the POST request to confirm the orders
      final response = await http.post(
        Uri.parse(cancelOrderUrl),
        headers: headers,
        body: body,
      );

      print('Response status: ${response.statusCode}');
      //print('Response body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // After successful confirmation, fetch updated orders and notify listeners
        await fetchReadyOrders(); // Assuming fetchOrders is a function that reloads the orders
        resetSelections(); // Clear selected order IDs
        setCancelStatus(false);
        notifyListeners(); // Notify the UI to rebuild

        return responseData['message'] ?? 'Orders confirmed successfully';
      } else {
        return responseData['message'] ?? 'Failed to confirm orders';
      }
    } catch (error) {
      setCancelStatus(false);
      notifyListeners();
      print('Error during API request: $error');
      return 'An error occurred: $error';
    }
  }

  void toggleSelectAllReady(bool isSelected) {
    allSelectedReady = isSelected;
    selectedReadyItemsCount = isSelected
        ? readyOrders.length
        : 0; // Update count based on selection state
    _selectedReadyOrders = List<bool>.filled(
        readyOrders.length, isSelected); // Update selection list

    notifyListeners();
  }

  void toggleSelectAllFailed(bool isSelected) {
    allSelectedFailed = isSelected;
    selectedFailedItemsCount = isSelected
        ? failedOrders.length
        : 0; // Update count based on selection state
    _selectedFailedOrders = List<bool>.filled(
        failedOrders.length, isSelected); // Update selection list

    notifyListeners();
  }

  void toggleOrderSelectionFailed(bool value, int index) {
    if (index >= 0 && index < _selectedFailedOrders.length) {
      _selectedFailedOrders[index] = value;
      selectedFailedItemsCount = _selectedFailedOrders
          .where((selected) => selected)
          .length; // Update count of selected items

      // Check if all selected
      allSelectedFailed = selectedFailedItemsCount == failedOrders.length;

      notifyListeners();
    }
  }

  void toggleOrderSelectionReady(bool value, int index) {
    if (index >= 0 && index < _selectedReadyOrders.length) {
      _selectedReadyOrders[index] = value;
      selectedReadyItemsCount = _selectedReadyOrders
          .where((selected) => selected)
          .length; // Update count of selected items

      // Check if all selected
      allSelectedReady = selectedReadyItemsCount == readyOrders.length;

      notifyListeners();
    }
  }

  // Update status for failed orders
  Future<void> updateFailedOrders(BuildContext context) async {
    setUpdating(true);
    notifyListeners();
    final List<String> failedOrderIds = failedOrders
        .asMap()
        .entries
        .where((entry) => _selectedFailedOrders[entry.key])
        .map((entry) => entry.value.orderId)
        .toList();

    if (failedOrderIds.isEmpty) {
      _showSnackbar(context, 'No orders selected to update.');
      return;
    }

    for (String orderId in failedOrderIds) {
      await updateOrderStatus(
          context, orderId, 1); // Update status to 1 for failed orders
    }

    // Reload orders after updating
    await fetchFailedOrders(); // Refresh the orders after update

    // Reset checkbox states
    allSelectedFailed = false; // Reset "Select All" checkbox
    _selectedFailedOrders =
        List<bool>.filled(failedOrders.length, false); // Reset selection list
    selectedFailedItemsCount = 0; // Reset selected items count
    setUpdating(false);
    notifyListeners(); // Notify listeners to update UI
  }

// Update status for ready-to-confirm orders
  Future<void> updateReadyToConfirmOrders(BuildContext context) async {
    final List<String> readyOrderIds = readyOrders
        .asMap()
        .entries
        .where((entry) => _selectedReadyOrders[entry.key])
        .map((entry) => entry.value.orderId)
        .toList();

    if (readyOrderIds.isEmpty) {
      _showSnackbar(context, 'No orders selected to update.');
      return;
    }

    for (String orderId in readyOrderIds) {
      await updateOrderStatus(context, orderId,
          2); // Update status to 2 for ready-to-confirm orders
    }

    // Reload orders after updating
    await fetchReadyOrders(); // Refresh the orders after update

    // Reset checkbox states
    allSelectedReady = false; // Reset "Select All" checkbox
    _selectedReadyOrders =
        List<bool>.filled(readyOrders.length, false); // Reset selection list
    selectedReadyItemsCount = 0; // Reset selected items count

    notifyListeners(); // Notify listeners to update UI
  }

  // Existing updateOrderStatus function
  Future<void> updateOrderStatus(
      BuildContext context, String orderId, int newStatus) async {
    final String? token = await _getToken();
    if (token == null) {
      _showSnackbar(context, 'No auth token found');
      return;
    }

    // Define the URL for the update with query parameters
    final String url =
        'https://inventory-management-backend-s37u.onrender.com/orders?orderId=$orderId&status=$newStatus';

    // Set up the headers for the request
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      // Make the PUT request
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // Show snackbar and trigger fetchOrders in parallel
        _showSnackbar(context, 'Order status updated successfully');
        // Reload orders immediately after the snackbar is shown
        await fetchFailedOrders(); // Refresh failed orders
        await fetchReadyOrders(); // Refresh ready orders
      } else {
        final errorResponse = json.decode(response.body);
        String errorMessage =
            errorResponse['message'] ?? 'Failed to update order status';
        _showSnackbar(context, errorMessage);
        throw Exception(
            'Failed to update order status: ${response.statusCode} ${response.body}');
      }
    } catch (error) {
      _showSnackbar(
          context, 'An error occurred while updating the order status: $error');
      throw Exception(
          'An error occurred while updating the order status: $error');
    }
  }

  // Method to display a snackbar
  void _showSnackbar(BuildContext context, String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Method to get the token from shared preferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // Format date
  String formatDate(DateTime date) {
    String year = date.year.toString();
    String month = date.month.toString().padLeft(2, '0');
    String day = date.day.toString().padLeft(2, '0');
    return '$day-$month-$year';
  }

  String formatDateTime(DateTime date) {
    String year = date.year.toString();
    String month = date.month.toString().padLeft(2, '0');
    String day = date.day.toString().padLeft(2, '0');
    String hour = date.hour.toString().padLeft(2, '0');
    String minute = date.minute.toString().padLeft(2, '0');
    String second = date.second.toString().padLeft(2, '0');

    return '$day-$month-$year $hour:$minute:$second';
  }

  void clearSearchResults() {
    filteredReadyOrders = readyOrders;
    filteredFailedOrders = failedOrders;
    notifyListeners();
  }

  Future<void> searchReadyToConfirmOrders(String orderId) async {
    final url = Uri.parse(
        'https://inventory-management-backend-s37u.onrender.com/orders?orderStatus=1&order_id=$orderId');
    final token = await _getToken();
    if (token == null) return;

    try {
      isLoading = true;
      notifyListeners();

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(response.body);

        filteredReadyOrders = [Order.fromJson(data)];
        print(response.body);
      } else {
        filteredReadyOrders = [];
      }
    } catch (e) {
      filteredReadyOrders = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchFailedOrders(String orderId) async {
    final url = Uri.parse(
        'https://inventory-management-backend-s37u.onrender.com/orders?orderStatus=0&order_id=$orderId');
    final token = await _getToken();
    if (token == null) return;

    try {
      isLoading = true;
      notifyListeners();

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(response.body);

        filteredFailedOrders = [Order.fromJson(data)];
        print(response.body);
      } else {
        filteredFailedOrders = [];
      }
    } catch (e) {
      filteredFailedOrders = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchOrdersByMarketplace(
      String marketplace, int orderStatus, int page) async {
    const String baseUrl =
        'https://inventory-management-backend-s37u.onrender.com/orders';
    String url =
        '$baseUrl?orderStatus=$orderStatus&marketplace=$marketplace&page=$page';

    String? token =
        await _getToken(); // Assuming you have a method to get the token
    if (token == null) {
      print('Token is null, unable to fetch orders.');
      return;
    }

    try {
      isLoading = true;
      notifyListeners();

      // Clear checkboxes when a new page is fetched
      // clearSearchResults();

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // Log response for debugging
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        List<Order> orders = (jsonResponse['orders'] as List)
            .map((orderJson) => Order.fromJson(orderJson))
            .toList();

        Logger().e("length: ${orders.length}");

        // Store fetched orders and update pagination state
        if (orderStatus == 1) {
          filteredReadyOrders = orders;
          currentPageReady = page; // Track current page for B2B
          totalReadyPages =
              jsonResponse['totalPages']; // Assuming API returns total pages
          notifyListeners();
        } else {
          filteredFailedOrders = orders;
          currentPageFailed = page; // Track current page for B2C
          totalFailedPages =
              jsonResponse['totalPages']; // Assuming API returns total pages
          notifyListeners();
        }
      } else if (response.statusCode == 401) {
        print('Unauthorized access - Token might be expired or invalid.');
      } else if (response.statusCode == 404) {
        if (orderStatus == 1) {
          filteredReadyOrders = [];
          notifyListeners();
        } else {
          filteredFailedOrders = [];
          notifyListeners();
        }
        print('Orders not found - Check the filter type.');
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching orders: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
