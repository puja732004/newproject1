import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:newproject1/screens/userhome/paymentdetails/addaddresspage.dart';
import 'package:newproject1/screens/userhome/paymentdetails/addcardpage.dart';
import 'package:timelines_plus/timelines_plus.dart';

const primaryPurple = Color(0xFF8B5CF6);
const primaryDark = Color(0xFF1E1E1E);

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final double _shippingCost = 8.00;
  final double _tax = 0.00;

  final _firestore = FirebaseFirestore.instance;

  String get _userId => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference get _cartCollection => _firestore
      .collection('ammu')
      .doc('db')
      .collection('users')
      .doc(_userId)
      .collection('cart')
      .doc('items')
      .collection('products');

  // 🔹 Add product to cart (with real Firestore productId)
  Future<void> addToCart(Map<String, dynamic> product) async {
    try {
      final querySnapshot = await _cartCollection
          .where('productId', isEqualTo: product['productId'])
          .get();

      if (querySnapshot.docs.isEmpty) {
        await _cartCollection.add({
          ...product,
          'quantity': 1,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        final docId = querySnapshot.docs.first.id;
        final data = querySnapshot.docs.first.data() as Map<String, dynamic>;
        int currentQty = (data['quantity'] is int)
            ? data['quantity']
            : int.tryParse(data['quantity'].toString()) ?? 1;

        await _cartCollection.doc(docId).update({'quantity': currentQty + 1});
      }
    } catch (e) {
      debugPrint('Error adding to cart: $e');
    }
  }

  // 🔹 Update quantity or delete if < 1
  Future<void> _updateQuantity(String docId, int change) async {
    final doc = await _cartCollection.doc(docId).get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    int currentQty = (data['quantity'] is int)
        ? data['quantity']
        : int.tryParse(data['quantity'].toString()) ?? 1;
    int newQty = currentQty + change;

    if (newQty < 1) {
      await _cartCollection.doc(docId).delete();
    } else {
      await _cartCollection.doc(docId).update({'quantity': newQty});
    }
  }

  // 🔹 Calculate subtotal
  double _calculateSubtotal(List<QueryDocumentSnapshot> docs) {
    double sum = 0;
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      double price = 0;
      if (data['price'] is String) {
        price =
            double.tryParse((data['price'] as String).replaceAll('₹', '')) ??
                0.0;
      } else if (data['price'] is num) {
        price = (data['price'] as num).toDouble();
      }

      int qty = (data['quantity'] is int)
          ? data['quantity']
          : int.tryParse(data['quantity'].toString()) ?? 1;

      sum += price * qty;
    }
    return sum;
  }

  double _getTotal(double subtotal) => subtotal + _shippingCost + _tax;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in first')));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cart',
          style: TextStyle(fontWeight: FontWeight.bold, color: primaryDark),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _cartCollection
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return _buildEmptyCartUI(context);

          final subtotal = _calculateSubtotal(docs);
          final total = _getTotal(subtotal);

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final docId = docs[index].id;

                    int quantity = (data['quantity'] is int)
                        ? data['quantity']
                        : int.tryParse(data['quantity'].toString()) ?? 1;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: data['imageUrl'] != null
                              ? Image.network(
                            data['imageUrl'],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                            const Icon(Icons.image_not_supported),
                          )
                              : const Icon(Icons.image_not_supported),
                        ),
                        title: Text(
                          data['name'] ?? 'Product',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          data['price']?.toString() ?? '₹0.0',
                          style: const TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: SizedBox(
                          width: 160,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () => _updateQuantity(docId, -1),
                              ),
                              Text('$quantity'),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => _updateQuantity(docId, 1),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _cartCollection.doc(docId).delete(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  children: [
                    _buildPriceRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
                    _buildPriceRow(
                        'Shipping', '₹${_shippingCost.toStringAsFixed(2)}'),
                    _buildPriceRow('Tax', '₹${_tax.toStringAsFixed(2)}'),
                    const Divider(),
                    _buildPriceRow('Total', '₹${total.toStringAsFixed(2)}',
                        isTotal: true),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CheckoutPage(),
                            ),
                          );
                        },
                        child: const Text(
                          'Proceed to Checkout',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: isTotal ? 18 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              )),
          Text(value,
              style: TextStyle(
                fontSize: isTotal ? 18 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              )),
        ],
      ),
    );
  }

  Widget _buildEmptyCartUI(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.shopping_cart_outlined,
            size: 100, color: Colors.grey),
        const SizedBox(height: 20),
        const Text('Your cart is empty',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryPurple,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text('Continue Shopping'),
        ),
      ],
    ),
  );
}


