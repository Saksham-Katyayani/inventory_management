import 'package:flutter/material.dart';
import 'package:inventory_management/Widgets/product_details_card.dart';
import 'package:inventory_management/edit_order_page.dart';
import 'package:inventory_management/provider/ba_approve_provider.dart';
import 'package:provider/provider.dart';

import 'Custom-Files/colors.dart';
import 'Custom-Files/custom_pagination.dart';
import 'Custom-Files/loading_indicator.dart';
import 'Widgets/order_card.dart';
import 'model/orders_model.dart';

class BAApprovePage extends StatefulWidget {
  const BAApprovePage({super.key});

  @override
  State<BAApprovePage> createState() => _BAApprovePageState();
}

class _BAApprovePageState extends State<BAApprovePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BAApproveProvider>(context, listen: false)
          .fetchOrdersWithStatus2();
    });
  }

  void _onSearchButtonPressed() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      Provider.of<BAApproveProvider>(context, listen: false)
          .onSearchChanged(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BAApproveProvider>(
      builder: (context, baApproveProvider, child) {
        return Scaffold(
          backgroundColor: AppColors.white,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 200,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color.fromARGB(183, 6, 90, 216),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _searchController,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration(
                            hintText: 'Search by Order ID',
                            hintStyle: TextStyle(color: Colors.black),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Color.fromARGB(183, 6, 90, 216),
                            ),
                          ),
                          onChanged: (query) {
                            setState(() {});
                            if (query.isEmpty) {
                              baApproveProvider.fetchOrdersWithStatus2();
                            }
                          },
                          onTap: () {
                            setState(() {});
                          },
                          onSubmitted: (query) {
                            if (query.isNotEmpty) {
                              baApproveProvider.searchOrders(query);
                            }
                          },
                          onEditingComplete: () {
                            FocusScope.of(context).unfocus();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                      ),
                      onPressed: _searchController.text.isNotEmpty
                          ? _onSearchButtonPressed
                          : null,
                      child: const Text(
                        'Search',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 8),
                    // Refresh Button
                    Row(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                          ),
                          onPressed: () async {
                            await baApproveProvider.statusUpdate(context);
                          },
                          child: baApproveProvider.isUpdatingOrder
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Approve',
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.cardsred,
                          ),
                          // onPressed: () async {
                          //   await baApproveProvider.statusUpdate(context);
                          // },
                          onPressed: baApproveProvider.isCancel
                              ? null // Disable button while loading
                              : () async {
                                  final provider =
                                      Provider.of<BAApproveProvider>(context,
                                          listen: false);

                                  // Collect selected order IDs
                                  List<String> selectedOrderIds = provider
                                      .orders
                                      .asMap()
                                      .entries
                                      .where((entry) =>
                                          provider.selectedProducts[entry.key])
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
                                    String resultMessage =
                                        await provider.cancelOrders(
                                            context, selectedOrderIds);

                                    // Set loading status to false after operation completes
                                    provider.setCancelStatus(false);

                                    // Determine the background color based on the result
                                    Color snackBarColor;
                                    if (resultMessage.contains('success')) {
                                      snackBarColor =
                                          AppColors.green; // Success: Green
                                    } else if (resultMessage
                                            .contains('error') ||
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
                          child: baApproveProvider.isCancel
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Cancel Orders',
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                          ),
                          onPressed: baApproveProvider.isRefreshingOrders
                              ? null
                              : () async {
                                  await baApproveProvider
                                      .fetchOrdersWithStatus2();
                                },
                          child: baApproveProvider.isRefreshingOrders
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Refresh',
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const SizedBox(height: 8),
              _buildTableHeader(
                  baApproveProvider.orders.length, baApproveProvider),
              const SizedBox(height: 4),
              Expanded(
                child: Stack(
                  children: [
                    if (baApproveProvider.isLoading)
                      const Center(
                        child: LoadingAnimation(
                          icon: Icons.account_box_rounded,
                          beginColor: Color.fromRGBO(189, 189, 189, 1),
                          endColor: AppColors.primaryBlue,
                          size: 80.0,
                        ),
                      )
                    else if (baApproveProvider.orders.isEmpty)
                      const Center(
                        child: Text(
                          'No Orders Found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        itemCount: baApproveProvider.orders.length,
                        itemBuilder: (context, index) {
                          final order = baApproveProvider.orders[index];
                          final percentDelhivery = double.parse(
                              ((order.freightCharge!.delhivery! /
                                          order.totalAmount!) *
                                      100)
                                  .toStringAsFixed(2));
                          final percentShiprocket = double.parse(
                              ((order.freightCharge!.shiprocket! /
                                          order.totalAmount!) *
                                      100)
                                  .toStringAsFixed(2));

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
                                        value: baApproveProvider
                                            .selectedProducts[index],
                                        onChanged: (isSelected) {
                                          baApproveProvider
                                              .handleRowCheckboxChange(
                                                  index, isSelected!);
                                        },
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
                                            baApproveProvider
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
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  EditOrderPage(
                                                order: order,
                                                isBookPage: false,
                                              ),
                                            ),
                                          );
                                          if (result == true) {
                                            Provider.of<BAApproveProvider>(
                                                    context,
                                                    listen: false)
                                                .fetchOrdersWithStatus2();
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: AppColors.white,
                                          backgroundColor: AppColors.orange,
                                          textStyle: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        child: const Text(
                                          'Edit Order',
                                        ),
                                      ),
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
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12.0),
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              buildLabelValueRow('Payment Mode',
                                                  order.paymentMode ?? ''),
                                              buildLabelValueRow(
                                                  'Currency Code',
                                                  order.currencyCode ?? ''),
                                              buildLabelValueRow(
                                                  'COD Amount',
                                                  order.codAmount.toString() ??
                                                      ''),
                                              buildLabelValueRow(
                                                  'Prepaid Amount',
                                                  order.prepaidAmount
                                                          .toString() ??
                                                      ''),
                                              buildLabelValueRow('Coin',
                                                  order.coin.toString() ?? ''),
                                              buildLabelValueRow(
                                                  'Tax Percent',
                                                  order.taxPercent.toString() ??
                                                      ''),
                                              buildLabelValueRow('Courier Name',
                                                  order.courierName ?? ''),
                                              buildLabelValueRow('Order Type',
                                                  order.orderType ?? ''),
                                              buildLabelValueRow('Payment Bank',
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
                                              buildLabelValueRow(
                                                  'Filter', order.filter ?? ''),
                                              buildLabelValueRow(
                                                'Expected Delivery Date',
                                                order.expectedDeliveryDate !=
                                                        null
                                                    ? baApproveProvider
                                                        .formatDate(order
                                                            .expectedDeliveryDate!)
                                                    : '',
                                              ),
                                              buildLabelValueRow(
                                                  'Preferred Courier',
                                                  order.preferredCourier ?? ''),
                                              buildLabelValueRow(
                                                'Payment Date Time',
                                                order.paymentDateTime != null
                                                    ? baApproveProvider
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
                                                  order.microDealerOrder ?? ''),
                                              buildLabelValueRow(
                                                  'Fulfillment Type',
                                                  order.fulfillmentType ?? ''),
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
                                                  order.calcEntryNumber ?? ''),
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
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12.0,
                                                    color:
                                                        AppColors.primaryBlue),
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
                                                order.customer?.customerGstin ??
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
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12.0,
                                                    color:
                                                        AppColors.primaryBlue),
                                              ),
                                              buildLabelValueRow(
                                                'Address',
                                                [
                                                  order.shippingAddress
                                                      ?.address1,
                                                  order.shippingAddress
                                                      ?.address2,
                                                  order.shippingAddress?.city,
                                                  order.shippingAddress?.state,
                                                  order
                                                      .shippingAddress?.country,
                                                  order.shippingAddress?.pincode
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
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12.0,
                                                    color:
                                                        AppColors.primaryBlue),
                                              ),
                                              buildLabelValueRow(
                                                'Address',
                                                [
                                                  order
                                                      .billingAddress?.address1,
                                                  order
                                                      .billingAddress?.address2,
                                                  order.billingAddress?.city,
                                                  order.billingAddress?.state,
                                                  order.billingAddress?.country,
                                                  order.billingAddress?.pincode
                                                      ?.toString(),
                                                ]
                                                    .where((element) =>
                                                        element != null &&
                                                        element.isNotEmpty)
                                                    .join(', '),
                                              ),
                                              buildLabelValueRow(
                                                'Name',
                                                order.billingAddress?.firstName !=
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
                                                  order.billingAddress?.email ??
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
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text.rich(
                                          TextSpan(
                                            text: "Delhivery: ",
                                            children: [
                                              TextSpan(
                                                  text:
                                                      "Rs. ${order.freightCharge!.delhivery} ",
                                                  style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.normal,
                                                  )),
                                              TextSpan(
                                                text: "($percentDelhivery %)",
                                                style: TextStyle(
                                                  color: percentDelhivery > 20
                                                      ? AppColors.cardsred
                                                      : AppColors.green,
                                                  fontWeight: FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text.rich(
                                          TextSpan(
                                            text: "Shiprocket: ",
                                            children: [
                                              TextSpan(
                                                text:
                                                    "Rs. ${order.freightCharge!.shiprocket} ",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.normal,
                                                ),
                                              ),
                                              TextSpan(
                                                text: "($percentShiprocket %)",
                                                style: TextStyle(
                                                  color: percentShiprocket > 20
                                                      ? AppColors.cardsred
                                                      : AppColors.green,
                                                  fontWeight: FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ],
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
                  ],
                ),
              ),
              CustomPaginationFooter(
                currentPage: baApproveProvider.currentPage,
                totalPages: baApproveProvider.totalPages,
                buttonSize: 30,
                pageController: baApproveProvider.textEditingController,
                onFirstPage: () {
                  baApproveProvider.goToPage(1);
                },
                onLastPage: () {
                  baApproveProvider.goToPage(baApproveProvider.totalPages);
                },
                onNextPage: () {
                  if (baApproveProvider.currentPage <
                      baApproveProvider.totalPages) {
                    baApproveProvider
                        .goToPage(baApproveProvider.currentPage + 1);
                  }
                },
                onPreviousPage: () {
                  if (baApproveProvider.currentPage > 1) {
                    baApproveProvider
                        .goToPage(baApproveProvider.currentPage - 1);
                  }
                },
                onGoToPage: (page) {
                  baApproveProvider.goToPage(page);
                },
                onJumpToPage: () {
                  final page = int.tryParse(
                      baApproveProvider.textEditingController.text);
                  if (page != null &&
                      page > 0 &&
                      page <= baApproveProvider.totalPages) {
                    baApproveProvider.goToPage(page);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(
      Order order, int index, BAApproveProvider baApproveProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Checkbox(
            value: baApproveProvider
                .selectedProducts[index], // Accessing selected products
            onChanged: (isSelected) {
              baApproveProvider.handleRowCheckboxChange(index, isSelected!);
            },
          ),
          Expanded(
            flex: 5,
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween, // Space between elements
              children: [
                Expanded(
                  child:
                      OrderCard(order: order), // Your existing OrderCard widget
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // if (dispatchProvider.isReturning)
          //   Center(
          //     child: CircularProgressIndicator(), // Loading indicator
          //   ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(
      int totalCount, BAApproveProvider baApproveProvider) {
    return Container(
      color: Colors.grey[300],
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          Transform.scale(
            scale: 0.8,
            child: Checkbox(
              value: baApproveProvider.selectAll,
              onChanged: (value) {
                baApproveProvider.toggleSelectAll(value!);
              },
            ),
          ),
          Text(
            'Select All(${baApproveProvider.selectedCount})',
          ),
          buildHeader('ORDERS')
        ],
      ),
    );
  }

  Widget buildHeader(String title, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Center(
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget buildCell(Widget content, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
        child: Center(child: content),
      ),
    );
  }
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