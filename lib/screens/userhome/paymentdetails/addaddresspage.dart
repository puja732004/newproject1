import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:newproject1/screens/userhome/cartitems.dart';


class AddEditAddressPage extends StatefulWidget {
  final String? addressDocId; // null = add, not null = edit
  final Map<String, dynamic>? initialData;

  const AddEditAddressPage({super.key, this.addressDocId, this.initialData});

  @override
  State<AddEditAddressPage> createState() => _AddEditAddressPageState();
}

class _AddEditAddressPageState extends State<AddEditAddressPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _streetController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _zipCodeController;

  final _firestore = FirebaseFirestore.instance;
  final _userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data if editing
    _streetController = TextEditingController(text: widget.initialData?['street'] ?? '');
    _cityController = TextEditingController(text: widget.initialData?['city'] ?? '');
    _stateController = TextEditingController(text: widget.initialData?['state'] ?? '');
    _zipCodeController = TextEditingController(text: widget.initialData?['zipCode'] ?? '');
  }

  @override
  void dispose() {
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  void _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User not logged in.')),
      );
      return;
    }

    final address = {
      'street': _streetController.text,
      'city': _cityController.text,
      'state': _stateController.text,
      'zipCode': _zipCodeController.text,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      if (widget.addressDocId == null) {
        // ADD NEW ADDRESS
        await _firestore.collection('users').doc(_userId).collection('addresses').add(address);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address Added Successfully!')),
        );
      } else {
        // UPDATE EXISTING ADDRESS
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('addresses')
            .doc(widget.addressDocId)
            .update(address);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address Updated Successfully!')),
        );
      }

      // Navigate to AddressPage after saving
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AddressPage()),
            (route) => false, // removes all previous routes
      );

    } catch (e) {
      debugPrint('Error saving address: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to save address: $e')));
    }
  }


  Widget _buildAddressField(TextEditingController controller, String hintText,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
      validator: (value) => value == null || value.isEmpty ? 'Please enter $hintText' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.addressDocId != null;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditMode ? 'Edit Address' : 'Add Address',
          style: const TextStyle(fontWeight: FontWeight.bold, color: primaryDark),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildAddressField(_streetController, 'Street Address'),
              const SizedBox(height: 15),
              _buildAddressField(_cityController, 'City'),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: _buildAddressField(_stateController, 'State')),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildAddressField(
                      _zipCodeController,
                      'Zip Code',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: _saveAddress,
                  child: Text(
                    isEditMode ? 'Update' : 'Save',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: primaryDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddressPage extends StatelessWidget {
  const AddressPage({super.key});

  Stream<QuerySnapshot> _getAddresses() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.empty();

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryDark),
          onPressed: () {
            // Navigate to CheckoutPage
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CheckoutPage()),
            );
          },
        ),
        title: const Text(
          'Address',
          style: TextStyle(fontWeight: FontWeight.bold, color: primaryDark),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: primaryPurple),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditAddressPage()),
              );
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getAddresses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No saved addresses. Add a new one!'));
          }

          final addresses = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final data = addresses[index].data() as Map<String, dynamic>;
              final docId = addresses[index].id;
              final fullAddress =
                  '${data['street'] ?? ''}, ${data['city'] ?? ''}, ${data['state'] ?? ''} ${data['zipCode'] ?? ''}';

              return _AddressTile(
                address: fullAddress,
                onEdit: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEditAddressPage(
                        addressDocId: docId,
                        initialData: data,
                      ),
                    ),
                  );
                },
                onDelete: () async {
                  if (userId == null) return;

                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .collection('addresses')
                        .doc(docId)
                        .delete();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Address Deleted Successfully!')),
                    );
                    // No need to manually remove from the list; StreamBuilder updates automatically
                  } catch (e) {
                    debugPrint('Error deleting address: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete address: $e')),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  final String address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AddressTile({
    super.key,
    required this.address,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              address,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: primaryDark,
              ),
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: onEdit,
                child: const Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryPurple,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onDelete,
                child: const Text(
                  'Delete',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