class CheckoutPage extends StatelessWidget {

  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Checkout',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 30),

              // Shipping Address
              // Ensure AddAddressPage is imported:
              // import 'package:your_app_path/add_address_page.dart';
              GestureDetector(
                onTap: () {
                  // Navigate to the AddAddressPage when tapped
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const AddEditAddressPage(), // Assuming your page is named AddAddressPage
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(15),
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add Shipping Address',
                        style: TextStyle(fontSize: 16),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ),

              // Ensure AddCardPageSimple is imported
              // import 'package:your_app_path/add_card_page_simple.dart';
              GestureDetector(
                onTap: () {
                  // Navigate to the AddCardPageSimple when tapped
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const AddCardPageSimple(), // Navigate to the simple card form
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(15),
                  margin: const EdgeInsets.only(bottom: 30),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add Payment Method',
                        style: TextStyle(fontSize: 16),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ),
              // Price Details
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  PriceRow(label: 'Subtotal', amount: 200),
                  PriceRow(label: 'Shipping Cost', amount: 8),
                  PriceRow(label: 'Tax', amount: 0),
                  PriceRow(label: 'Total', amount: 208, isBold: true),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  // 🟣 Place Order Button
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurpleAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const OrdersListPage()),
                        );
                      },
                      child: const Text(
                        'Place Order',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // 🟣 Order Page Button
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: () async {
                        await OrderHelper.placeOrder(999); // or your calculated total
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const OrdersPage()),
                        );
                      },
                      child: const Text(
                        'Order Page',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),

            ],
          ),
        ),
      ),
    );
  }
}

class PriceRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isBold;

  const PriceRow({
    super.key,
    required this.label,
    required this.amount,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16)),
          Text(
            '\$$amount',
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }
}



// --- 1. Data Models ---

class OrderStatus {
  final String label;
  final bool isSelected;
  const OrderStatus(this.label, {this.isSelected = false});
}

class OrderItem {
  final int quantity;
  final String productId;

  const OrderItem({
    required this.quantity,
    required this.productId,
  });
}

// --- 2. OrdersListContent (shows live Firestore data) ---

class OrdersListContent extends StatelessWidget {
  final List<OrderStatus> statuses;
  const OrdersListContent({required this.statuses});

  String get _userId => FirebaseAuth.instance.currentUser!.uid;

  // Firestore collection reference (your cart path)
  CollectionReference get _cartCollection => FirebaseFirestore.instance
      .collection('ammu')
      .doc('db')
      .collection('users')
      .doc(_userId)
      .collection('cart')
      .doc('items')
      .collection('products');

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- Status Filter Row ---
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 16.0, top: 10),
          child: SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: statuses.length,
              itemBuilder: (context, index) {
                return StatusFilterChip(status: statuses[index]);
              },
            ),
          ),
        ),

        // --- Live Orders List (from Firestore cart) ---
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _cartCollection.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const EmptyOrdersPage();
              }

              // Convert Firestore docs to OrderItems
              final orders = docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                int quantity = (data['quantity'] is int)
                    ? data['quantity']
                    : int.tryParse(data['quantity'].toString()) ?? 1;

                return OrderItem(
                  quantity: quantity,
                  productId: data['productId'] ?? doc.id,
                );
              }).toList();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.shopping_bag_outlined,
                          size: 36,
                          color: Colors.black87,
                        ),
                        title: Text(
                          order.productId,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          'ID: ${order.productId}\nQuantity: ${order.quantity}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right,
                            color: Colors.black54),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// --- 3. Status Filter Chip ---

