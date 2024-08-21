import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/retry.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/Custom-Files/custom-dropdown.dart';
import 'package:inventory_management/Custom-Files/custom-textfield.dart';

class ManageInventory extends StatefulWidget {
  const ManageInventory({super.key});

  @override
  State<ManageInventory> createState() => _ManageInventoryState();
}

class _ManageInventoryState extends State<ManageInventory> {
  int firstval=0,lastval=10;
  int size=40,currentPage=0,jump=5;
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          color: AppColors.greyBackground,
          child: Column(
            children: [
              Container(
                color: AppColors.greyBackground,
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    screenWidth > 1415
                        ? Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Stock Level',
                                      style: AppColors().simpleHeadingStyle),
                                  Row(
                                    children: [
                                      CustomTextField(
                                        controller: TextEditingController(),
                                        width: screenWidth * 0.12,
                                      ),
                                      const SizedBox(width: 10),
                                      CustomTextField(
                                        controller: TextEditingController(),
                                        width: screenWidth * 0.12,
                                      ),
                                      const SizedBox(width: 20),
                                      buttonForThisPage(
                                          width: 70,
                                          height: 50,
                                          buttonTitle: 'GO'),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: screenWidth * 0.5,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Search',
                                        style: AppColors().simpleHeadingStyle),
                                    Row(
                                      children: [
                                        const SizedBox(
                                          width: 100,
                                          child: CustomDropdown(),
                                        ),
                                        const SizedBox(width: 10),
                                        CustomTextField(
                                          controller: TextEditingController(),
                                          width: screenWidth * 0.12,
                                        ),
                                        const SizedBox(
                                          width: 5,
                                        ),
                                        Text('Search Exact SKU',
                                            style:
                                                AppColors().simpleHeadingStyle),
                                        const SizedBox(
                                          width: 5,
                                        ),
                                        buttonForThisPage(
                                            buttonTitle: 'Search',
                                            height: 50,
                                            width: 100),
                                        const SizedBox(
                                          width: 5,
                                        ),
                                        buttonForThisPage(
                                            buttonTitle: 'Download Inventory',
                                            height: 50,
                                            width: 175),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Stock Level',
                                  style: AppColors().simpleHeadingStyle),
                              Row(
                                children: [
                                  CustomTextField(
                                    controller: TextEditingController(),
                                    width:145,
                                  ),
                                  const SizedBox(width: 10),
                                  CustomTextField(
                                    controller: TextEditingController(),
                                    width:145,
                                  ),
                                  const SizedBox(width: 10),
                                 screenWidth>450?buttonForThisPage(
                                      width: 70, height: 50, buttonTitle: 'GO'):const SizedBox(),
                                ],
                              ),
                              screenWidth<450?buttonForThisPage(
                                      width: 70, height: 50, buttonTitle: 'GO'):const SizedBox(),
                              Text('Search',
                                  style: AppColors().simpleHeadingStyle),
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 100,
                                    child: CustomDropdown(),
                                  ),
                                  const SizedBox(width: 10),
                                  CustomTextField(
                                    controller: TextEditingController(),
                                    width:screenWidth*0.15,
                                    label:'Search Exact SKU',
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                 screenWidth>450?Text('Search Exact SKU',
                                      style: AppColors().simpleHeadingStyle):const SizedBox(),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  buttonForThisPage(
                                      buttonTitle: 'Search',
                                      height: 50,
                                      width: 100),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                ],
                              ),
                             const SizedBox(
                                height:5,
                              ),
                              buttonForThisPage(
                                  buttonTitle: 'Download Inventory',
                                  height: 50,
                                  width: 175),
                            ],
                          ),
                    const SizedBox(height: 10),
                    Text('Filters', style: AppColors().simpleHeadingStyle),
                    Container(
                      height: 80,
                      // width: 300,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.cardsgreen),
                        // color: Colors.amberAccent,
                      ),
                      child: const Align(
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                          width: 150,
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CustomDropdown(),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              Container(
                height: 30,
                color: AppColors.white,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CustomTextField(
                      controller: TextEditingController(text: 'Hello'),
                      width: 150,
                      label: 'Search',
                      icon: Icons.search,
                    ),
                  ),
                ],
              ),
              SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    children: [
                      DataTable(
                        showBottomBorder: true,
                        dataRowMaxHeight: 100,
                        columns: [
                          DataColumn(
                              label: Text('COMPANY NAME',
                                  style: AppColors().headerStyle)),
                          DataColumn(
                              label: Text('CATEGORY',
                                  style: AppColors().headerStyle)),
                          DataColumn(
                              label: Text('IMAGE',
                                  style: AppColors().headerStyle)),
                          DataColumn(
                              label: Text('BRAND',
                                  style: AppColors().headerStyle)),
                          DataColumn(
                              label:
                                  Text('SKU', style: AppColors().headerStyle)),
                          DataColumn(
                              label: Text('PRODUCT NAME',
                                  style: AppColors().headerStyle)),
                          DataColumn(
                              label: Text('MODEL NO',
                                  style: AppColors().headerStyle)),
                          DataColumn(
                              label:
                                  Text('MRP', style: AppColors().headerStyle)),
                          DataColumn(
                              label: Text('QUANTITY',
                                  style: AppColors().headerStyle)),
                          DataColumn(
                            label: ElevatedButton(
                              onPressed: () {
                                // Save action
                              },
                              child: const Text('Save All'),
                            ),
                          ),
                          DataColumn(
                              label: Text('FLIPKART',
                                  style: AppColors().headerStyle)),
                          DataColumn(
                              label: Text('SNAPDEAL',
                                  style: AppColors().headerStyle)),
                          DataColumn(
                              label: Text('AMAZON.IN',
                                  style: AppColors().headerStyle)),
                        ],
                        rows: List<DataRow>.generate(
                          5, // Example number of rows
                          (index) => DataRow(
                            cells: [
                              DataCell(Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 200,
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: Text(
                                    'Company ${firstval+index+1}',
                                    overflow: TextOverflow.visible,
                                    softWrap: true,
                                  ),
                                ),
                              )),
                              DataCell(Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 150,
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: Text('Category ${firstval+index+1}'),
                                ),
                              )),
                              DataCell(Image.network(
                                'https://sharmellday.com/wp-content/uploads/2022/12/032_Canva-Text-to-Image-Generator-min-1.jpg',
                                width: 100,
                                height: 400,
                              )
                              ),
                              DataCell(IntrinsicHeight(
                                child: Container(
                                  constraints: const BoxConstraints(
                                    maxWidth: 150,
                                  ),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.vertical,
                                    child: Text('Brand ${firstval+index+1}'),
                                  ),
                                ),
                              )),
                              DataCell(Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 100,
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: Text('SKU${firstval+index+1}'),
                                ),
                              )),
                              DataCell(Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 150,
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: Text('Product Name ${firstval+index+1}'),
                                ),
                              )),
                              DataCell(Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 100,
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: Text('Model No ${firstval+index+1}'),
                                ),
                              )),
                              DataCell(Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 100,
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: Text('MRP ${firstval+index+1}'),
                                ),
                              )),
                              DataCell(Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 200,
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Column(
                                            children: [
                                              Container(
                                                height: 30,
                                                width: 130,
                                                decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color:
                                                            AppColors.black)),
                                                child: Center(
                                                    child: Text(
                                                        "Quantity ${firstval+index+1}")),
                                              ),
                                              const SizedBox(height: 3),
                                              buttonForThisPage(),
                                            ],
                                          ),
                                          const SizedBox(width: 4),
                                          const InkWell(
                                            child: Icon(Icons.cloud,
                                                color: AppColors.cardsgreen),
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(DateTime.now().toString()),
                                      ),
                                    ],
                                  ),
                                ),
                              )),
                              DataCell(ElevatedButton(
                                onPressed: () {
                                  // Save action
                                },
                                child: const Text('Save All'),
                              )),
                              DataCell(Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 100,
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: Text('Flipkart ${firstval+index+1}'),
                                ),
                              )),
                              DataCell(Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 100,
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: Text('Snapdeal ${firstval+index+1}'),
                                ),
                              )),
                              DataCell(Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 100,
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: Text('Amazon ${firstval+index+1}'),
                                ),
                              )),
                            ],
                          ),
                        // ),
                      ),
                      ),
                    ],
                  ),
                ),
              ),
               const SizedBox(height:10,),
               SingleChildScrollView(
                scrollDirection:Axis.horizontal,
                 child: Row(
                  mainAxisAlignment:MainAxisAlignment.start,
                   children:[
                    for(int i=0;i<size/jump;i++)
                     Padding(
                       padding: const EdgeInsets.symmetric(horizontal:8),
                       child: InkWell(
                         child: CircleAvatar(
                            backgroundColor:AppColors.primaryBlue,
                            child:Text('${i+1}',style:const TextStyle(color:AppColors.white),),       
                         ),
                         onTap:(){
                          firstval=i*jump;
                          lastval=(i+1)*jump;
                          setState(() {
                            
                          });
                         },
                       ),
                     ),
                   
                   ],
                 ),
               ),
               InkWell(child: const Text('Load More'),
               onTap:(){
                size=size+20;
                setState(() {
                  print("size is here $size");
                });
               },
               )
            ],
          ),
        ),
      ),
    );
  }
}

class buttonForThisPage extends StatelessWidget {
  final double width;
  final double height;
  final String buttonTitle;

  buttonForThisPage({
    super.key,
    this.width = 150,
    this.height = 30,
    this.buttonTitle = 'View Details',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        style: const ButtonStyle(
            fixedSize: MaterialStatePropertyAll(Size(130, 7))),
        onPressed: () {
          // Save action
        },
        child: Text(buttonTitle),
      ),
    );
  }
}
