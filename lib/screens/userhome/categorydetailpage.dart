import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:newproject1/screens/userhome/cartitems.dart';

class CategoryDetailPage extends StatelessWidget {
  final String categoryName;

  const CategoryDetailPage({
    super.key,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Firestore stream for products under selected category
    final productsStream = FirebaseFirestore.instance
        .collection('ammu')
        .doc('db')
        .collection('users')
        .doc('RuB2O4psR2flpb56MNDvoxOUuHp2') // your user doc
        .collection('categories')
        .doc(categoryName.toLowerCase())
        .collection('products')
        .snapshots();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: StreamBuilder<QuerySnapshot>(
          stream: productsStream,
          builder: (context, snapshot) {
            final itemCount = snapshot.data?.docs.length ?? 0;
            return Text(
              '$categoryName ($itemCount)',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            );
          },
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),

      // --- Product Grid ---
      body: StreamBuilder<QuerySnapshot>(
        stream: productsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No products found in $categoryName.',
                style: const TextStyle(fontSize: 16),
              ),
            );
          }

          final products = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index].data() as Map<String, dynamic>;
              final name = product['categoryName'] ?? 'Unnamed Product';
              final price = product['price'] ?? '₹0';
              final imageUrl = product['imageUrl'] ?? '';
              final quantity = product['quantity']?.toString() ?? '0';
              final rate = product['rate']?.toString() ?? '0';

              return ProductGridItem(
                name: name,
                price: price,
                imageUrl: imageUrl,
                quantity: quantity,
                rate: rate,
                categoryName: categoryName,
              );
            },
          );
        },
      ),
    );
  }
}


class ProductGridItem extends StatefulWidget {
  final String name;
  final String price;
  final String imageUrl;
  final String quantity;
  final String rate;
  final String categoryName;

  const ProductGridItem({
    super.key,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.quantity,
    required this.rate,
    required this.categoryName,
  });

  @override
  State<ProductGridItem> createState() => _ProductGridItemState();
}

class _ProductGridItemState extends State<ProductGridItem> {
  bool isFavourite = false;
  String? userId;
  int currentQuantity = 1; // default quantity
  double currentRate = 0;  // default rating


  @override
  void initState() {
    super.initState();
    _initUser();
    currentQuantity = int.tryParse(widget.quantity) ?? 1;
    currentRate = double.tryParse(widget.rate) ?? 0;
  }