class StatusFilterChip extends StatelessWidget {
  final OrderStatus status;
  const StatusFilterChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: RawChip(
        label: Text(status.label),
        labelStyle: TextStyle(
          color: status.isSelected ? Colors.white : Colors.black,
          fontWeight: status.isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        backgroundColor: Colors.grey.shade200,
        selected: status.isSelected,
        selectedColor: primaryPurple,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        onPressed: () => print('Filter by ${status.label} tapped!'),
      ),
    );
  }
}

// --- 4. Empty Orders Page (Shown when no cart items) ---

class EmptyOrdersPage extends StatelessWidget {
  const EmptyOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart_outlined,
                size: 100, color: Colors.black87),
            const SizedBox(height: 24),
            const Text(
              'No Orders Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child: const Text(
                  'Explore Products',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class OrdersListPage extends StatelessWidget {
  const OrdersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    final cartCollection = FirebaseFirestore.instance
        .collection('ammu')
        .doc('db')
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc('items')
        .collection('products');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: Column(
        children: [
          // 🔹 Filter Buttons Row
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: const [
                OrderStatusButton(label: 'Processing', isSelected: true),
                OrderStatusButton(label: 'Shipped'),
                OrderStatusButton(label: 'Delivered'),
                OrderStatusButton(label: 'Returned'),
                OrderStatusButton(label: 'Cancelled'),
              ],
            ),
          ),

          // 🔹 Orders List (unchanged)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: cartCollection.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No orders yet'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final productId = doc.id;
                    final productName = data['name'] ?? 'Product';
                    final quantity = (data['quantity'] is int)
                        ? data['quantity']
                        : int.tryParse(data['quantity'].toString()) ?? 1;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.shopping_bag_outlined, size: 36),
                          title: Text(
                            'Order: $productName',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            '$quantity item${quantity > 1 ? 's' : ''}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          trailing:
                          const Icon(Icons.chevron_right, color: Colors.black54),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OrderDetailsPage(
                                  orderId: productId,
                                ),
                              ),
                            );
                          },
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
    );
  }
}

// 🔹 Simple Reusable Button Widget
class OrderStatusButton extends StatelessWidget {
  final String label;
  final bool isSelected;

