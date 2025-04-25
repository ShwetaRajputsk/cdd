import 'package:flutter/material.dart';
import 'bottom_navigation_bar.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({Key? key}) : super(key: key);

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final Color primaryColor = const Color(0xFF1C4B0C);
  String _selectedCategory = 'Herbicides';
  final TextEditingController _searchController = TextEditingController();
  int _currentIndex = 2;

  final Map<String, List<Map<String, dynamic>>> productsByCategory = {
 'Herbicides': [
      {
        'name': 'Glycel 41% SL',
        'price': '₹450',
        'image': 'assets/herbicides/glycel.png',
        'brand': 'Syngenta'
      },
      {
        'name': 'Rally 10% WP',
        'price': '₹620',
        'image': 'assets/herbicides/rally.png',
        'brand': 'Bayer'
      },
      {
        'name': 'Pendimethalin 30% EC',
        'price': '₹380',
        'image': 'assets/herbicides/pendimethalin.png',
        'brand': 'UPL'
      },
      {
        'name': 'Topstar 80% WP',
        'price': '₹550',
        'image': 'assets/herbicides/topstar.png',
        'brand': 'Dhanuka'
      },
      {
        'name': 'Clodinafop 15% WP',
        'price': '₹420',
        'image': 'assets/herbicides/clodinafop.png',
        'brand': 'Rallis'
      },
      {
        'name': 'Basagran 48% SL',
        'price': '₹680',
        'image': 'assets/herbicides/basagran.png',
        'brand': 'BASF'
      },
      {
        'name': 'Almix 20% WP',
        'price': '₹510',
        'image': 'assets/herbicides/almix.png',
        'brand': 'Nagarjuna'
      },
      {
        'name': 'Nominee Gold',
        'price': '₹720',
        'image': 'assets/herbicides/nominee.png',
        'brand': 'UPL'
      },
    ],
    // 'Seeds': [
    //   {
    //     'name': 'Pusa Basmati 1509',
    //     'price': '₹2800/kg',
    //     'image': 'assets/seeds/basmati.png',
    //     'brand': 'IARI'
    //   },
    //   {
    //     'name': 'NK 6240 Hybrid Maize',
    //     'price': '₹3200/kg',
    //     'image': 'assets/seeds/maize.png',
    //     'brand': 'Syngenta'
    //   },
    //   {
    //     'name': 'Pioneer PUSA 44',
    //     'price': '₹2500/kg',
    //     'image': 'assets/seeds/paddy.png',
    //     'brand': 'Dupont'
    //   },
    //   {
    //     'name': 'NRC 138 Cotton',
    //     'price': '₹4500/packet',
    //     'image': 'assets/seeds/cotton.png',
    //     'brand': 'Nuziveedu'
    //   },
    //   {
    //     'name': 'Mahyco Tomato Hybrid',
    //     'price': '₹1500/100g',
    //     'image': 'assets/seeds/tomato.png',
    //     'brand': 'Mahyco'
    //   },
    //   {
    //     'name': 'Kaveri BG II Cotton',
    //     'price': '₹4200/packet',
    //     'image': 'assets/seeds/kaveri.png',
    //     'brand': 'Kaveri'
    //   },
    //   {
    //     'name': 'Pro Agro Groundnut',
    //     'price': '₹1800/kg',
    //     'image': 'assets/seeds/groundnut.png',
    //     'brand': 'Pro Agro'
    //   },
    //   {
    //     'name': 'NS 515 Soybean',
    //     'price': '₹3200/kg',
    //     'image': 'assets/seeds/soybean.png',
    //     'brand': 'Nath Seeds'
    //   },
    // ],
    // 'Nutrients': [
    //   {
    //     'name': 'NPK 19:19:19',
    //     'price': '₹120/kg',
    //     'image': 'assets/nutrients/npk.png',
    //     'brand': 'IFFCO'
    //   },
    //   {
    //     'name': 'Zinc Sulphate 21%',
    //     'price': '₹85/kg',
    //     'image': 'assets/nutrients/zinc.png',
    //     'brand': 'Coromandel'
    //   },
    //   {
    //     'name': 'Boron 20%',
    //     'price': '₹240/kg',
    //     'image': 'assets/nutrients/boron.png',
    //     'brand': 'Tata'
    //   },
    //   {
    //     'name': 'Seaweed Extract',
    //     'price': '₹350/ltr',
    //     'image': 'assets/nutrients/seaweed.png',
    //     'brand': 'Biostadt'
    //   },
    //   {
    //     'name': 'Calcium Nitrate',
    //     'price': '₹180/kg',
    //     'image': 'assets/nutrients/calcium.png',
    //     'brand': 'Yara'
    //   },
    //   {
    //     'name': 'Humic Acid Granules',
    //     'price': '₹95/kg',
    //     'image': 'assets/nutrients/humic.png',
    //     'brand': 'DAP'
    //   },
    //   {
    //     'name': 'Micronutrient Mix',
    //     'price': '₹420/5kg',
    //     'image': 'assets/nutrients/micro.png',
    //     'brand': 'Paras'
    //   },
    //   {
    //     'name': 'Vermicompost',
    //     'price': '₹8/kg',
    //     'image': 'assets/nutrients/vermi.png',
    //     'brand': 'Organic'
    //   },
    // ],
    // 'Insecticides': [
    //   {
    //     'name': 'Confidor 17.8% SL',
    //     'price': '₹650/ltr',
    //     'image': 'assets/insecticides/confidor.png',
    //     'brand': 'Bayer'
    //   },
    //   {
    //     'name': 'Monocrotophos 36%',
    //     'price': '₹480/ltr',
    //     'image': 'assets/insecticides/mono.png',
    //     'brand': 'Coromandel'
    //   },
    //   {
    //     'name': 'Acephate 75% SP',
    //     'price': '₹320/kg',
    //     'image': 'assets/insecticides/acephate.png',
    //     'brand': 'UPL'
    //   },
    //   {
    //     'name': 'Deltamethrin 2.8%',
    //     'price': '₹540/ltr',
    //     'image': 'assets/insecticides/delta.png',
    //     'brand': 'Syngenta'
    //   },
    //   {
    //     'name': 'Imidacloprid 17.8%',
    //     'price': '₹720/ltr',
    //     'image': 'assets/insecticides/imidacloprid.png',
    //     'brand': 'BASF'
    //   },
    //   {
    //     'name': 'Chlorpyriphos 20%',
    //     'price': '₹380/ltr',
    //     'image': 'assets/insecticides/chlorpyriphos.png',
    //     'brand': 'Dhanuka'
    //   },
    //   {
    //     'name': 'Neem Oil',
    //     'price': '₹220/ltr',
    //     'image': 'assets/insecticides/neem.png',
    //     'brand': 'Organic'
    //   },
    //   {
    //     'name': 'Cypermethrin 25%',
    //     'price': '₹410/ltr',
    //     'image': 'assets/insecticides/cyper.png',
    //     'brand': 'Rallis'
    //   },
    
  };

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          'CropFit Store',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      // Removed duplicate body parameter
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Category Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: productsByCategory.keys.map((category) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: _selectedCategory == category,
                            selectedColor: primaryColor,
                            labelStyle: TextStyle(
                              color: _selectedCategory == category 
                                  ? Colors.white 
                                  : primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: primaryColor),
                            ),
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Product Grid
 GridView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  padding: const EdgeInsets.only(bottom: 25), // ← Add this line
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 0.75,
    crossAxisSpacing: 15,
    mainAxisSpacing: 15,
  ),
                    itemCount: productsByCategory[_selectedCategory]!.length,
                    itemBuilder: (context, index) {
                      final product = productsByCategory[_selectedCategory]![index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 2,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Image
                            Container(
                              height: 135,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                image: DecorationImage(
                                  image: AssetImage(product['image']),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            // Product Details
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product['brand'],
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    product['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                     product['price'],
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: primaryColor,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(Icons.add_shopping_cart, 
                                            color: Colors.white, 
                                            size: 20),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () {},
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
