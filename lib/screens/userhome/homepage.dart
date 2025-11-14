import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:newproject1/screens/userhome/cartitems.dart';
import 'package:newproject1/screens/userhome/categorypage.dart';
import 'package:newproject1/screens/userhome/notifiactionpage.dart';
import 'package:newproject1/screens/userhome/wishlistpage.dart';
import 'package:newproject1/screens/userhome/profilepage/profilesettings.dart';
import 'categorydetailpage.dart';

// =========================================================================
// WIDGET 1: HomePageUI (Main Stateful Widget with Bottom Navigation)
// =========================================================================

class HomePageUI extends StatefulWidget {
  const HomePageUI({super.key});

  @override
  State<HomePageUI> createState() => _HomePageUIState();
}

class _HomePageUIState extends State<HomePageUI> {
  int _selectedIndex = 0;
  static const primaryPurple = Color(0xFF8B5CF6);

  // DECLARE the page list field
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Define the callback for navigating back to the Home index (0)
    final VoidCallback navigateToHomeCallback = () => _onItemTapped(0);

    // Initialize the page list using the renamed class: MyCollectionsPage
    _pages = [
      const HomeContent(),
      // RENAMED CLASS REFERENCE
      MyCollectionsPage(onNavigateToHome: navigateToHomeCallback),
      NotificationPage(onNavigateToHome: navigateToHomeCallback),
      _ProfilePage(),
    ];
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: primaryPurple,
        unselectedItemColor: Colors.grey.shade400,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            // Updated label to reflect "Collections"
            label: "Collections",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none_outlined),
            activeIcon: Icon(Icons.notifications),
            label: "Notifications",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}

// Rename the placeholder class to the detailed implementation
class _ProfilePage extends StatelessWidget {
  const _ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const ProfilePage();
  }
}

// =========================================================================
// WIDGET 3: HomeContent
// =========================================================================

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}


class _HomeContentState extends State<HomeContent> {
  String selectedCategory = "All";
  String searchQuery = ''; // ✅ added this line
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Top Row with avatar, category filter, and cart icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(
                    'https://catlog-s3.s3.eu-west-2.amazonaws.com/qdzjz99zxj.jpeg',
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final selected = await showMenu<String>(
                      context: context,
                      position: const RelativeRect.fromLTRB(100, 100, 0, 0),
                      items: const [
                        PopupMenuItem(value: 'All', child: Text('All')),
                        PopupMenuItem(value: 'Men', child: Text('Men’s Wear')),
                        PopupMenuItem(value: 'Women', child: Text('Women’s Wear')),
                        PopupMenuItem(value: 'Beauty', child: Text('Beauty Products')),
                        PopupMenuItem(value: 'Shoes', child: Text('Shoes')),
                        PopupMenuItem(value: 'Groceries', child: Text('Groceries')),
                      ],
                    );

                    if (selected != null) {
                      setState(() {
                        selectedCategory = selected;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        Text(
                          selectedCategory,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartPage()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: primaryPurple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 25),
            // 🔹 Categories section
            _buildCategories(),

            const SizedBox(height: 12),
            // 🏷️ 1. Categories Section
            _buildSectionTitle('Categories'),

            _buildSearchResults(),

            const SizedBox(height: 25),

            // 🔹 Top Selling Section
            Text(
              selectedCategory == 'All'
                  ? "Top Selling Products"
                  : "$selectedCategory Category",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildProductList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() {
    final categories = [
      {
        'name': 'Ethnic',
        'image':
        'https://www.shutterstock.com/image-photo/create-south-indian-ethnic-wear-260nw-2650373635.jpg',
      },
      {
        'name': 'Men',
        'image':
        'assets/men wear2.jpg',
      },
      {
        'name': 'Shoes',
        'image':
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSQUT6CI8AC5Ki_CfYNGYFsHEUF9ZjQJR1KUg&s',
      },
      {
        'name': 'Beauty',
        'image':
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQu2JISOi-TY2zvCAxjOqQRPpYGtXa6HaRP-A&s',
      },
      {
        'name': 'Groceries',
        'image':
        'https://png.pngtree.com/thumb_back/fh260/background/20230702/pngtree-grocery-and-food-store-concept-3d-rendering-illustration-of-a-shopping-image_3744533.jpg',
      },
    ];

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 15),
        itemBuilder: (context, i) {
          final cat = categories[i];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CategoryDetailPage(categoryName: cat['name']!),
                ),
              );
            },
            child: Column(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: NetworkImage(cat['image']!),
                ),
                const SizedBox(height: 8),
                Text(
                  cat['name']!,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        },
      ),
    );
  }



