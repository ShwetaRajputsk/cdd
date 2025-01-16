import 'package:flutter/material.dart';

class SelectYourCropPage extends StatefulWidget {
  final List<Map<String, String>> selectedCrops;

  SelectYourCropPage({required this.selectedCrops});

  @override
  _SelectYourCropPageState createState() => _SelectYourCropPageState();
}

class _SelectYourCropPageState extends State<SelectYourCropPage> {
  final List<Map<String, String>> crops = [
    {'image': 'assets/tomato2.png', 'name': 'Tomato'},
    {'image': 'assets/potato2.png', 'name': 'Potato'},
    {'image': 'assets/lemon.png', 'name': 'Lemon'},
    {'image': 'assets/pepper.png', 'name': 'Pepper'},
    {'image': 'assets/corn.png', 'name': 'Maize'},
    {'image': 'assets/rice.png', 'name': 'Rice'},
    {'image': 'assets/cabbage.png', 'name': 'Cabbage'},
    {'image': 'assets/carrot.png', 'name': 'Carrot'},
    {'image': 'assets/onion.jpg', 'name': 'Onion'},
    {'image': 'assets/wheat.png', 'name': 'Wheat'},
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Your Crop'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              // Return the selected crops to the HomePage
              Navigator.pop(context, widget.selectedCrops);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
          ),
          itemCount: crops.length,
          itemBuilder: (context, index) {
            final crop = crops[index];
            final isSelected = widget.selectedCrops
                .any((selectedCrop) => selectedCrop['name'] == crop['name']);

            return GestureDetector(
              onTap: () {
                setState(() {
                  // Check if the crop is selected
                  if (isSelected) {
                    // Remove crop if it's already selected
                    widget.selectedCrops.removeWhere(
                        (selectedCrop) => selectedCrop['name'] == crop['name']);
                  } else {
                    // Add crop if not already selected
                    widget.selectedCrops.add(crop);
                  }
                });
              },
              child: Card(
                color: isSelected ? Colors.green[100] : Colors.white,
                child: Column(
                  children: [
                    Expanded(
                      child: Image.asset(crop['image']!, fit: BoxFit.cover),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        crop['name']!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
