import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/Api/auth_provider.dart';
import 'package:inventory_management/accounts_page.dart';
import 'package:inventory_management/ba_approve_page.dart';
import 'package:inventory_management/booked_page.dart';
import 'package:inventory_management/cancelled_orders.dart';
import 'package:inventory_management/combo_upload.dart';
import 'package:inventory_management/create_account.dart';
import 'package:inventory_management/inventory_upload.dart';
import 'package:inventory_management/invoice_page.dart';
import 'package:inventory_management/book_page.dart';
import 'package:inventory_management/combo_page.dart';
import 'package:inventory_management/create-label-page.dart';
import 'package:inventory_management/location_master.dart';
import 'package:inventory_management/login_page.dart';
import 'package:inventory_management/manage_inventory.dart';
import 'package:inventory_management/manifest_section.dart';
import 'package:inventory_management/marketplace_page.dart';
import 'package:inventory_management/category_master.dart';
import 'package:inventory_management/dashboard_cards.dart';
import 'package:inventory_management/checker_page.dart';
import 'package:inventory_management/label_upload.dart';
import 'package:inventory_management/manifest_page.dart';
import 'package:inventory_management/product_upload.dart';
import 'package:inventory_management/packer_page.dart';
import 'package:inventory_management/picker_page.dart';
import 'package:inventory_management/orders_page.dart';
import 'package:inventory_management/provider/dashboard_provider.dart';
import 'package:inventory_management/racked_page.dart';
import 'package:inventory_management/dispatch_order.dart';
import 'package:inventory_management/show-label-page.dart';
import 'package:inventory_management/uploadproduct-quantity.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Custom-Files/colors.dart';
import 'package:inventory_management/product_manager.dart';

class DashboardPage extends StatefulWidget {
  final String inventoryId;
  const DashboardPage({super.key, required this.inventoryId});

  @override
  // ignore: library_private_types_in_public_api
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String selectedDrawerItem = 'Dashboard';
  DateTime? selectedDate; // State variable to hold the selected date
  DateTime?
      lastUpdatedTime; // Make sure this is initialized properly in your actual code
  DateTime? previousDate;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String? userRole;

  @override
  void initState() {
    super.initState();
    lastUpdatedTime = DateTime.now();

    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final credentials = await context.read<AuthProvider>().getCredentials();
    setState(() {
      userRole = credentials['userRole'];
    });

    log("$userRole");
  }

