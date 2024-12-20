import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/model/orders_model.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookProvider with ChangeNotifier {
  final TextEditingController searchController = TextEditingController();

  // Store selected states for B2B and B2C orders
  List<bool> selectedB2BItems = List.generate(40, (index) => false);
  List<bool> selectedB2CItems = List.generate(40, (index) => false);
  List<bool> selectedBookedItems = List.generate(40, (index) => false);

  // Select all flags for B2B and B2C
  bool selectAllB2B = false;
  bool selectAllB2C = false;
  bool selectAllBooked = false;

  // Loading states for B2B and B2C orders
  bool isLoadingB2B = false;
  bool isLoadingB2C = false;
  bool isLoadingBooked = false;

  // Sort option for orders
  String? _sortOption;
  String? get sortOption => _sortOption;

  // Lists for storing fetched orders
  List<Order> ordersB2B = [];
  List<Order> ordersB2C = [];
  List<Order> ordersBooked = [];

  List<Order> B2BOrders = []; // List to store fetched ready orders
  List<Order> B2COrders = [];
  List<Order> BookedOrders = [];

  // Pagination
  int currentPageB2B = 1;
  int currentPageB2C = 1;
  int currentPageBooked = 1;
  int totalPagesB2B = 0;
  int totalPagesB2C = 0;
  int totalPagesBooked = 0;

  bool isRefreshingOrders = false;
  bool isDelhiveryLoading = false;
  bool isShiprocketLoading = false;
  bool isOthersLoading = false;

  bool isCancel = false;

  void setCancelStatus(bool status) {
    isCancel = status;
    notifyListeners();
  }

  void setLoading(String provider, bool isLoading) {
    switch (provider) {
      case 'Delhivery':
        isDelhiveryLoading = isLoading;
        break;
      case 'Shiprocket':
        isShiprocketLoading = isLoading;
        break;
      case 'Others':
        isOthersLoading = isLoading;
        break;
    }
    notifyListeners();
  }

  void setRefreshingOrders(bool value) {
    isRefreshingOrders = value;
    notifyListeners();
  }

  void setRefreshingBookedOrders(bool value) {
    isRefreshingOrders = value;
    notifyListeners();
  }

  // Set the sort option and notify listeners
  void setSortOption(String? option) {
    _sortOption = option;
    notifyListeners();
  }

  Future<void> fetchPaginatedOrdersB2B(int page) async {
    await fetchOrders('B2B', page);
  }

  Future<String> cancelOrders(
      BuildContext context, List<String> orderIds) async {
    const String baseUrl =
        'https://inventory-management-backend-s37u.onrender.com';
    const String cancelOrderUrl = '$baseUrl/orders/cancel';
    // final String? token = await _getToken();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    setCancelStatus(true);
    notifyListeners();

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
        setRefreshingOrders(false); // Clear selected order IDs
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

  Future<void> fetchPaginatedOrdersB2C(int page) async {
    await fetchOrders('B2C', page);
  }

  // Fetch orders based on type (B2B or B2C)
  Future<void> fetchOrders(String type, int page) async {
    String? token = await _getToken();
    if (token == null) {
      print('Token is null, unable to fetch orders.');
      return;
    }

    String url =
        'https://inventory-management-backend-s37u.onrender.com/orders?filter=$type&orderStatus=3&page=$page';

    try {
      // Set loading state based on order type
      if (type == 'B2B') {
        isLoadingB2B = true;
        setRefreshingOrders(true);
      } else {
        isLoadingB2C = true;
        setRefreshingOrders(true);
      }
      notifyListeners();

      // Clear checkboxes when a new page is fetched
      clearAllSelections();

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

        // Store fetched orders and update pagination state
        if (type == 'B2B') {
          ordersB2B = orders;
          currentPageB2B = page; // Track current page for B2B
          totalPagesB2B =
              jsonResponse['totalPages']; // Assuming API returns total pages
        } else {
          ordersB2C = orders;
          currentPageB2C = page; // Track current page for B2C
          totalPagesB2C =
              jsonResponse['totalPages']; // Assuming API returns total pages
        }
      } else if (response.statusCode == 401) {
        print('Unauthorized access - Token might be expired or invalid.');
      } else if (response.statusCode == 404) {
        print('Orders not found - Check the filter type.');
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching $type orders: $e');
    } finally {
      // Reset loading states
      if (type == 'B2B') {
        isLoadingB2B = false;
        setRefreshingOrders(false);
      } else {
        isLoadingB2C = false;
        setRefreshingOrders(false);
      }
      notifyListeners();
    }
  }

  Future<void> fetchBookedOrders(int page) async {
    String? token = await _getToken();
    if (token == null) {
      print('Token is null, unable to fetch orders.');
      return;
    }

    String url =
        'https://inventory-management-backend-s37u.onrender.com/orders?isBooked=true&page=$page';

    try {
      // Set loading state based on order type
      isLoadingBooked = true;
      setRefreshingBookedOrders(true);
      notifyListeners();

      clearAllSelections();

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // Log response for debugging
      log('Response status: ${response.statusCode}');
      log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        List<Order> orders = (jsonResponse['orders'] as List)
            .map((orderJson) => Order.fromJson(orderJson))
            .toList();

        Logger().e(jsonResponse['orders'][0]['isBooked']['status']);

        ordersBooked = orders;
        currentPageBooked = page;
        totalPagesBooked = jsonResponse['totalPages'];
      } else if (response.statusCode == 401) {
        print('Unauthorized access - Token might be expired or invalid.');
      } else if (response.statusCode == 404) {
        print('Orders not found');
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching orders: $e');
    } finally {
      isLoadingBooked = false;
      setRefreshingBookedOrders(false);
      notifyListeners();
    }
  }

  // Function to book orders
  Future<String> bookOrders(BuildContext context, List<String> orderIds,
      String lowerCase, String provider) async {
    setLoading(provider, true);
    const String baseUrl =
        'https://inventory-management-backend-s37u.onrender.com';
    const String bookOrderUrl = '$baseUrl/orders/book';
    final String? token = await _getToken();

    if (token == null) {
      setLoading(provider, false);
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
      'service': lowerCase,
    });
    log(body);

    try {
      // Make the POST request to book the orders
      final response = await http.post(
        Uri.parse(bookOrderUrl),
        headers: headers,
        body: body,
      );

      // Log response status and body
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Parse the response
      final responseData = json.decode(response.body);

      // Check if the response is successful
      if (response.statusCode == 200) {
        // Optionally, you can also clear the selected orders here
        clearAllSelections();
        setLoading(provider, false);
        // Notify listeners after successful booking
        notifyListeners();
        return responseData['message'] ?? 'Orders booked successfully';
      } else {
        // If the API returns an error, return the error message
        setLoading(provider, false);
        return responseData['message'] ?? 'Failed to book orders';
      }
    } catch (error) {
      print('Error during API request: $error');
      setLoading(provider, false);
      return 'An error occurred: $error';
    }
  }

  // Get the auth token from SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // Update search query and notify listeners
  void onSearchChanged() {
    print('Search query: ${searchController.text}');
    notifyListeners();
  }

  // Handle individual row checkbox change
  void handleRowCheckboxChange(String? orderId, bool isSelected, bool isB2B) {
    int index;
    if (isB2B) {
      index = ordersB2B.indexWhere((order) => order.orderId == orderId);
      if (index != -1) {
        selectedB2BItems[index] = isSelected;
        ordersB2B[index].isSelected = isSelected;
      }
    } else {
      index = ordersB2C.indexWhere((order) => order.orderId == orderId);
      if (index != -1) {
        selectedB2CItems[index] = isSelected;
        ordersB2C[index].isSelected = isSelected;
      }
    }
    _updateSelectAllState(isB2B);
    notifyListeners();
  }

  void handleRowCheckboxChangeBooked(String? orderId, bool isSelected) {
    int index;
    index = ordersBooked.indexWhere((order) => order.orderId == orderId);
    if (index != -1) {
      selectedBookedItems[index] = isSelected;
      ordersBooked[index].isSelected = isSelected;
    }

    selectAllBooked = selectedBookedItems.every((item) => item);
    // _updateSelectAllState(isB2B);
    notifyListeners();
  }

  // Update the select all state based on selected items
  void _updateSelectAllState(bool isB2B) {
    if (isB2B) {
      selectAllB2B = selectedB2BItems.every((item) => item);
    } else {
      selectAllB2C = selectedB2CItems.every((item) => item);
    }
    notifyListeners();
  }

  // Toggle select all checkboxes
  void toggleSelectAll(bool isB2B, bool? value) {
    if (isB2B) {
      selectAllB2B = value!;
      selectedB2BItems.fillRange(0, selectedB2BItems.length, selectAllB2B);
      // Update the selection state for B2B orders
      for (int i = 0; i < ordersB2B.length; i++) {
        ordersB2B[i].isSelected = selectAllB2B;
      }
    } else {
      selectAllB2C = value!;
      selectedB2CItems.fillRange(0, selectedB2CItems.length, selectAllB2C);
      // Update the selection state for B2C orders
      for (int i = 0; i < ordersB2C.length; i++) {
        ordersB2C[i].isSelected = selectAllB2C;
      }
    }
    notifyListeners();
  }

  void toggleBookedSelectAll(bool? value) {
    selectAllBooked = value!;
    selectedBookedItems.fillRange(
        0, selectedBookedItems.length, selectAllBooked);
    // Update the selection state for B2B orders
    for (int i = 0; i < ordersBooked.length; i++) {
      ordersBooked[i].isSelected = selectAllBooked;
    }

    notifyListeners();
  }

  // Clear all checkboxes when the page is changed
  void clearAllSelections() {
    selectedB2BItems.fillRange(0, selectedB2BItems.length, false);
    selectedB2CItems.fillRange(0, selectedB2CItems.length, false);
    selectAllB2B = false;
    selectAllB2C = false;
    notifyListeners();
  }

  void clearSearchResults() {
    ordersB2B = B2BOrders;
    ordersB2C = B2COrders;
    ordersBooked = BookedOrders;
    notifyListeners();
  }

  Future<void> searchB2BOrders(String orderId) async {
    final url = Uri.parse(
        'https://inventory-management-backend-s37u.onrender.com/orders?orderStatus=3&filter=B2B&order_id=$orderId');
    final token = await _getToken();
    if (token == null) return;

    try {
      isLoadingB2B = true;
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

        ordersB2B = [Order.fromJson(data)];
        print(response.body);
      } else {
        ordersB2B = [];
      }
    } catch (e) {
      ordersB2B = [];
    } finally {
      isLoadingB2B = false;
      notifyListeners();
    }
  }

  Future<void> searchB2COrders(String orderId) async {
    final url = Uri.parse(
        'https://inventory-management-backend-s37u.onrender.com/orders?orderStatus=3&filter=B2C&order_id=$orderId');
    final token = await _getToken();
    if (token == null) return;

    try {
      isLoadingB2C = true;
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

        ordersB2C = [Order.fromJson(data)];
        print(response.body);
      } else {
        ordersB2C = [];
      }
    } catch (e) {
      ordersB2C = [];
    } finally {
      isLoadingB2C = false;
      notifyListeners();
    }
  }

  Future<void> searchBookedOrders(String orderId) async {
    final url = Uri.parse(
        'https://inventory-management-backend-s37u.onrender.com/orders?isBooked=true&order_id=$orderId');
    final token = await _getToken();
    if (token == null) return;

    try {
      isLoadingBooked = true;
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

        ordersBooked = [Order.fromJson(data)];
        print(response.body);
      } else {
        ordersBooked = [];
      }
    } catch (e) {
      ordersBooked = [];
    } finally {
      isLoadingBooked = false;
      notifyListeners();
    }
  }

  // Add this method to the BookProvider class
  Future<void> generatePicklist(
      BuildContext context, String marketplace) async {
    // Get the current time in ISO 8601 format
    String currentTime = DateTime.now().toIso8601String();

    log("currentTime: $currentTime");
    log("marketplace: $marketplace");

    const String baseUrl =
        'https://inventory-management-backend-s37u.onrender.com';
    String url =
        '$baseUrl/order-picker?currentTime=$currentTime&marketplace=$marketplace';

    String? token = await _getToken();
    if (token == null) {
      print('Token is null, unable to fetch order picker data.');
      return;
    }

    try {
      // Make the GET request
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // Log response for debugging
      log('Status: ${response.statusCode}');
      log('Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Handle the successful response
        // Process the data as needed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['error']['message']),
            backgroundColor: AppColors.cardsred,
          ),
        );
        log("data: $data");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['error']['message']),
            backgroundColor: AppColors.cardsred,
          ),
        );
        print('Failed to post order picker data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error posting order picker data: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> fetchOrdersByMarketplace(
      String marketplace, String type, int page) async {
    log("$marketplace, $type, $page");
    const String baseUrl =
        'https://inventory-management-backend-s37u.onrender.com/orders';
    String url =
        '$baseUrl?orderStatus=3&marketplace=$marketplace&filter=$type&page=$page';

    String? token =
        await _getToken(); // Assuming you have a method to get the token
    if (token == null) {
      print('Token is null, unable to fetch orders.');
      return;
    }

    try {
      // Set loading state based on order type
      if (type == 'B2B') {
        isLoadingB2B = true;
        setRefreshingOrders(true);
      } else {
        isLoadingB2C = true;
        setRefreshingOrders(true);
      }
      notifyListeners();

      // Clear checkboxes when a new page is fetched
      clearAllSelections();

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // Log response for debugging
      log('Response status: ${response.statusCode}');
      log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        List<Order> orders = (jsonResponse['orders'] as List)
            .map((orderJson) => Order.fromJson(orderJson))
            .toList();

        Logger().e("length: ${orders.length}");

        // Store fetched orders and update pagination state
        if (type == 'B2B') {
          ordersB2B = orders;
          currentPageB2B = page; // Track current page for B2B
          totalPagesB2B =
              jsonResponse['totalPages']; // Assuming API returns total pages
        } else {
          ordersB2C = orders;
          currentPageB2C = page; // Track current page for B2C
          totalPagesB2C =
              jsonResponse['totalPages']; // Assuming API returns total pages
        }
      } else if (response.statusCode == 401) {
        print('Unauthorized access - Token might be expired or invalid.');
      } else if (response.statusCode == 404) {
        if (type == 'B2C') {
          ordersB2C = [];
          notifyListeners();
        } else {
          ordersB2B = [];
          notifyListeners();
        }

        log('Orders not found - Check the filter type.');
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching $type orders: $e');
    } finally {
      // Reset loading states
      if (type == 'B2B') {
        isLoadingB2B = false;
        setRefreshingOrders(false);
      } else {
        isLoadingB2C = false;
        setRefreshingOrders(false);
      }
      notifyListeners();
    }
  }

  Future<void> fetchBookedOrdersByMarketplace(
      String marketplace, int page) async {
    log("$marketplace, $page");
    const String baseUrl =
        'https://inventory-management-backend-s37u.onrender.com/orders';
    String url = '$baseUrl?isBooked=true&marketplace=$marketplace&page=$page';

    String? token =
        await _getToken(); // Assuming you have a method to get the token
    if (token == null) {
      print('Token is null, unable to fetch orders.');
      return;
    }

    try {
      isLoadingBooked = true;
      setRefreshingBookedOrders(true);
      notifyListeners();

      // Clear checkboxes when a new page is fetched
      clearAllSelections();

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // Log response for debugging
      log('Response status: ${response.statusCode}');
      log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        List<Order> orders = (jsonResponse['orders'] as List)
            .map((orderJson) => Order.fromJson(orderJson))
            .toList();

        Logger().e("length: ${orders.length}");

        ordersBooked = orders;
        currentPageBooked = page; // Track current page for B2B
        totalPagesBooked =
            jsonResponse['totalPages']; // Assuming API returns total pages
      } else if (response.statusCode == 401) {
        print('Unauthorized access - Token might be expired or invalid.');
      } else if (response.statusCode == 404) {
        ordersBooked = [];
        notifyListeners();

        log('Orders not found');
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching orders: $e');
    } finally {
      isLoadingBooked = false;
      setRefreshingBookedOrders(false);

      notifyListeners();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