  // ✅ Initialize user and check favourite state
  Future<void> _initUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
      await checkIfFavourite();
    }
  }

  // ✅ Check if product already exists in favourites
  Future<void> checkIfFavourite() async {
    if (userId == null) return;

    final favRef = FirebaseFirestore.instance
        .collection('ammu')
        .doc('db')
        .collection('users')
        .doc(userId)
        .collection('favourites');

    final existing = await favRef
        .where('name', isEqualTo: widget.name)
        .where('category', isEqualTo: widget.categoryName)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      setState(() => isFavourite = true);
    }
  }

  // ✅ Toggle favourite (Add/Remove)
  Future<void> toggleFavourite(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first')),
      );
      return;
    }

    final userId = user.uid;
    final favRef = FirebaseFirestore.instance
        .collection('ammu')
        .doc('db')
        .collection('users')
        .doc(userId)
        .collection('favourites');

    if (isFavourite) {
      // 🔴 Remove from favourites
      final snapshot = await favRef
          .where('name', isEqualTo: widget.name)
          .where('category', isEqualTo: widget.categoryName)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.name} removed from favorites 💔')),
      );
    } else {
      // ❤️ Add to favourites
      await favRef.add({
        'categoryName': widget.name,
        'price': widget.price,
        'imageUrl': widget.imageUrl,
        'quantity': widget.quantity,
        'rate': widget.rate,
        'addedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.name} added to favorites ❤️')),
      );
    }

    setState(() => isFavourite = !isFavourite);
  }


  Future<void> addToCart(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first')),
      );
      return;
    }

    final userId = user.uid;
    final cartRef = FirebaseFirestore.instance
        .collection('ammu')
        .doc('db')
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc('items')
        .collection('products');

    final existing =
    await cartRef.where('name', isEqualTo: widget.name).limit(1).get();

    if (existing.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already in cart 🛒')),
      );
      return;
    }

    await cartRef.add({
      'CategoryName': widget.name,
      'price': widget.price,
      'imageUrl': widget.imageUrl,
      'quantity': widget.quantity,
      'rate': widget.rate,
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.name} added to cart 🛒')),
    );

    // ✅ Navigate to CartPage after adding
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CartPage()),
    );
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(
              name: widget.name,
              price: widget.price,
              imageUrl: widget.imageUrl,
              quantity: widget.quantity,
              rate: widget.rate,
              categoryName: widget.categoryName,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                    child: Image.network(
                      widget.imageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, size: 50),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: GestureDetector(
                      onTap: () => toggleFavourite(context),
                      child: Icon(
                        isFavourite ? Icons.favorite : Icons.favorite_border,
                        color: isFavourite ? Colors.red : Colors.black54,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 5),
                    Text(widget.price,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              IconButton(
                                onPressed: () {
                                  if (currentQuantity > 1) {
                                    setState(() => currentQuantity--);
                                  }
                                },
                                icon: const Icon(Icons.remove_circle_outline, size: 20),
                              ),
                              Text('$currentQuantity',
                                  style: const TextStyle(fontSize: 14)),
                              IconButton(
                                onPressed: () => setState(() => currentQuantity++),
                                icon: const Icon(Icons.add_circle_outline, size: 20),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 18),
                              const SizedBox(width: 2),
                              Text(currentRate.toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 14)),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => setState(() {
                                  if (currentRate < 5) currentRate += 0.5;
                                }),
                                icon: const Icon(Icons.arrow_drop_up, size: 18),
                              ),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => setState(() {
                                  if (currentRate > 0) currentRate -= 0.5;
                                }),
                                icon: const Icon(Icons.arrow_drop_down, size: 18),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => addToCart(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Buy Now'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => CheckoutPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.shopping_bag),
                        label: const Text('Add To Cart'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final productsCollection =
    FirebaseFirestore.instance.collection('products');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: Colors.white,
        foregroundColor: primaryDark,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: productsCollection.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No products found'));
          }

          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final productDoc = docs[index];
              final data = productDoc.data() as Map<String, dynamic>;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailPage(
                        name: data['name'] ?? 'Unnamed Product',
                        price: data['price']?.toString() ?? '₹0',
                        imageUrl: data['imageUrl'] ?? '',
                        quantity: data['quantity']?.toString() ?? 'N/A',
                        rate: data['rate']?.toString() ?? '0',
                        categoryName: data['category'] ?? 'Unknown',
                      ),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        data['imageUrl'] ?? '',
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                        const Icon(Icons.image_not_supported, size: 40),
                      ),
                    ),
                    title: Text(
                      data['name'] ?? 'Unnamed Product',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      data['price']?.toString() ?? '₹0.00',
                      style: const TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: SizedBox(
                      width: 100, // <-- enough width for both buttons
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                            // --- Add to Cart logic ---
                            try {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please log in to add to cart')),
                                );
                                return;
                              }

                              final userId = user.uid;
                              final cartCollection = FirebaseFirestore.instance
                                  .collection('ammu')
                                  .doc('db')
                                  .collection('users')
                                  .doc(userId)
                                  .collection('cart')
                                  .doc('items')
                                  .collection('products');

                              final productData = {
                                'productId': productDoc.id,
                                'name': data['name'] ?? '',
                                'price': data['price'] ?? '₹0',
                                'imageUrl': data['imageUrl'] ?? '',
                              };

                              final existing = await cartCollection
                                  .where('productId', isEqualTo: productDoc.id)
                                  .get();

                              if (existing.docs.isEmpty) {
                                await cartCollection.add({
                                  ...productData,
                                  'quantity': 1,
                                  'timestamp': FieldValue.serverTimestamp(),
                                });
                              } else {
                                final docId = existing.docs.first.id;
                                final existingData =
                                existing.docs.first.data() as Map<String, dynamic>;
                                int currentQty = (existingData['quantity'] is int)
                                    ? existingData['quantity']
                                    : int.tryParse(existingData['quantity'].toString()) ?? 1;

                                await cartCollection.doc(docId).update({'quantity': currentQty + 1});
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Added to cart 🛒')),
                              );
                            } catch (e) {
                              debugPrint('Error adding to cart: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to add to cart ❌')),
                              );
                            }
                          },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryPurple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Add to Cart',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 6),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => CheckoutPage()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Buy Now',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}


class ProductDetailPage extends StatelessWidget {
  final String name;
  final String price;
  final String imageUrl;
  final String quantity;
  final String rate;
  final String categoryName;

  const ProductDetailPage({
    super.key,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.quantity,
    required this.rate,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.broken_image, size: 100),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              price,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 8),
            Text("Quantity: $quantity"),
            Text("⭐ Rating: $rate"),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            const Text(
              "Product Description",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              "This is a sample product description. You can connect this section to Firestore later to show the real product description.",
              style: TextStyle(color: Colors.black87, height: 1.4),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Add to cart logic (reuse your addToCart function)
                    },
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: const Text(
                      'Add to Cart',
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(0, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Add to favorites logic (reuse toggleFavourite)
                    },
                    icon: const Icon(Icons.favorite_border, size: 18),
                    label: const Text(
                      'Favourites',
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(0, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }
}
