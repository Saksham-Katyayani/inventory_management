import 'package:flutter/material.dart';
//import 'package:inventory_management/Custom-Files/colors.dart';

class Product {
  final String sku;
  final String categoryName;
  final String brand;
  final String mrp;
  final String createdDate;
  final String lastUpdated;
  //final String accSku;
  final String colour;
  //final String upcEan;
  final String displayName;
  final String parentSku;
  final String netWeight;
  final String grossWeight;
  final String ean;
  final String description;
  final String technicalName;
  final String labelSku;
  final String outerPackage_name;
  final String outerPackage_quantity;
  final String length;
  final String width;
  final String height;
  //final String weight;
  final String cost;
  final String tax_rule;
  final String grade;
  final String shopifyImage;
  final String variantName;

  Product({
    required this.sku,
    required this.categoryName,
    required this.brand,
    required this.mrp,
    required this.createdDate,
    required this.lastUpdated,
    //required this.accSku,
    required this.colour,
    //required this.upcEan,
    required this.displayName,
    required this.parentSku,
    required this.ean,
    required this.description,
    required this.technicalName,
    //required this.weight,
    required this.cost,
    required this.tax_rule,
    required this.grade,
    required this.shopifyImage,
    required this.netWeight,
    required this.grossWeight,
    required this.labelSku,
    required this.outerPackage_name,
    required this.outerPackage_quantity,
    required this.length,
    required this.width,
    required this.height,
    required this.variantName,
  });
}

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Check if the screen width is less than a certain value (e.g., 800)
            final bool isSmallScreen = constraints.maxWidth < 800;

            return isSmallScreen
                ? _buildSmallScreenContent() // Column layout for small screens
                : _buildWideScreenContent(); // Two-column content on the right for wide screens
          },
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      height: 150,
      width: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[300],
      ),
      child: product.shopifyImage.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.shopifyImage,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder();
                },
              ),
            )
          : _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.image,
        size: 50,
        color: Colors.grey,
      ),
    );
  }

  // For small screens, adjust the content in a vertical column layout
  Widget _buildSmallScreenContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImage(),
        const SizedBox(height: 12),
        _buildTitle(product.displayName),
        _buildText('SKU', product.sku),
        _buildText('Parent SKU', product.parentSku),
        _buildText('EAN', product.ean),
        _buildText('Description', product.description),
        _buildText('Category Name', product.categoryName),
        _buildText('Colour', product.colour),
        _buildText('Net Weight', product.netWeight),
        _buildText('Gross Weight', product.grossWeight),
        _buildText('Label SKU', product.labelSku),
        _buildText('Outer Package Name', product.outerPackage_name),
        _buildText('Outer Package Quantity', product.outerPackage_quantity),
        _buildText('Brand', product.brand),
        _buildText('Technical Name', product.technicalName),
        //_buildText('Weight', '${product.weight} kg'),
        _buildText('MRP', product.mrp.isNotEmpty ? '₹${product.mrp}' : ''),
        _buildText('Cost', product.cost.isNotEmpty ? '₹${product.cost}' : ''),
        _buildText('Tax Rule',
            product.tax_rule.isNotEmpty ? '${product.tax_rule}%' : ''),
        _buildText('Grade', product.grade),
        _buildText('Created Date', formatDate(product.createdDate)),
        _buildText('Last Updated', formatDate(product.lastUpdated)),
        _buildText(
            'Length', product.length.isNotEmpty ? '${product.length} cm' : ''),
        _buildText(
            'Width', product.width.isNotEmpty ? '${product.width} cm' : ''),
        _buildText(
            'Heigth', product.height.isNotEmpty ? '${product.height} cm' : ''),
      ],
    );
  }

  // For wide screens, keep the image on the left and the content in two columns on the right
  Widget _buildWideScreenContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImage(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitle(product.displayName),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildLeftColumnContent()),
                  const SizedBox(width: 8),
                  Expanded(child: _buildRightColumnContent()),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeftColumnContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildText('SKU', product.sku),
        _buildText('Parent SKU', product.parentSku),
        _buildText('EAN', product.ean),
        _buildText('Description', product.description),
        _buildText('Category Name', product.categoryName),
        _buildText('Colour', product.colour),
        _buildText('Net Weight', product.netWeight),
        _buildText('Gross Weight', product.grossWeight),
        _buildText('Label SKU', product.labelSku),
        _buildText('Outer Package Name', product.outerPackage_name),
        _buildText('Outer Package Quantity', product.outerPackage_quantity),
      ],
    );
  }

  Widget _buildRightColumnContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildText('Brand', product.brand),
        _buildText('Technical Name', product.technicalName),
        //_buildText('Weight', '${product.weight} kg'),
        _buildText('MRP', product.mrp.isNotEmpty ? '₹${product.mrp}' : ''),
        _buildText('Cost', product.cost.isNotEmpty ? '₹${product.cost}' : ''),
        _buildText('Tax Rule',
            product.tax_rule.isNotEmpty ? '${product.tax_rule}%' : ''),
        _buildText('Grade', product.grade),
        _buildText('Created Date', formatDate(product.createdDate)),
        _buildText('Last Updated', formatDate(product.lastUpdated)),
        _buildText(
            'Length', product.length.isNotEmpty ? '${product.length} cm' : ''),
        _buildText(
            'Width', product.width.isNotEmpty ? '${product.width} cm' : ''),
        _buildText(
            'Heigth', product.height.isNotEmpty ? '${product.height} cm' : ''),
      ],
    );
  }

  Widget _buildTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.orange,
        ),
      ),
    );
  }

  Widget _buildText(String label, String value) {
    //print('$label: $value'); // Debugging the value
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value.isNotEmpty ? value : ' ',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: Colors.black54,
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}

String formatDate(String dateString) {
  DateTime date = DateTime.parse(dateString);
  String year = date.year.toString();
  String month = date.month.toString().padLeft(2, '0');
  String day = date.day.toString().padLeft(2, '0');

  return '$day-$month-$year';
}
