import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/colors.dart';

class CustomDataTable extends StatelessWidget {
  final List<String> columnNames;
  final List<Map<String, dynamic>> rowsData;

  const CustomDataTable({
    Key? key,
    required this.columnNames,
    required this.rowsData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create DataColumn list from column names
    List<DataColumn> columns = columnNames.map((name) {
      return DataColumn(
        label: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
      );
    }).toList();

    // Create DataRow list from rowsData
    List<DataRow> rows = rowsData.map((data) {
      return DataRow(
        cells: columnNames.map((columnName) {
          return DataCell(Text(data[columnName] ?? 'N/A'));
        }).toList(),
      );
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          headingRowColor: MaterialStateColor.resolveWith(
            (states) => AppColors.green.withOpacity(0.2),
          ),
          columns: columns,
          rows: rows,
        ),
      ),
    );
  }
}