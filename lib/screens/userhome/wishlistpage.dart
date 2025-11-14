import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// =========================================================================
// WIDGET 4: MyCollectionsPage (RENAMED from WishlistPage - List of folders)
// =========================================================================

class MyCollectionsPage extends StatelessWidget {
  final VoidCallback onNavigateToHome;
  const MyCollectionsPage({super.key, required this.onNavigateToHome});

  @override
  Widget build(BuildContext context) {
    // Firestore Stream (Favourites)
    final favouritesStream = FirebaseFirestore.instance
        .collection('ammu')
        .doc('db')
        .collection('users')
        .doc('RuB2O4psR2flpb56MNDvoxOUuHp2') // 👈 static user ID
        .collection('favourites')
        .snapshots();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 🔹 Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onNavigateToHome,
                    child: const CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFFF0F0F0),
                      child: Icon(Icons.arrow_back, color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Expanded(
                    child: Text(
                      'My Collections ❤️',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 38),
                ],
              ),
            ),

            // 🔹 StreamBuilder - Load Favourites
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: favouritesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No favorites yet ❤️',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    );
                  }

                  // Fetch favourite items
                  final favourites = snapshot.data!.docs;

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: 1, // One collection "My Favorites"
                    separatorBuilder: (_, __) => const SizedBox(height: 15),
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          // 👉 Navigate to Wishlist Details Page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WishlistDetailPage(
                                title: 'My Favorites',
                                products: favourites, // ✅ correct parameter name
                              ),

                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F8F8),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.favorite,
                                      color: Colors.red, size: 28),
                                  const SizedBox(width: 15),
                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'My Favorites',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${favourites.length} Products',
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Icon(Icons.arrow_forward_ios,
                                  size: 18, color: Colors.grey),
                            ],
                          ),
                        ),
                      );
                    },
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

// =========================================================================
// WIDGET 5: WishlistDetailPage (Product Grid View)
// =========================================================================

class WishlistDetailPage extends StatelessWidget {
  final String title;
  final List<QueryDocumentSnapshot> products;

  const WishlistDetailPage({
    super.key,
    required this.title,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    const Color darkBackground = Color(0xFF14141E);
    const Color primaryRed = Color(0xFFE74C3C);

    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // 🔹 Custom App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '$title ❤️',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Text(
                    '${products.length}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),

            // 🔹 Favorites Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: products.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final data =
                  products[index].data() as Map<String, dynamic>;

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(15),
                              ),
                              child: Image.network(
                                data['imageUrl'] ?? '',
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image,
                                    color: Colors.white30, size: 50),
                              ),
                            ),
                            const Positioned(
                              right: 10,
                              top: 10,
                              child: Icon(Icons.favorite,
                                  color: primaryRed, size: 24),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['name'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                data['price'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
