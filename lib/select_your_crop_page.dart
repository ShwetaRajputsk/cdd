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
        title: Text(
          'Select Your Crop',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF1C4B0C)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: Color(0xFF1C4B0C)),
            onPressed: () {
              Navigator.pop(context, widget.selectedCrops);
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose your crops to get personalized care tips',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            SizedBox(height: 20),
            Expanded(
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
                        if (isSelected) {
                          widget.selectedCrops.removeWhere(
                              (selectedCrop) => selectedCrop['name'] == crop['name']);
                        } else {
                          widget.selectedCrops.add(crop);
                        }
                      });
                    },
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? Color(0xFF1C4B0C) : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                                child: Image.asset(
                                  crop['image']!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? Color(0xFFE8F5E9) : Colors.white,
                              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  crop['name']!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: isSelected ? Color(0xFF1C4B0C) : Colors.black87,
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF1C4B0C),
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