  void _refreshData() {
    setState(() {
      lastUpdatedTime = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    // final provider = Provider.of<InventoryProvider>(context, listen: false);
    return SelectionArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isSmallScreen = constraints.maxWidth < 800;

          return Scaffold(
            key: _scaffoldKey,
            drawer: isSmallScreen
                ? SizedBox(
                    width: 220,
                    child: Drawer(
                      child: Container(
                        color: Colors.grey[200],
                        child: _buildDrawerContent(isSmallScreen),
                      ),
                    ),
                  )
                : null,
            body: Row(
              children: <Widget>[
                if (!isSmallScreen)
                  Container(
                    width: 200,
                    color: AppColors.lightGrey,
                    child: _buildDrawerContent(isSmallScreen),
                  ),
                Expanded(
                  child: Container(
                    color: AppColors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Row(
                          children: <Widget>[
                            if (isSmallScreen)
                              IconButton(
                                icon: const Icon(Icons.menu,
                                    color: AppColors.grey),
                                onPressed: () {
                                  _scaffoldKey.currentState?.openDrawer();
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: _buildMainContent(
                              selectedDrawerItem, isSmallScreen),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawerContent(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Image(
                  fit: BoxFit.cover,
                  image: AssetImage('assets/homeLogo.png'),
                ),
                const SizedBox(height: 20),
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  text: 'Dashboard',
                  isSelected: selectedDrawerItem == 'Dashboard',
                  onTap: () => _onDrawerItemTapped('Dashboard', isSmallScreen),
                ),
                _buildOrdersSection(
                  isSmallScreen,
                ),
                _buildInventorySection(isSmallScreen),
                _buildMasterSection(isSmallScreen),
                _buildAccountSection(isSmallScreen),
                _buildUploadSection(isSmallScreen),
                (userRole == 'superAdmin' || userRole == 'admin')
                    ? _buildDrawerItem(
                        icon: Icons.person,
                        text: 'Create Account',
                        isSelected: selectedDrawerItem == 'Create Account',
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const CreateAccountPage()));
                        },
                      )
                    : Container(),
                _buildDrawerItem(
                  icon: Icons.logout,
                  text: 'Logout',
                  isSelected: selectedDrawerItem == 'Logout',
                  onTap: () async {
                    try {
                      SharedPreferences pref =
                          await SharedPreferences.getInstance();
                      bool cleared = await pref.clear();

                      if (cleared) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Logout successful!'),
                            backgroundColor: AppColors.primaryGreen,
                          ),
                        );

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error: Could not clear session.'),
                            backgroundColor: AppColors.cardsred,
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('An error occurred during logout.'),
                          backgroundColor: AppColors.cardsred,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(
                  height: 100,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection(bool isSmallScreen) {
    return Theme(
      data: ThemeData(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20.0),
        collapsedBackgroundColor: ["Invoices"].contains(selectedDrawerItem)
            ? Colors.blue.withOpacity(0.2)
            : AppColors.white,
        title: Text(
          'Accounting',
          style: TextStyle(
            color: selectedDrawerItem == 'Accounting'
                ? AppColors.white
                : AppColors.primaryBlue,
            fontSize: 16,
          ),
        ),
        leading: Icon(
          Icons.analytics,
          color: selectedDrawerItem == 'Accounting'
              ? AppColors.white
              : AppColors.primaryBlue,
          size: 24,
        ),
        backgroundColor: selectedDrawerItem == 'Accounting'
            ? const Color.fromRGBO(6, 90, 216, 0.1)
            : null,
        children: <Widget>[
          Padding(
            padding:
                const EdgeInsets.only(left: 10.0), // Ensure consistent padding
            child: _buildDrawerItem(
              icon: Icons.account_balance_outlined,
              text: 'Invoices',
              isSelected: selectedDrawerItem == 'Invoices',
              onTap: () => userRole == 'confirmer' ||
                      userRole == 'account' ||
                      userRole == 'booker' ||
                      userRole == 'superAdmin' ||
                      userRole == 'admin'
                  ? _onDrawerItemTapped('Invoices', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
                    ),
              isIndented: true, // Pass the indentation flag
              iconSize: 20, // Adjust icon size
              fontSize: 14, // Adjust font size
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersSection(bool isSmallScreen) {
    return Theme(
      data: ThemeData(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20.0),
        collapsedBackgroundColor: [
          "Orders Page",
          "HOD Approval",
          "Accounts Page",
          "Book Page",
          "Booked Orders",
          "Picker Page",
          "Packer Page",
          "Checker Page",
          "Racked Page",
          "Manifest Page",
          "Manifest Section",
        ].contains(selectedDrawerItem)
            ? Colors.blue.withOpacity(0.2)
            : AppColors.white,
        title: Text(
          'Orders',
          style: TextStyle(
            color: selectedDrawerItem == 'Orders'
                ? AppColors.white
                : AppColors.primaryBlue,
            fontSize: 16,
          ),
        ),
        leading: Icon(
          Icons.shopping_cart,
          color: selectedDrawerItem == 'Orders'
              ? AppColors.white
              : AppColors.primaryBlue,
          size: 24,
        ),
        backgroundColor: selectedDrawerItem == 'Orders'
            ? const Color.fromRGBO(6, 90, 216, 0.1)
            : null,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.assignment_rounded,
              text: 'Orders',
              isSelected: selectedDrawerItem == 'Orders Page',
              onTap: () => userRole == 'confirmer' ||
                      userRole == 'superAdmin' ||
                      userRole == 'admin'
                  ? _onDrawerItemTapped('Orders Page', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.account_box_rounded,
              text: 'HOD Approval',
              isSelected: selectedDrawerItem == 'HOD Approval',
              onTap: () => userRole == 'superAdmin' || userRole == 'admin'
                  ? _onDrawerItemTapped('HOD Approval', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.account_box_rounded,
              text: 'Accounts',
              isSelected: selectedDrawerItem == 'Accounts Page',
              onTap: () => userRole == 'account' ||
                      userRole == 'superAdmin' ||
                      userRole == 'admin'
                  ? _onDrawerItemTapped('Accounts Page', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.menu_book,
              text: 'Book',
              isSelected: selectedDrawerItem == 'Book Page',
              onTap: () => userRole == 'booker' ||
                      userRole == 'superAdmin' ||
                      userRole == 'admin'
                  ? _onDrawerItemTapped('Book Page', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 30.0),
            child: _buildDrawerItem(
              icon: Icons.subdirectory_arrow_right,
              text: 'Booked Orders',
              isSelected: selectedDrawerItem == 'Booked Orders',
              onTap: () => userRole == 'booker' ||
                      userRole == 'superAdmin' ||
                      userRole == 'admin'
                  ? _onDrawerItemTapped('Booked Orders', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.local_shipping,
              text: 'Picker',
              isSelected: selectedDrawerItem == 'Picker Page',
              onTap: () => userRole == 'picker' ||
                      userRole == 'superAdmin' ||
                      userRole == 'admin'
                  ? _onDrawerItemTapped('Picker Page', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.backpack_rounded,
              text: 'Packer',
              isSelected: selectedDrawerItem == 'Packer Page',
              onTap: () => userRole == 'packer' ||
                      userRole == 'superAdmin' ||
                      userRole == 'admin'
                  ? _onDrawerItemTapped('Packer Page', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.check_circle,
              text: 'Checker',
              isSelected: selectedDrawerItem == 'Checker Page',
              onTap: () => userRole == 'checker' ||
                      userRole == 'superAdmin' ||
                      userRole == 'admin'
                  ? _onDrawerItemTapped('Checker Page', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.shelves,
              text: 'Racked',
              isSelected: selectedDrawerItem == 'Racked Page',
              onTap: () => userRole == 'racker' ||
                      userRole == 'superAdmin' ||
                      userRole == 'admin'
                  ? _onDrawerItemTapped('Racked Page', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.star,
              text: 'Manifest',
              isSelected: selectedDrawerItem == 'Manifest Page',
              onTap: () => userRole == 'manifest' ||
                      userRole == 'superAdmin' ||
                      userRole == 'admin'
                  ? _onDrawerItemTapped('Manifest Page', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 30.0),
            child: _buildDrawerItem(
              icon: Icons.subdirectory_arrow_right,
              text: 'Sub section',
              isSelected: selectedDrawerItem == 'Manifest Section',
              onTap: () => userRole == 'manifest' ||
                      userRole == 'superAdmin' ||
                      userRole == 'admin'
                  ? _onDrawerItemTapped('Manifest Section', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.assignment_return,
              text: 'Dispatched',
              isSelected: selectedDrawerItem == 'Dispatched',
              onTap: () => userRole == 'confirmer' ||
                      userRole == 'account' ||
                      userRole == 'booker' ||
                      userRole == 'superAdmin' ||
                      userRole == 'admin'
                  ? _onDrawerItemTapped('Dispatched', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.cancel,
              text: 'Cancelled',
              isSelected: selectedDrawerItem == 'Cancelled',
              onTap: () => userRole == 'confirmer' ||
                      userRole == 'account' ||
                      userRole == 'booker' ||
                      userRole == 'superAdmin' ||
                      userRole == 'admin'
                  ? _onDrawerItemTapped('Cancelled', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventorySection(bool isSmallScreen) {
    return Theme(
      data: ThemeData(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20.0),
        collapsedBackgroundColor:
            ["Manage Inventory"].contains(selectedDrawerItem)
                ? Colors.blue.withOpacity(0.2)
                : AppColors.white,
        title: Text(
          'Inventory',
          style: TextStyle(
            color: selectedDrawerItem == 'Inventory'
                ? AppColors.white
                : AppColors.primaryBlue,
            fontSize: 16,
          ),
        ),
        leading: Icon(
          Icons.inventory,
          color: selectedDrawerItem == 'Inventory'
              ? AppColors.white
              : AppColors.primaryBlue,
          size: 24,
        ),
        backgroundColor: selectedDrawerItem == 'Inventory'
            ? const Color.fromRGBO(6, 90, 216, 0.1)
            : null,
        children: <Widget>[
          Padding(
            padding:
                const EdgeInsets.only(left: 10.0), // Ensure consistent padding
            child: _buildDrawerItem(
              icon: Icons.production_quantity_limits,
              text: 'Manage Inventory',
              isSelected: selectedDrawerItem == 'Manage Inventory',
              onTap: () => userRole == 'confirmer' ||
                      userRole == 'account' ||
                      userRole == 'booker' ||
                      userRole == 'superAdmin' ||
                      userRole == 'admin'
                  ? _onDrawerItemTapped('Manage Inventory', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
                    ),
              isIndented: true, // Pass the indentation flag
              iconSize: 20, // Adjust icon size
              fontSize: 14, // Adjust font size
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterSection(bool isSmallScreen) {
    return Theme(
      data: ThemeData(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20.0),
        collapsedBackgroundColor: [
          "Label Page",
          "Create Label Page",
          "Product Master",
          "Category Master",
          "Combo Master",
          "Marketplace Master",
          "Location Master"
        ].contains(selectedDrawerItem)
            ? Colors.blue.withOpacity(0.2)
            : AppColors.white,
        title: Text(
          'Master',
          style: TextStyle(
            color: selectedDrawerItem == 'Master'
                ? AppColors.white
                : AppColors.primaryBlue,
            fontSize: 16,
          ),
        ),
        leading: Icon(
          Icons.pages,
          color: selectedDrawerItem == 'Master'
              ? AppColors.white
              : AppColors.primaryBlue,
          size: 24,
        ),
        backgroundColor: selectedDrawerItem == 'Master'
            ? const Color.fromRGBO(6, 90, 216, 0.1)
            : null,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.label_important,
              text: 'Label Master',
              isSelected: selectedDrawerItem == 'Label Page',
              onTap: () => userRole == 'confirmer' ||
                      userRole == 'account' ||
                      userRole == 'booker' ||
                      userRole == 'superAdmin' ||
                      userRole == 'admin'
                  ? _onDrawerItemTapped('Label Page', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          // Padding(
          //   padding: const EdgeInsets.only(left: 10.0),
          //   child: _buildDrawerItem(
          //     icon: Icons.production_quantity_limits,
          //     text: 'Create Label Page',
          //     isSelected: selectedDrawerItem == 'Create Label Page',
          //     onTap: () =>
          //         _onDrawerItemTapped('Create Label Page', isSmallScreen),
          //     isIndented: true,
          //     iconSize: 20,
          //     fontSize: 14,
          //   ),
          // ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.production_quantity_limits,
              text: 'Product Master',
              isSelected: selectedDrawerItem == 'Product Master',
              onTap: () => userRole == 'confirmer' ||
                      userRole == 'account' ||
                      userRole == 'booker' ||
                      userRole == 'superAdmin' ||
                      userRole == 'admin'
                  ? _onDrawerItemTapped('Product Master', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.category,
              text: 'Category Master',
              isSelected: selectedDrawerItem == 'Category Master',
              onTap: () => userRole == 'confirmer' ||
                      userRole == 'account' ||
                      userRole == 'booker' ||
                      userRole == 'superAdmin' ||
                      userRole == 'admin'
                  ? _onDrawerItemTapped('Category Master', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.list,
              text: 'Combo Master',
              isSelected: selectedDrawerItem == 'Combo Master',
              onTap: () => userRole == 'confirmer' ||
                      userRole == 'account' ||
                      userRole == 'booker' ||
                      userRole == 'superAdmin' ||
                      userRole == 'admin'
                  ? _onDrawerItemTapped('Combo Master', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.add_business,
              text: 'Marketplace Master',
              isSelected: selectedDrawerItem == 'Marketplace Master',
              onTap: () => userRole == 'confirmer' ||
                      userRole == 'account' ||
                      userRole == 'booker' ||
                      userRole == 'superAdmin' ||
                      userRole == 'admin'
                  ? _onDrawerItemTapped('Marketplace Master', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.warehouse,
              text: 'Location Master',
              isSelected: selectedDrawerItem == 'Location Master',
              onTap: () => userRole == 'confirmer' ||
                      userRole == 'account' ||
                      userRole == 'booker' ||
                      userRole == 'superAdmin' ||
                      userRole == 'admin'
                  ? _onDrawerItemTapped('Location Master', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection(bool isSmallScreen) {
    return Theme(
      data: ThemeData(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20.0),
        collapsedBackgroundColor: [
          "Upload Products",
          "Upload Labels",
          "Upload Inventory",
          "Upload Combo"
        ].contains(selectedDrawerItem)
            ? Colors.blue.withOpacity(0.2)
            : AppColors.white,
        title: Text(
          'Uploads',
          style: TextStyle(
            color: selectedDrawerItem == 'Uploads'
                ? AppColors.white
                : AppColors.primaryBlue,
            fontSize: 16,
          ),
        ),
        leading: Icon(
          Icons.upload_file,
          color: selectedDrawerItem == 'Uploads'
              ? AppColors.white
              : AppColors.primaryBlue,
          size: 24,
        ),
        backgroundColor: selectedDrawerItem == 'Uploads'
            ? const Color.fromRGBO(6, 90, 216, 0.1)
            : null,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.upload_file,
              text: 'Upload Products',
              isSelected: selectedDrawerItem == 'Upload Products',
              onTap: () => userRole == 'confirmer' ||
                      userRole == 'account' ||
                      userRole == 'booker' ||
                      userRole == 'superAdmin' ||
                      userRole == 'admin'
                  ? _onDrawerItemTapped('Upload Products', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.new_label,
              text: 'Upload Labels',
              isSelected: selectedDrawerItem == 'Upload Labels',
              onTap: () => userRole == 'confirmer' ||
                      userRole == 'account' ||
                      userRole == 'booker' ||
                      userRole == 'superAdmin' ||
                      userRole == 'admin'
                  ? _onDrawerItemTapped('Upload Labels', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.inventory,
              text: 'Upload Inventory',
              isSelected: selectedDrawerItem == 'Upload Inventory',
              onTap: () => userRole == 'confirmer' ||
                      userRole == 'account' ||
                      userRole == 'booker' ||
                      userRole == 'superAdmin' ||
                      userRole == 'admin'
                  ? _onDrawerItemTapped('Upload Inventory', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.inventory,
              text: 'Upload Combo',
              isSelected: selectedDrawerItem == 'Upload Combo',
              onTap: () => userRole == 'confirmer' ||
                      userRole == 'account' ||
                      userRole == 'booker' ||
                      userRole == 'superAdmin' ||
                      userRole == 'admin'
                  ? _onDrawerItemTapped('Upload Combo', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _onDrawerItemTapped(String item, bool isSmallScreen) {
    setState(() {
      selectedDrawerItem = item;
      if (isSmallScreen) {
        Navigator.pop(context);
      }
    });
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
    bool isIndented = false,
    double iconSize = 24,
    double fontSize = 16,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: isIndented ? 32.0 : 8.0),
      child: Container(
        decoration: isSelected
            ? BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.primaryBlueLight,
                    AppColors.primaryBlue,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(6),
              )
            : null,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
          leading: Icon(
            icon,
            color: isSelected ? AppColors.white : AppColors.primaryBlue,
            size: iconSize,
          ),
          title: Text(
            text,
            style: TextStyle(
              color: isSelected ? AppColors.white : AppColors.primaryBlue,
              fontSize: fontSize,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildMainContent(String selectedDrawerItem, bool isSmallScreen) {
    switch (selectedDrawerItem) {
      case 'Dashboard':
        return _buildDashboardContent(isSmallScreen);
      case 'Sales Orders':
        return const Center(child: Text("Sales Orders content goes here"));
      case 'Inventory':
        return const Center(child: Text("Inventory content goes here"));
      case 'Products':
        return const UploadProductSku();
      // return const Products();
      case 'Manage Inventory':
        return const ManageInventoryPage();
      case 'Orders Page':
        return const OrdersNewPage();
      case 'HOD Approval':
        return const BAApprovePage();
      case 'Accounts Page':
        return const AccountsPage();
      case 'Book Page':
        return const BookPage();
      case 'Booked Orders':
        return const BookedPage();
      case 'Picker Page':
        return const PickerPage();
      case 'Packer Page':
        return const PackerPage();
      case 'Checker Page':
        return const CheckerPage();
      case 'Racked Page':
        return const RackedPage();
      case 'Manifest Page':
        return const ManifestPage();
      case 'Manifest Section':
        return const ManifestSection();
      case 'Dispatched':
        return const DispatchedOrders();
      case 'Cancelled':
        return const CancelledOrders();
      case 'Product Master':
        return const ProductDashboardPage();
      case 'Create Label Page':
        return const CreateLabelPage();
      case 'Label Page':
        return const LabelPage();
      case 'Category Master':
        return const CategoryMasterPage();
      case 'Combo Master':
        return const ComboPage();
      case 'Location Master':
        return const LocationMaster();
      case 'Marketplace Master':
        return const MarketplacePage();
      case 'Accounting':
        return const Center(child: Text("Accounting content goes here"));
      case 'Invoices':
        return const InvoicePage();
      case 'Upload Products':
        return const ProductDataDisplay();
      case 'Upload Labels':
        return const LabelUpload();
      case 'Upload Inventory':
        return const InventoryUpload();
      case 'Upload Combo':
        return const ComboUpload();
      default:
        return const Center(child: Text("Select a menu item"));
    }
  }

  Widget _buildDashboardContent(bool isSmallScreen) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: Text(
                    'Hello, Katyayani Organics',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
                if (selectedDate != null) // Display selected date if not null
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Selected Date: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}', // Display selected date
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.greyText,
                      ),
                    ),
                  ),
                const SizedBox(width: 20),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3), // Shadow color
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        DateTime? pickedDate = await _selectDate(context);
                        if (pickedDate != null) {
                          String formattedDate =
                              DateFormat('yyyy-MM-dd').format(pickedDate);
                          Provider.of<DashboardProvider>(context, listen: false)
                              .fetchDashboardData(formattedDate);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.primaryBlue, // Button background color
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10), // Same border radius
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 12.0), // Button padding
                      ),
                      icon: const Icon(
                          Icons.calendar_month_outlined), // Button icon
                      label: const Text(
                        'Select Date', // Button label
                        style: TextStyle(
                          color: Colors.white, // Text color
                          fontSize: 16, // Font size
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              "Here's what's happening with your store today",
              style: TextStyle(
                fontSize: 16,
                color: AppColors.greyText,
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: DashboardCards()),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Last updated: ${lastUpdatedTime != null ? DateFormat('hh:mm a').format(lastUpdatedTime!) : 'N/A'}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.greyText,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    selectedDate = DateTime.now();
                    refreshData(); // Call refresh data method
                    _refreshData();
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(100, 50),
                    backgroundColor: AppColors.primaryBlue,
                  ),
                  child: const Text(
                    'Refresh',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> _selectDate(BuildContext context) async {
    DateTime today = DateTime.now();
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? today,
      firstDate: DateTime(today.year - 5),
      lastDate: DateTime(today.year + 5),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      Provider.of<DashboardProvider>(context, listen: false)
          .fetchDashboardData(DateFormat('yyyy-MM-dd').format(selectedDate!));
    }
    return picked;
  }

  void refreshData() {
    // Refresh logic
    DateTime today = DateTime.now(); // Get today's date
    String formattedDate = DateFormat('yyyy-MM-dd').format(today);
    setState(() {
      selectedDate = today;
      lastUpdatedTime = DateTime.now();
    });
    // Fetch today's data
    Provider.of<DashboardProvider>(context, listen: false)
        .fetchDashboardData(formattedDate);
  }
}