  const OrderStatusButton({
    super.key,
    required this.label,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ElevatedButton(
        onPressed: () {
          // Future: implement filtering logic here if needed
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? primaryPurple : Colors.grey.shade200,
          foregroundColor: isSelected ? Colors.white : Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}



class OrderDetailsPage extends StatelessWidget {
  final String orderId;
  const OrderDetailsPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final orderDoc = FirebaseFirestore.instance
        .collection('ammu')
        .doc('db')
        .collection('users')
        .doc(userId)
        .collection('orders')
        .doc(orderId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Order $orderId',
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: primaryDark),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: orderDoc.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final currentStatus = data['status'] ?? 'Order Placed';
          final statusDates =
          Map<String, String>.from(data['statusDates'] ?? {});

          final steps = [
            'Order Placed',
            'Order Confirmed',
            'Shipped',
            'Delivered',
          ];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🟣 Timeline Section
                FixedTimeline.tileBuilder(
                  builder: TimelineTileBuilder.connected(
                    connectionDirection: ConnectionDirection.before,
                    itemCount: steps.length,
                    contentsBuilder: (context, index) {
                      final title = steps[index];
                      final isCompleted =
                          steps.indexOf(currentStatus) >= index;
                      final date = statusDates[title] ?? '';

                      return Padding(
                        padding: const EdgeInsets.only(left: 10.0, bottom: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                color: isCompleted
                                    ? primaryDark
                                    : Colors.grey,
                              ),
                            ),
                            Text(
                              date,
                              style: TextStyle(
                                fontSize: 14,
                                color: isCompleted
                                    ? primaryDark
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    indicatorBuilder: (context, index) {
                      final isCompleted =
                          steps.indexOf(currentStatus) >= index;
                      return DotIndicator(
                        size: 30,
                        color: isCompleted
                            ? primaryPurple
                            : Colors.grey.shade300,
                        child: isCompleted
                            ? const Icon(Icons.check,
                            color: Colors.white, size: 18)
                            : null,
                      );
                    },
                    connectorBuilder: (context, index, type) {
                      final isCompleted =
                          steps.indexOf(currentStatus) > index;
                      return SolidLineConnector(
                        color: isCompleted
                            ? primaryPurple
                            : Colors.grey.shade300,
                        thickness: 2,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 30),

                // 🟢 Order Items
                const Text(
                  'Order Items',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryDark,
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Icon(Icons.shopping_bag_outlined, color: primaryDark),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '1 item',
                          style: TextStyle(fontSize: 16, color: primaryDark),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 📦 Shipping Details
                const Text(
                  'Shipping details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryDark,
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    data['address'] ?? 'No shipping address available.',
                    style: const TextStyle(
                        fontSize: 16, color: primaryDark),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class OrderHelper {
  static Future<void> placeOrder(int totalAmount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final orderRef = FirebaseFirestore.instance
        .collection('ammu')
        .doc('db')
        .collection('users')
        .doc(user.uid)
        .collection('orders')
        .doc();

    await orderRef.set({
      'status': 'Pending',
      'timestamp': FieldValue.serverTimestamp(),
      'total': totalAmount,
    });
  }
}



class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  String _selectedFilter = "All"; // All, Pending, Delivered
  String _sortOrder = "Latest";   // Latest, Oldest

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;


    return Scaffold(
      appBar: AppBar(
        title: const Text("My Orders"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          // 🔍 --- FILTER & SORT CONTROLS ---
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Filter Chips
                Row(
                  children: [
                    _buildFilterChip("All"),
                    const SizedBox(width: 5),
                    _buildFilterChip("Pending"),
                    const SizedBox(width: 5),
                    _buildFilterChip("Delivered"),
                  ],
                ),

                // Sort Dropdown
                DropdownButton<String>(
                  value: _sortOrder,
                  items: const [
                    DropdownMenuItem(value: "Latest", child: Text("Latest")),
                    DropdownMenuItem(value: "Oldest", child: Text("Oldest")),
                  ],
                  onChanged: (value) {
                    setState(() => _sortOrder = value!);
                  },
                ),
              ],
            ),
          ),



          // 🔁 --- ORDERS LIST ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .doc(user!.uid)
                  .collection('userOrders')
                  .orderBy('timestamp', descending: _sortOrder == "Latest")
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                // Apply filter (All / Pending / Delivered)
                final filteredDocs = _selectedFilter == "All"
                    ? docs
                    : docs
                    .where((d) =>
                (d['status'] ?? '').toString() == _selectedFilter)
                    .toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text("No orders found"));
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final order = filteredDocs[index];
                    final status = order['status'] ?? 'Pending';
                    final total = order['total'] ?? 0;
                    final date = (order['timestamp'] as Timestamp?)?.toDate();

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: Text(
                          "Order #${order.id}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Status: $status\nTotal: ₹$total\nDate: ${date != null ? date.toString().substring(0, 16) : '-'}",
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // 🔗 You can reuse your existing OrderDetailsPage here:
                          // Navigator.push(context, MaterialPageRoute(
                          //   builder: (_) => OrderDetailsPage(orderId: order.id),
                          // ));
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => OrderHelper.placeOrder(999), // ✅ call static method
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      ),



    );
  }

  // 🔹 Helper widget for chips
  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.deepPurple,
      backgroundColor: Colors.grey.shade200,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
      ),
      onSelected: (_) => setState(() => _selectedFilter = label),
    );
  }
}