  Widget _buildSearchResults() {
    // Return nothing if searchQuery is empty
    if (searchQuery.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    // Convert to lowercase for accurate Firestore matching
    final query = searchQuery.toLowerCase().trim();
    Future<void> uploadProduct(
      String name,
      String price,
      String oldPrice,
      String imageUrl,
    ) async {
      await FirebaseFirestore.instance
          .collection('ammu')
          .doc('db')
          .collection('users')
          .doc('RuB2O4psR2flpb56MNDvoxOUuHp2')
          .collection('products')
          .add({
            'name': name,
            'price': price,
            'oldPrice': oldPrice,
            'imageUrl': imageUrl,
            'searchName': name.toLowerCase(),
            'addedAt': FieldValue.serverTimestamp(),
          });
    }

    final searchStream = FirebaseFirestore.instance
        .collection('ammu')
        .doc('db')
        .collection('users')
        .doc('RuB2O4psR2flpb56MNDvoxOUuHp2')
        .collection('products')
        .where('searchName', isGreaterThanOrEqualTo: query)
        .where('searchName', isLessThanOrEqualTo: '$query\uf8ff')
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: searchStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(
              child: Text(
                'No matching products found.',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          );
        }

        final products = snapshot.data!.docs;

        return Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Search Results',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B5CF6), // primaryPurple
                ),
              ),
              const SizedBox(height: 15),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(height: 15),
                itemBuilder: (context, i) {
                  final product = products[i];
                  final name = product['name'] ?? 'Unnamed Product';
                  final price = product['price'] ?? '';
                  final oldPrice = product['oldPrice'] ?? '';
                  final imageUrl = product['imageUrl'] ?? '';

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image_not_supported),
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          Text(
                            price,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (oldPrice.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              oldPrice,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }


  // 🔹 Product List Builder (auto filters by category)
  Widget _buildProductList() {
    // Base query
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('ammu')
        .doc('db')
        .collection('users')
        .doc('RuB2O4psR2flpb56MNDvoxOUuHp2')
        .collection('products');

    // Apply category filter if not 'All'
    if (selectedCategory != 'All') {
      // Firestore field names are case-sensitive, so make sure they match your stored field
      query = query.where('category', isEqualTo: selectedCategory);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No ${selectedCategory == 'All' ? '' : selectedCategory} products found.',
              style: const TextStyle(color: Colors.black54),
            ),
          );
        }

        final products = snapshot.data!.docs;

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Two items per row
            mainAxisSpacing: 15,
            crossAxisSpacing: 15,
            childAspectRatio: 0.72,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final data = products[index].data() as Map<String, dynamic>;
            final name = data['name'] ?? 'Unnamed';
            final imageUrl = data['imageUrl'] ?? '';
            final price = data['price'] ?? '';
            final oldPrice = data['oldPrice'] ?? '';

            return Container(
              width: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 5,
                    spreadRadius: 1,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      imageUrl,
                      height: 210,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image, size: 80),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Text(
                              price,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (oldPrice.isNotEmpty) ...[
                              const SizedBox(width: 5),
                              Text(
                                oldPrice,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        // 💡 'See All' navigates to CategoriesPage
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CategoriesPage(),
              ),
            );
          },
          child: const Text(
            'See All',
            style: TextStyle(
              color: primaryPurple,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    String title,
    String imagePath,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: GestureDetector(
        onTap: () {  setState(() {
          selectedCategory = title; // update category
        });
          debugPrint('Navigating from Categories List to $title Detail');
          // 💡 Navigation to the detail page from the vertical list
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CategoriesPage()),
          );
        },
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white,
                backgroundImage: AssetImage(imagePath),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
