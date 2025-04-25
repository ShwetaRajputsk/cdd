import 'package:flutter/material.dart';
import 'dart:typed_data'; // Import Uint8List
import 'chat.dart'; // Import the chat.dart file

class PlantHealthScreen extends StatelessWidget {
  final Color primaryColor = const Color(0xFF1C4B0C);
  final Uint8List imageData;
  final String diseaseName;
  final String symptoms;

  const PlantHealthScreen({
    Key? key,
    required this.imageData,
    required this.diseaseName,
    required this.symptoms,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Crop Health Report',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plant Image
            Container(
              width: double.infinity,
              height: 320,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                child: Image.memory(
                  imageData,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            // Plant Name Section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    diseaseName,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Text(
                  //   'a species of $diseaseName',
                  //   style: TextStyle(
                  //     fontSize: 18,
                  //     color: Colors.grey.shade600,
                  //   ),
                  // ),
                ],
              ),
            ),
            
            // Plant Health Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryColor.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Plant Health Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.local_florist_rounded, color: primaryColor),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Plant Health',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Health Status
                    const Text(
                      ' YOUR CROP HEALTH STATUS IS READY!',
                        style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Description
                    Text(
                      'We’ve analyzed your crop condition. For a more accurate assessment and personalized advice, feel free to chat with our AI expert.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Chat with AI Button
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to the chat.dart page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(), // Replace with your ChatScreen widget
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 54),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Chat with AI',
                            style: TextStyle(
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Symptoms Section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Symptoms',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...symptoms.split('\n').map((symptom) => SymptomItem(symptom)).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SymptomItem extends StatelessWidget {
  final String text;
  
  const SymptomItem(this.text, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.teal.shade900,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: Colors.teal.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PlantIcon extends StatelessWidget {
  const PlantIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: CustomPaint(
        painter: PlantIconPainter(),
      ),
    );
  }
}

class PlantIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint fillPaint = Paint()
      ..color = Colors.green.withOpacity(0.2)
      ..style = PaintingStyle.fill;
      
    final Paint strokePaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    // Draw plant pot and stem
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = size.width / 2;
    
    // Draw circle background
    canvas.drawCircle(Offset(centerX, centerY), radius, fillPaint);
    
    // Draw pot
    final Path potPath = Path()
      ..moveTo(centerX - radius * 0.3, centerY)
      ..lineTo(centerX - radius * 0.3, centerY + radius * 0.4)
      ..lineTo(centerX + radius * 0.3, centerY + radius * 0.4)
      ..lineTo(centerX + radius * 0.3, centerY);
    
    canvas.drawPath(potPath, strokePaint);
    
    // Draw stem and leaves
    final Path stemPath = Path()
      ..moveTo(centerX, centerY)
      ..lineTo(centerX, centerY - radius * 0.5);
    
    canvas.drawPath(stemPath, strokePaint);
    
    // Draw leaves
    final Path leafPath = Path()
      ..moveTo(centerX - radius * 0.4, centerY - radius * 0.3)
      ..quadraticBezierTo(centerX, centerY - radius * 0.8, centerX + radius * 0.4, centerY - radius * 0.3);
    
    canvas.drawPath(leafPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
