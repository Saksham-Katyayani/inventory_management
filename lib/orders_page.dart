import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/Custom-Files/custom_pagination.dart';
import 'package:inventory_management/Custom-Files/loading_indicator.dart';
import 'package:inventory_management/Widgets/product_details_card.dart';
import 'package:inventory_management/edit_order_page.dart';
import 'package:inventory_management/provider/marketplace_provider.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/provider/orders_provider.dart';
// Import the separate provider
import 'package:inventory_management/Custom-Files/colors.dart';

class OrdersNewPage extends StatefulWidget {
  const OrdersNewPage({super.key});

  @override
  _OrdersNewPageState createState() => _OrdersNewPageState();
}

class _OrdersNewPageState extends State<OrdersNewPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _searchController;
  late TextEditingController _searchControllerReady;
  late TextEditingController _searchControllerFailed;
  final TextEditingController _pageController = TextEditingController();
  final TextEditingController pageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController = TextEditingController();
    _searchControllerReady = TextEditingController();
    _searchControllerFailed = TextEditingController();
    _tabController.addListener(() {
      // Reload data when the tab changes
      if (_tabController.indexIsChanging) {
        _reloadOrders();
        _searchController.clear();
        _searchControllerReady.clear();
        _searchControllerFailed.clear();
      }
    });

    context.read<MarketplaceProvider>().fetchMarketplaces();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchControllerReady.dispose();
    _searchControllerFailed.dispose();
    _pageController.dispose();
    pageController.dispose();
    super.dispose();
  }

  void _reloadOrders() {
    // Access the OrdersProvider and fetch orders again
    final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);
    ordersProvider.fetchReadyOrders(); // Fetch both orders
    ordersProvider.fetchFailedOrders();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => OrdersProvider()
        ..fetchFailedOrders(page: 1) // Fetch failed orders on initialization
        ..fetchReadyOrders(page: 1), // Fetch ready orders on initialization
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 0, // Removes space above the tabs
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: _buildTabBar(),
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(text: 'Ready to Confirm'),
        Tab(text: 'Failed Orders'),
      ],
      indicatorColor: Colors.blue,
      labelColor: Colors.black,
      unselectedLabelColor: Colors.grey,
    );
  }

  Widget _buildBody() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildReadyToConfirmTab(),
        _buildFailedOrdersTab(),
      ],
    );
  }

  Widget _buildReadyToConfirmTab() {
    return Consumer<OrdersProvider>(
      builder: (context, ordersProvider, child) {
        if (ordersProvider.isLoading) {
          return const Center(
            child: LoadingAnimation(
              icon: Icons.shopping_cart,
              beginColor: Color.fromRGBO(189, 189, 189, 1),
              endColor: AppColors.primaryGreen,
              size: 80.0,
            ),
          );
        }
        return Column(
          children: [
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: ordersProvider.allSelectedReady,
                      onChanged: (bool? value) {
                        ordersProvider.toggleSelectAllReady(value ?? false);
                      },
                    ),
                    Text(
                        'Select All (${ordersProvider.selectedReadyItemsCount})'),
                  ],
                ),
                Row(
                  children: [
                    Consumer<MarketplaceProvider>(
                      builder: (context, provider, child) {
                        return PopupMenuButton<String>(
                          tooltip: 'Filter by Marketplace',
                          onSelected: (String value) {
                            if (value == 'All') {
                              ordersProvider.fetchReadyOrders();
                            } else {
                              ordersProvider.fetchOrdersByMarketplace(
                                  value, 1, ordersProvider.currentPageReady);
                            }

                            log('Selected: $value');
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                            ...provider.marketplaces
                                .map((marketplace) => PopupMenuItem<String>(
                                      value: marketplace.name,
                                      child: Text(marketplace.name),
                                    )), // Fetched marketplaces
                            const PopupMenuItem<String>(
                              value: 'All', // Hardcoded marketplace
                              child: Text('All'),
                            ),
                          ],
                          child: const IconButton(
                            onPressed: null,
                            icon: Icon(
                              Icons.filter_alt_outlined,
                              size: 30,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                      ),
                      onPressed: ordersProvider.isConfirm
                          ? null // Disable button while loading
                          : () async {
                              final provider = Provider.of<OrdersProvider>(
                                  context,
                                  listen: false);

                              // Collect selected order IDs
                              List<String> selectedOrderIds = provider
                                  .readyOrders
                                  .asMap()
                                  .entries
                                  .where((entry) =>
                                      provider.selectedReadyOrders[entry.key])
                                  .map((entry) => entry.value.orderId)
                                  .toList();

                              if (selectedOrderIds.isEmpty) {
                                // Show an error message if no orders are selected
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No orders selected'),
                                    backgroundColor: AppColors.cardsred,
                                  ),
                                );
                              } else {
                                // Set loading status to true before starting the operation
                                provider.setConfirmStatus(true);

                                // Call confirmOrders method with selected IDs
                                String resultMessage = await provider
                                    .confirmOrders(context, selectedOrderIds);

                                // Set loading status to false after operation completes
                                provider.setConfirmStatus(false);

                                // Determine the background color based on the result
                                Color snackBarColor;
                                if (resultMessage.contains('success')) {
                                  snackBarColor =
                                      AppColors.green; // Success: Green
                                } else if (resultMessage.contains('error') ||
                                    resultMessage.contains('failed')) {
                                  snackBarColor =
                                      AppColors.cardsred; // Error: Red
                                } else {
                                  snackBarColor =
                                      AppColors.orange; // Other: Orange
                                }

                                // Show feedback based on the result
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(resultMessage),
                                    backgroundColor: snackBarColor,
                                  ),
                                );
                              }
                            },
                      child: ordersProvider.isConfirm
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white),
                            )
                          : const Text(
                              'Confirm Orders',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cardsred,
                      ),
                      onPressed: ordersProvider.isCancel
                          ? null // Disable button while loading
                          : () async {
                              final provider = Provider.of<OrdersProvider>(
                                  context,
                                  listen: false);

                              // Collect selected order IDs
                              List<String> selectedOrderIds = provider
                                  .readyOrders
                                  .asMap()
                                  .entries
                                  .where((entry) =>
                                      provider.selectedReadyOrders[entry.key])
                                  .map((entry) => entry.value.orderId)
                                  .toList();

                              if (selectedOrderIds.isEmpty) {
                                // Show an error message if no orders are selected
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No orders selected'),
                                    backgroundColor: AppColors.cardsred,
                                  ),
                                );
                              } else {
                                // Set loading status to true before starting the operation
                                provider.setCancelStatus(true);

                                // Call confirmOrders method with selected IDs
                                String resultMessage = await provider
                                    .cancelOrders(context, selectedOrderIds);

                                // Set loading status to false after operation completes
                                provider.setCancelStatus(false);

                                // Determine the background color based on the result
                                Color snackBarColor;
                                if (resultMessage.contains('success')) {
                                  snackBarColor =
                                      AppColors.green; // Success: Green
                                } else if (resultMessage.contains('error') ||
                                    resultMessage.contains('failed')) {
                                  snackBarColor =
                                      AppColors.cardsred; // Error: Red
                                } else {
                                  snackBarColor =
                                      AppColors.orange; // Other: Orange
                                }

                                // Show feedback based on the result
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(resultMessage),
                                    backgroundColor: snackBarColor,
                                  ),
                                );
                              }
                            },
                      child: ordersProvider.isCancel
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white),
                            )
                          : const Text(
                              'Cancel Orders',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                      ),
                      onPressed: () {
                        // Call fetchOrders method on refresh button press
                        Provider.of<OrdersProvider>(context, listen: false)
                            .fetchReadyOrders();
                        Provider.of<OrdersProvider>(context, listen: false)
                            .resetSelections();
                        ordersProvider.clearSearchResults();
                        print('Ready to Confirm Orders refreshed');
                      },
                      child: const Text('Refresh'),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 200,
                      height: 34,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.green,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchControllerReady,
                              decoration: InputDecoration(
                                prefixIcon: IconButton(
                                  icon: const Icon(
                                    Icons.search,
                                    color: Color.fromRGBO(117, 117, 117, 1),
                                  ),
                                  onPressed: () {
                                    final searchTerm =
                                        _searchControllerReady.text;
                                    ordersProvider
                                        .searchReadyToConfirmOrders(searchTerm);
                                  },
                                ),
                                hintText: 'Search Orders',
                                hintStyle: const TextStyle(
                                  color: Color.fromRGBO(117, 117, 117, 1),
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 10.0),
                              ),
                              style: const TextStyle(color: AppColors.black),
                              onSubmitted: (value) {
                                ordersProvider
                                    .searchReadyToConfirmOrders(value);
                              },
                              onChanged: (value) {
                                if (value.isEmpty) {
                                  ordersProvider.clearSearchResults();
                                }
                              },
                            ),
                          ),
                          if (_searchControllerReady.text.isNotEmpty)
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                color: Colors.grey.shade600,
                              ),
                              onPressed: () {
                                _searchControllerReady.clear();
                                ordersProvider.fetchReadyOrders();
                                ordersProvider.clearSearchResults();
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ordersProvider.isLoading
                  ? const Center(
                      child: LoadingAnimation(
                        icon: Icons.shopping_cart,
                        beginColor: Color.fromRGBO(189, 189, 189, 1),
                        endColor: AppColors.primaryGreen,
                        size: 80.0,
                      ),
                    )
                  : ordersProvider.filteredReadyOrders.isEmpty
                      ? const Center(
                          child: Text(
                            "No orders found",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: ordersProvider.filteredReadyOrders.length,
                          itemBuilder: (context, index) {
                            final order =
                                ordersProvider.filteredReadyOrders[index];

                            return Card(
                              surfaceTintColor: Colors.white,
                              color: const Color.fromARGB(255, 231, 230, 230),
                              elevation: 0.5,
                              margin: const EdgeInsets.all(8.0),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Checkbox(
                                          value: ordersProvider
                                              .selectedReadyOrders[index],
                                          onChanged: (value) => ordersProvider
                                              .toggleOrderSelectionReady(
                                                  value ?? false, index),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Order ID: ',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              order.orderId ?? 'N/A',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primaryBlue,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Date: ',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              ordersProvider
                                                  .formatDate(order.date!),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primaryBlue),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Total Amount: ',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              'Rs. ${order.totalAmount ?? ''}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primaryBlue),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Total Items: ',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              '${order.items.fold(0, (total, item) => total + item.qty!)}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primaryBlue),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Total Weight: ',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              '${order.totalWeight ?? ''}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primaryBlue),
                                            ),
                                          ],
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            // Handle edit order action here
                                            // provider.editOrder(order);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    EditOrderPage(
                                                  order: order,
                                                  isBookPage: false,
                                                ),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            foregroundColor: AppColors.white,
                                            backgroundColor: AppColors
                                                .orange, // Set the text color to white
                                            textStyle: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          child: const Text(
                                            'Edit Order',
                                          ),
                                        )
                                      ],
                                    ),
                                    const Divider(
                                      thickness: 1,
                                      color: AppColors.grey,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            child: const SizedBox(
                                              height: 50,
                                              width: 130,
                                              child: Text(
                                                'ORDER DETAILS:',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12.0),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                buildLabelValueRow(
                                                    'Payment Mode',
                                                    order.paymentMode ?? ''),
                                                buildLabelValueRow(
                                                    'Currency Code',
                                                    order.currencyCode ?? ''),
                                                buildLabelValueRow(
                                                    'COD Amount',
                                                    order.codAmount
                                                            .toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Prepaid Amount',
                                                    order.prepaidAmount
                                                            .toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Coin',
                                                    order.coin.toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Tax Percent',
                                                    order.taxPercent
                                                            .toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Courier Name',
                                                    order.courierName ?? ''),
                                                buildLabelValueRow('Order Type',
                                                    order.orderType ?? ''),
                                                buildLabelValueRow(
                                                    'Payment Bank',
                                                    order.paymentBank ?? ''),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12.0),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                buildLabelValueRow(
                                                    'Discount Amount',
                                                    order.discountAmount
                                                            .toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Discount Scheme',
                                                    order.discountScheme ?? ''),
                                                buildLabelValueRow(
                                                    'Agent', order.agent ?? ''),
                                                buildLabelValueRow(
                                                    'Notes', order.notes ?? ''),
                                                buildLabelValueRow(
                                                    'Marketplace',
                                                    order.marketplace?.name ??
                                                        ''),
                                                buildLabelValueRow('Filter',
                                                    order.filter ?? ''),
                                                buildLabelValueRow(
                                                  'Expected Delivery Date',
                                                  order.expectedDeliveryDate !=
                                                          null
                                                      ? ordersProvider
                                                          .formatDate(order
                                                              .expectedDeliveryDate!)
                                                      : '',
                                                ),
                                                buildLabelValueRow(
                                                    'Preferred Courier',
                                                    order.preferredCourier ??
                                                        ''),
                                                buildLabelValueRow(
                                                  'Payment Date Time',
                                                  order.paymentDateTime != null
                                                      ? ordersProvider
                                                          .formatDateTime(order
                                                              .paymentDateTime!)
                                                      : '',
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12.0),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                buildLabelValueRow(
                                                    'Delivery Term',
                                                    order.deliveryTerm ?? ''),
                                                buildLabelValueRow(
                                                    'Transaction Number',
                                                    order.transactionNumber ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Micro Dealer Order',
                                                    order.microDealerOrder ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Fulfillment Type',
                                                    order.fulfillmentType ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'No. of Boxes',
                                                    order.numberOfBoxes
                                                            .toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Total Quantity',
                                                    order.totalQuantity
                                                            .toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'SKU Qty',
                                                    order.skuQty.toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Calc Entry No.',
                                                    order.calcEntryNumber ??
                                                        ''),
                                                buildLabelValueRow('Currency',
                                                    order.currency ?? ''),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12.0),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                buildLabelValueRow(
                                                  'Dimensions',
                                                  '${order.length.toString() ?? ''} x ${order.breadth.toString() ?? ''} x ${order.height.toString() ?? ''}',
                                                ),
                                                buildLabelValueRow(
                                                    'Tracking Status',
                                                    order.trackingStatus ?? ''),
                                                const SizedBox(
                                                  height: 7,
                                                ),
                                                const Text(
                                                  'Customer Details:',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12.0,
                                                      color: AppColors
                                                          .primaryBlue),
                                                ),
                                                buildLabelValueRow(
                                                  'Customer ID',
                                                  order.customer?.customerId ??
                                                      '',
                                                ),
                                                buildLabelValueRow(
                                                    'Full Name',
                                                    order.customer?.firstName !=
                                                            order.customer
                                                                ?.lastName
                                                        ? '${order.customer?.firstName ?? ''} ${order.customer?.lastName ?? ''}'
                                                            .trim()
                                                        : order.customer
                                                                ?.firstName ??
                                                            ''),
                                                buildLabelValueRow(
                                                  'Email',
                                                  order.customer?.email ?? '',
                                                ),
                                                buildLabelValueRow(
                                                  'Phone',
                                                  order.customer?.phone
                                                          ?.toString() ??
                                                      '',
                                                ),
                                                buildLabelValueRow(
                                                  'GSTIN',
                                                  order.customer
                                                          ?.customerGstin ??
                                                      '',
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12.0),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Shipping Address:',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12.0,
                                                      color: AppColors
                                                          .primaryBlue),
                                                ),
                                                buildLabelValueRow(
                                                  'Address',
                                                  [
                                                    order.shippingAddress
                                                        ?.address1,
                                                    order.shippingAddress
                                                        ?.address2,
                                                    order.shippingAddress?.city,
                                                    order
                                                        .shippingAddress?.state,
                                                    order.shippingAddress
                                                        ?.country,
                                                    order.shippingAddress
                                                        ?.pincode
                                                        ?.toString(),
                                                  ]
                                                      .where((element) =>
                                                          element != null &&
                                                          element.isNotEmpty)
                                                      .join(', '),
                                                ),
                                                buildLabelValueRow(
                                                  'Name',
                                                  order.shippingAddress
                                                              ?.firstName !=
                                                          order.shippingAddress
                                                              ?.lastName
                                                      ? '${order.shippingAddress?.firstName ?? ''} ${order.shippingAddress?.lastName ?? ''}'
                                                          .trim()
                                                      : order.shippingAddress
                                                              ?.firstName ??
                                                          '',
                                                ),
                                                buildLabelValueRow(
                                                    'Phone',
                                                    order.shippingAddress?.phone
                                                            ?.toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Email',
                                                    order.shippingAddress
                                                            ?.email ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Country Code',
                                                    order.shippingAddress
                                                            ?.countryCode ??
                                                        ''),
                                                const SizedBox(height: 8.0),
                                                const Text(
                                                  'Billing Address:',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12.0,
                                                      color: AppColors
                                                          .primaryBlue),
                                                ),
                                                buildLabelValueRow(
                                                  'Address',
                                                  [
                                                    order.billingAddress
                                                        ?.address1,
                                                    order.billingAddress
                                                        ?.address2,
                                                    order.billingAddress?.city,
                                                    order.billingAddress?.state,
                                                    order.billingAddress
                                                        ?.country,
                                                    order
                                                        .billingAddress?.pincode
                                                        ?.toString(),
                                                  ]
                                                      .where((element) =>
                                                          element != null &&
                                                          element.isNotEmpty)
                                                      .join(', '),
                                                ),
                                                buildLabelValueRow(
                                                  'Name',
                                                  order.billingAddress
                                                              ?.firstName !=
                                                          order.billingAddress
                                                              ?.lastName
                                                      ? '${order.billingAddress?.firstName ?? ''} ${order.billingAddress?.lastName ?? ''}'
                                                          .trim()
                                                      : order.billingAddress
                                                              ?.firstName ??
                                                          '',
                                                ),
                                                buildLabelValueRow(
                                                    'Phone',
                                                    order.billingAddress?.phone
                                                            ?.toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Email',
                                                    order.billingAddress
                                                            ?.email ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Country Code',
                                                    order.billingAddress
                                                            ?.countryCode ??
                                                        ''),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text.rich(
                                        TextSpan(
                                            text: "Updated at: ",
                                            children: [
                                              TextSpan(
                                                  text: DateFormat(
                                                          'dd-MM-yyyy\',\' hh:mm a')
                                                      .format(
                                                    DateTime.parse(
                                                        "${order.updatedAt}"),
                                                  ),
                                                  style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.normal,
                                                  )),
                                            ],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            )),
                                      ),
                                    ),
                                    const Divider(
                                      thickness: 1,
                                      color: AppColors.grey,
                                    ),
                                    // Nested cards for each item in the order
                                    const SizedBox(height: 6),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: order.items.length,
                                      itemBuilder: (context, itemIndex) {
                                        final item = order.items[itemIndex];

                                        return OrderItemCard(
                                          item: item,
                                          index: itemIndex,
                                          courierName: order.courierName,
                                          orderStatus:
                                              order.orderStatus.toString(),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            CustomPaginationFooter(
              currentPage: ordersProvider.currentPageReady,
              totalPages: ordersProvider.totalReadyPages,
              buttonSize: 30,
              pageController: pageController,
              onFirstPage: () {
                ordersProvider.fetchReadyOrders(page: 1);
              },
              onLastPage: () {
                ordersProvider.fetchReadyOrders(
                    page: ordersProvider.totalReadyPages);
              },
              onNextPage: () {
                if (ordersProvider.currentPageReady <
                    ordersProvider.totalReadyPages) {
                  ordersProvider.fetchReadyOrders(
                      page: ordersProvider.currentPageReady + 1);
                }
              },
              onPreviousPage: () {
                if (ordersProvider.currentPageReady > 1) {
                  ordersProvider.fetchReadyOrders(
                      page: ordersProvider.currentPageReady - 1);
                }
              },
              onGoToPage: (page) {
                if (page > 0 && page <= ordersProvider.totalReadyPages) {
                  ordersProvider.fetchReadyOrders(page: page);
                }
              },
              onJumpToPage: () {
                final int? page = int.tryParse(pageController.text);

                if (page == null ||
                    page < 1 ||
                    page > ordersProvider.totalReadyPages) {
                  _showSnackbar(context,
                      'Please enter a valid page number between 1 and ${ordersProvider.totalReadyPages}.');
                  return;
                }

                ordersProvider.fetchReadyOrders(page: page);
                pageController.clear();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildFailedOrdersTab() {
    return Consumer<OrdersProvider>(
      builder: (context, ordersProvider, child) {
        if (ordersProvider.isLoading) {
          return const Center(
            child: LoadingAnimation(
              icon: Icons.shopping_cart,
              beginColor: Color.fromRGBO(189, 189, 189, 1),
              endColor: AppColors.primaryGreen,
              size: 80.0,
            ),
          );
        }
        return Column(
          children: [
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: ordersProvider.allSelectedFailed,
                      onChanged: (bool? value) {
                        ordersProvider.toggleSelectAllFailed(value ?? false);
                      },
                    ),
                    Text(
                        'Select All (${ordersProvider.selectedFailedItemsCount})'),
                  ],
                ),
                Row(
                  children: [
                    Consumer<MarketplaceProvider>(
                      builder: (context, provider, child) {
                        return PopupMenuButton<String>(
                          tooltip: 'Filter by Marketplace',
                          onSelected: (String value) {
                            if (value == 'All') {
                              ordersProvider.fetchFailedOrders();
                            } else {
                              ordersProvider.fetchOrdersByMarketplace(
                                  value, 0, ordersProvider.currentPageFailed);
                            }
                            log('Selected: $value');
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                            ...provider.marketplaces
                                .map((marketplace) => PopupMenuItem<String>(
                                      value: marketplace.name,
                                      child: Text(marketplace.name),
                                    )), // Fetched marketplaces
                            const PopupMenuItem<String>(
                              value: 'All', // Hardcoded marketplace
                              child: Text('All'),
                            ),
                          ],
                          child: const IconButton(
                            onPressed: null,
                            icon: Icon(
                              Icons.filter_alt_outlined,
                              size: 30,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                      ),
                      onPressed: ordersProvider.isUpdating
                          ? null
                          : () async {
                              ordersProvider.setUpdating(true);
                              await ordersProvider.updateFailedOrders(context);
                              ordersProvider.setUpdating(false);
                            },
                      child: ordersProvider.isUpdating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white),
                            )
                          : const Text(
                              'Approve Failed Orders',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cardsred,
                      ),
                      onPressed: ordersProvider.isCancel
                          ? null // Disable button while loading
                          : () async {
                              final provider = Provider.of<OrdersProvider>(
                                  context,
                                  listen: false);

                              // Collect selected order IDs
                              List<String> selectedOrderIds = provider
                                  .failedOrders
                                  .asMap()
                                  .entries
                                  .where((entry) =>
                                      provider.selectedFailedOrders[entry.key])
                                  .map((entry) => entry.value.orderId)
                                  .toList();

                              if (selectedOrderIds.isEmpty) {
                                // Show an error message if no orders are selected
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No orders selected'),
                                    backgroundColor: AppColors.cardsred,
                                  ),
                                );
                              } else {
                                // Set loading status to true before starting the operation
                                provider.setCancelStatus(true);

                                // Call confirmOrders method with selected IDs
                                String resultMessage = await provider
                                    .cancelOrders(context, selectedOrderIds);

                                // Set loading status to false after operation completes
                                provider.setCancelStatus(false);

                                // Determine the background color based on the result
                                Color snackBarColor;
                                if (resultMessage.contains('success')) {
                                  snackBarColor =
                                      AppColors.green; // Success: Green
                                } else if (resultMessage.contains('error') ||
                                    resultMessage.contains('failed')) {
                                  snackBarColor =
                                      AppColors.cardsred; // Error: Red
                                } else {
                                  snackBarColor =
                                      AppColors.orange; // Other: Orange
                                }

                                // Show feedback based on the result
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(resultMessage),
                                    backgroundColor: snackBarColor,
                                  ),
                                );
                              }
                            },
                      child: ordersProvider.isCancel
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white),
                            )
                          : const Text(
                              'Cancel Orders',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                      ),
                      onPressed: () {
                        // Call fetchOrders method on refresh button press
                        Provider.of<OrdersProvider>(context, listen: false)
                            .fetchFailedOrders();
                        Provider.of<OrdersProvider>(context, listen: false)
                            .resetSelections();
                        ordersProvider.clearSearchResults();

                        print('Failed Orders refreshed');
                      },
                      child: const Text('Refresh'),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 200,
                      height: 34,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.green,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchControllerFailed,
                              decoration: InputDecoration(
                                prefixIcon: IconButton(
                                  icon: const Icon(
                                    Icons.search,
                                    color: Color.fromRGBO(117, 117, 117, 1),
                                  ),
                                  onPressed: () {
                                    final searchTerm =
                                        _searchControllerFailed.text;
                                    ordersProvider
                                        .searchFailedOrders(searchTerm);
                                  },
                                ),
                                hintText: 'Search Orders',
                                hintStyle: const TextStyle(
                                  color: Color.fromRGBO(117, 117, 117, 1),
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 10.0),
                              ),
                              style: const TextStyle(color: Colors.white),
                              onSubmitted: (value) {
                                ordersProvider.searchFailedOrders(value);
                              },
                              onChanged: (value) {
                                if (value.isEmpty) {
                                  ordersProvider.clearSearchResults();
                                }
                              },
                            ),
                          ),
                          if (_searchControllerFailed.text.isNotEmpty)
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                color: Colors.grey.shade600,
                              ),
                              onPressed: () {
                                _searchControllerFailed.clear();
                                ordersProvider.fetchFailedOrders();
                                ordersProvider.clearSearchResults();
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ordersProvider.isLoading
                  ? const Center(
                      child: LoadingAnimation(
                        icon: Icons.shopping_cart,
                        beginColor: Color.fromRGBO(189, 189, 189, 1),
                        endColor: AppColors.primaryGreen,
                        size: 80.0,
                      ),
                    )
                  : ordersProvider.filteredFailedOrders.isEmpty
                      ? const Center(
                          child: Text(
                            "No orders found",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: ordersProvider.filteredFailedOrders.length,
                          itemBuilder: (context, index) {
                            final order =
                                ordersProvider.filteredFailedOrders[index];

                            return Card(
                              surfaceTintColor: Colors.white,
                              color: const Color.fromARGB(255, 231, 230, 230),
                              elevation: 0.5,
                              margin: const EdgeInsets.all(8.0),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Checkbox(
                                          value: ordersProvider
                                              .selectedFailedOrders[index],
                                          onChanged: (value) => ordersProvider
                                              .toggleOrderSelectionFailed(
                                                  value ?? false, index),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Order ID: ',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              order.orderId ?? 'N/A',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primaryBlue,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Date: ',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              ordersProvider
                                                  .formatDate(order.date!),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primaryBlue),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Total Amount: ',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              'Rs. ${order.totalAmount ?? ''}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primaryBlue),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Total Items: ',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              '${order.items.fold(0, (total, item) => total + item.qty!)}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primaryBlue),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Total Weight: ',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              '${order.totalWeight ?? ''}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primaryBlue),
                                            ),
                                          ],
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            // Handle edit order action here
                                            // provider.editOrder(order);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    EditOrderPage(
                                                  order: order,
                                                  isBookPage: false,
                                                ),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            foregroundColor: AppColors.white,
                                            backgroundColor: AppColors
                                                .orange, // Set the text color to white
                                            textStyle: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          child: const Text(
                                            'Edit Order',
                                          ),
                                        )
                                      ],
                                    ),
                                    const Divider(
                                      thickness: 1,
                                      color: AppColors.grey,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            child: const SizedBox(
                                              height: 50,
                                              width: 130,
                                              child: Text(
                                                'ORDER DETAILS:',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12.0),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                buildLabelValueRow(
                                                    'Payment Mode',
                                                    order.paymentMode ?? ''),
                                                buildLabelValueRow(
                                                    'Currency Code',
                                                    order.currencyCode ?? ''),
                                                buildLabelValueRow(
                                                    'COD Amount',
                                                    order.codAmount
                                                            .toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Prepaid Amount',
                                                    order.prepaidAmount
                                                            .toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Coin',
                                                    order.coin.toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Tax Percent',
                                                    order.taxPercent
                                                            .toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Courier Name',
                                                    order.courierName ?? ''),
                                                buildLabelValueRow('Order Type',
                                                    order.orderType ?? ''),
                                                buildLabelValueRow(
                                                    'Payment Bank',
                                                    order.paymentBank ?? ''),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12.0),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                buildLabelValueRow(
                                                    'Discount Amount',
                                                    order.discountAmount
                                                            .toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Discount Scheme',
                                                    order.discountScheme ?? ''),
                                                buildLabelValueRow(
                                                    'Agent', order.agent ?? ''),
                                                buildLabelValueRow(
                                                    'Notes', order.notes ?? ''),
                                                buildLabelValueRow(
                                                    'Marketplace',
                                                    order.marketplace?.name ??
                                                        ''),
                                                buildLabelValueRow('Filter',
                                                    order.filter ?? ''),
                                                buildLabelValueRow(
                                                  'Expected Delivery Date',
                                                  order.expectedDeliveryDate !=
                                                          null
                                                      ? ordersProvider
                                                          .formatDate(order
                                                              .expectedDeliveryDate!)
                                                      : '',
                                                ),
                                                buildLabelValueRow(
                                                    'Preferred Courier',
                                                    order.preferredCourier ??
                                                        ''),
                                                buildLabelValueRow(
                                                  'Payment Date Time',
                                                  order.paymentDateTime != null
                                                      ? ordersProvider
                                                          .formatDateTime(order
                                                              .paymentDateTime!)
                                                      : '',
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12.0),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                buildLabelValueRow(
                                                    'Delivery Term',
                                                    order.deliveryTerm ?? ''),
                                                buildLabelValueRow(
                                                    'Transaction Number',
                                                    order.transactionNumber ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Micro Dealer Order',
                                                    order.microDealerOrder ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Fulfillment Type',
                                                    order.fulfillmentType ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'No. of Boxes',
                                                    order.numberOfBoxes
                                                            .toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Total Quantity',
                                                    order.totalQuantity
                                                            .toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'SKU Qty',
                                                    order.skuQty.toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Calc Entry No.',
                                                    order.calcEntryNumber ??
                                                        ''),
                                                buildLabelValueRow('Currency',
                                                    order.currency ?? ''),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12.0),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                buildLabelValueRow(
                                                  'Dimensions',
                                                  '${order.length.toString() ?? ''} x ${order.breadth.toString() ?? ''} x ${order.height.toString() ?? ''}',
                                                ),
                                                buildLabelValueRow(
                                                    'Tracking Status',
                                                    order.trackingStatus ?? ''),
                                                const SizedBox(
                                                  height: 7,
                                                ),
                                                const Text(
                                                  'Customer Details:',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12.0,
                                                      color: AppColors
                                                          .primaryBlue),
                                                ),
                                                buildLabelValueRow(
                                                  'Customer ID',
                                                  order.customer?.customerId ??
                                                      '',
                                                ),
                                                buildLabelValueRow(
                                                    'Full Name',
                                                    order.customer?.firstName !=
                                                            order.customer
                                                                ?.lastName
                                                        ? '${order.customer?.firstName ?? ''} ${order.customer?.lastName ?? ''}'
                                                            .trim()
                                                        : order.customer
                                                                ?.firstName ??
                                                            ''),
                                                buildLabelValueRow(
                                                  'Email',
                                                  order.customer?.email ?? '',
                                                ),
                                                buildLabelValueRow(
                                                  'Phone',
                                                  order.customer?.phone
                                                          ?.toString() ??
                                                      '',
                                                ),
                                                buildLabelValueRow(
                                                  'GSTIN',
                                                  order.customer
                                                          ?.customerGstin ??
                                                      '',
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12.0),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Shipping Address:',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12.0,
                                                      color: AppColors
                                                          .primaryBlue),
                                                ),
                                                buildLabelValueRow(
                                                  'Address',
                                                  [
                                                    order.shippingAddress
                                                        ?.address1,
                                                    order.shippingAddress
                                                        ?.address2,
                                                    order.shippingAddress?.city,
                                                    order
                                                        .shippingAddress?.state,
                                                    order.shippingAddress
                                                        ?.country,
                                                    order.shippingAddress
                                                        ?.pincode
                                                        ?.toString(),
                                                  ]
                                                      .where((element) =>
                                                          element != null &&
                                                          element.isNotEmpty)
                                                      .join(', '),
                                                ),
                                                buildLabelValueRow(
                                                  'Name',
                                                  order.shippingAddress
                                                              ?.firstName !=
                                                          order.shippingAddress
                                                              ?.lastName
                                                      ? '${order.shippingAddress?.firstName ?? ''} ${order.shippingAddress?.lastName ?? ''}'
                                                          .trim()
                                                      : order.shippingAddress
                                                              ?.firstName ??
                                                          '',
                                                ),
                                                buildLabelValueRow(
                                                    'Phone',
                                                    order.shippingAddress?.phone
                                                            ?.toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Email',
                                                    order.shippingAddress
                                                            ?.email ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Country Code',
                                                    order.shippingAddress
                                                            ?.countryCode ??
                                                        ''),
                                                const SizedBox(height: 8.0),
                                                const Text(
                                                  'Billing Address:',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12.0,
                                                      color: AppColors
                                                          .primaryBlue),
                                                ),
                                                buildLabelValueRow(
                                                  'Address',
                                                  [
                                                    order.billingAddress
                                                        ?.address1,
                                                    order.billingAddress
                                                        ?.address2,
                                                    order.billingAddress?.city,
                                                    order.billingAddress?.state,
                                                    order.billingAddress
                                                        ?.country,
                                                    order
                                                        .billingAddress?.pincode
                                                        ?.toString(),
                                                  ]
                                                      .where((element) =>
                                                          element != null &&
                                                          element.isNotEmpty)
                                                      .join(', '),
                                                ),
                                                buildLabelValueRow(
                                                  'Name',
                                                  order.billingAddress
                                                              ?.firstName !=
                                                          order.billingAddress
                                                              ?.lastName
                                                      ? '${order.billingAddress?.firstName ?? ''} ${order.billingAddress?.lastName ?? ''}'
                                                          .trim()
                                                      : order.billingAddress
                                                              ?.firstName ??
                                                          '',
                                                ),
                                                buildLabelValueRow(
                                                    'Phone',
                                                    order.billingAddress?.phone
                                                            ?.toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Email',
                                                    order.billingAddress
                                                            ?.email ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Country Code',
                                                    order.billingAddress
                                                            ?.countryCode ??
                                                        ''),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text.rich(
                                        TextSpan(
                                            text: "Updated at: ",
                                            children: [
                                              TextSpan(
                                                  text: DateFormat(
                                                          'dd-MM-yyyy\',\' hh:mm a')
                                                      .format(
                                                    DateTime.parse(
                                                        "${order.updatedAt}"),
                                                  ),
                                                  style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.normal,
                                                  )),
                                            ],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            )),
                                      ),
                                    ),
                                    const Divider(
                                      thickness: 1,
                                      color: AppColors.grey,
                                    ),
                                    // Nested cards for each item in the order
                                    const SizedBox(height: 10),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: order.items.length,
                                      itemBuilder: (context, itemIndex) {
                                        final item = order.items[itemIndex];

                                        return OrderItemCard(
                                          item: item,
                                          index: itemIndex,
                                          courierName: order.courierName,
                                          orderStatus:
                                              order.orderStatus.toString(),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            CustomPaginationFooter(
              currentPage: ordersProvider.currentPageFailed,
              totalPages: ordersProvider.totalFailedPages,
              buttonSize: 30,
              pageController: _pageController,
              onFirstPage: () {
                ordersProvider.fetchFailedOrders(page: 1);
              },
              onLastPage: () {
                ordersProvider.fetchFailedOrders(
                    page: ordersProvider.totalFailedPages);
              },
              onNextPage: () {
                if (ordersProvider.currentPageFailed <
                    ordersProvider.totalFailedPages) {
                  ordersProvider.fetchFailedOrders(
                      page: ordersProvider.currentPageFailed + 1);
                }
              },
              onPreviousPage: () {
                if (ordersProvider.currentPageFailed > 1) {
                  ordersProvider.fetchFailedOrders(
                      page: ordersProvider.currentPageFailed - 1);
                }
              },
              onGoToPage: (page) {
                if (page > 0 && page <= ordersProvider.totalFailedPages) {
                  ordersProvider.fetchFailedOrders(page: page);
                }
              },
              onJumpToPage: () {
                final int? page = int.tryParse(_pageController.text);

                if (page == null ||
                    page < 1 ||
                    page > ordersProvider.totalFailedPages) {
                  _showSnackbar(context,
                      'Please enter a valid page number between 1 and ${ordersProvider.totalFailedPages}.');
                  return;
                }

                ordersProvider.fetchFailedOrders(page: page);
                _pageController.clear();
              },
            ),
          ],
        );
      },
    );
  }
}

void _showSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

Widget buildLabelValueRow(String label, String? value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '$label: ',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12.0,
        ),
      ),
      Flexible(
        child: Text(
          value ?? '',
          softWrap: true,
          maxLines: null,
          style: const TextStyle(
            fontSize: 12.0,
          ),
        ),
      ),
    ],
  );
}
