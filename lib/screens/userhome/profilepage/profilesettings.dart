import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cartitems.dart';

const Color buttonPurple = Color(0xFF9b59b6);
const Color primaryDark = Color(0xFF9b59b6);
const Color PrimaryPurple = Color(0xFF9b59b6);


class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic>? existingData;
  const EditProfilePage({super.key, this.existingData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late TextEditingController nameCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController dobCtrl;
  String? gender;
  File? _imageFile;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.existingData?['name']);
    phoneCtrl = TextEditingController(text: widget.existingData?['phone']);
    dobCtrl = TextEditingController(text: widget.existingData?['dob']);
    gender = widget.existingData?['gender'];
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String? imageUrl = widget.existingData?['imageUrl'];

    // 🔹 Upload image if new
    if (_imageFile != null) {
      final ref = FirebaseStorage.instance.ref().child('profile_images/${user.uid}.jpg');
      await ref.putFile(_imageFile!);
      imageUrl = await ref.getDownloadURL();
    }

    // 🔹 Prepare user data
    final userData = {
      'uid': user.uid,
      'email': user.email,
      'name': nameCtrl.text.trim(),
      'phone': phoneCtrl.text.trim(),
      'dob': dobCtrl.text.trim(),
      'gender': gender,
      'imageUrl': imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // 🔹 Save to Firestore (auto create/update)
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      userData,
      SetOptions(merge: true),
    );

    setState(() => _isSaving = false);
    Navigator.pop(context); // return to profile page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(color: primaryDark)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: primaryDark),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // 🔹 Profile Image Picker
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : (widget.existingData?['imageUrl'] != null
                        ? NetworkImage(widget.existingData!['imageUrl'])
                        : null) as ImageProvider?,
                    child: _imageFile == null && widget.existingData?['imageUrl'] == null
                        ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                        : null,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // 🔹 Name
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v!.isEmpty ? 'Enter name' : null,
              ),

              // 🔹 Email (read-only)
              TextFormField(
                initialValue: FirebaseAuth.instance.currentUser?.email ?? '',
                decoration: const InputDecoration(labelText: 'Email'),
                readOnly: true,
              ),

              // 🔹 Phone
              TextFormField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),

              // 🔹 Date of Birth
              TextFormField(
                controller: dobCtrl,
                readOnly: true,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    dobCtrl.text =
                    "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                  }
                },
                decoration: const InputDecoration(labelText: 'Date of Birth'),
              ),

              // 🔹 Gender Dropdown
              DropdownButtonFormField<String>(
                value: gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (val) => setState(() => gender = val),
              ),

              const SizedBox(height: 30),

              // 🔹 Save Button
              ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Profile',
                    style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class AddressPage extends StatefulWidget {
  const AddressPage({super.key});

  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();

  // Saved address data (to display below form)
  Map<String, String> savedAddress = {};

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  // Load saved address from SharedPreferences
  Future<void> _loadAddress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedAddress = {
        'house': prefs.getString('house') ?? '',
        'place': prefs.getString('place') ?? '',
        'village': prefs.getString('village') ?? '',
        'post': prefs.getString('post') ?? '',
        'city': prefs.getString('city') ?? '',
        'pincode': prefs.getString('pincode') ?? '',
        'district': prefs.getString('district') ?? '',
        'state': prefs.getString('state') ?? '',
        'country': prefs.getString('country') ?? '',
      };

      _houseController.text = savedAddress['house']!;
      _placeController.text = savedAddress['place']!;
      _villageController.text = savedAddress['village']!;
      _postController.text = savedAddress['post']!;
      _cityController.text = savedAddress['city']!;
      _pincodeController.text = savedAddress['pincode']!;
      _districtController.text = savedAddress['district']!;
      _stateController.text = savedAddress['state']!;
      _countryController.text = savedAddress['country']!;
    });
  }

  // Save address to SharedPreferences
  Future<void> _saveAddress() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('house', _houseController.text);
      await prefs.setString('place', _placeController.text);
      await prefs.setString('village', _villageController.text);
      await prefs.setString('post', _postController.text);
      await prefs.setString('city', _cityController.text);
      await prefs.setString('pincode', _pincodeController.text);
      await prefs.setString('district', _districtController.text);
      await prefs.setString('state', _stateController.text);
      await prefs.setString('country', _countryController.text);

      // ✅ Update UI immediately
      setState(() {
        savedAddress = {
          'house': _houseController.text,
          'place': _placeController.text,
          'village': _villageController.text,
          'post': _postController.text,
          'city': _cityController.text,
          'pincode': _pincodeController.text,
          'district': _districtController.text,
          'state': _stateController.text,
          'country': _countryController.text,
        };
      });

      // ✅ Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Address saved successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      validator: (value) =>
      value == null || value.isEmpty ? 'Please enter $label' : null,
    );
  }

  // 🏡 Widget to display saved address below form
  Widget _buildSavedAddressView() {
    if (savedAddress.values.every((v) => v.isEmpty)) {
      return const Text("No saved address yet.",
          style: TextStyle(fontSize: 16, color: Colors.grey));
    }

    return Card(
      margin: const EdgeInsets.only(top: 20),
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("📍 Saved Address",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("${savedAddress['house']}, ${savedAddress['place']}"),
            Text("${savedAddress['village']}, ${savedAddress['post']}"),
            Text("${savedAddress['city']} - ${savedAddress['pincode']}"),
            Text("${savedAddress['district']}, ${savedAddress['state']}"),
            Text("${savedAddress['country']}"),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Addresses'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField('House Name / Number', _houseController),
              _buildTextField('Place Name', _placeController),
              _buildTextField('Village / Panchayath', _villageController),
              _buildTextField('Post Office', _postController),
              _buildTextField('City', _cityController),
              _buildTextField('Pin Code', _pincodeController),
              _buildTextField('District', _districtController),
              _buildTextField('State', _stateController),
              _buildTextField('Country', _countryController),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Save Address',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              const SizedBox(height: 30),
              _buildSavedAddressView(), // 👇 show saved address below
            ],
          ),
        ),
      ),
    );
  }
}


class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My Wishlist')),
    body: const Center(child: Text("Wishlist UI")),
  );
}
class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Payment Methods')),
    body: const Center(child: Text("Payment Management UI")),
  );
}
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Help Center')),
    body: const Center(child: Text("Help/FAQ UI")),
  );
}
class SupportPage extends StatelessWidget {
  const SupportPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Customer Support')),
    body: const Center(child: Text("Support Contact UI")),
  );
}


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    if (doc.exists) {
      setState(() => userData = doc.data());
    }
  }

  Widget _buildProfileHeader(BuildContext context) {
    if (userData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      margin: const EdgeInsets.only(top: 20),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 🔹 User Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userData!['name'] ?? 'Your Name',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userData!['email'] ?? '',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                userData!['phone'] ?? '',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              if (userData!['dob'] != null)
                Text(
                  "DOB: ${userData!['dob']}",
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              if (userData!['gender'] != null)
                Text(
                  "Gender: ${userData!['gender']}",
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
            ],
          ),

          // 🔹 Edit Button
          TextButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfilePage(existingData: userData!),
                ),
              );
              _loadUserData(); // refresh after editing
            },
            child: const Text(
              'Edit',
              style: TextStyle(
                color: primaryPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(BuildContext context,
      {required String title, required Widget targetPage}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          color: primaryDark,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => targetPage));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = userData?['imageUrl'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🔹 Profile Picture
            Container(
              margin: const EdgeInsets.only(top: 0, bottom: 20),
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade200,
                image: imageUrl != null
                    ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                    : null,
              ),
              child: imageUrl == null
                  ? const Icon(Icons.person, size: 50, color: Colors.grey)
                  : null,
            ),

            _buildProfileHeader(context),
            const SizedBox(height: 30),

            // 🔹 Settings List
            Column(
              children: [
                _buildSettingTile(context, title: 'Address', targetPage: const AddressPage()),
                const Divider(color: Colors.grey, height: 1),
                _buildSettingTile(context, title: 'Wishlist', targetPage: const WishlistPage()),
                const Divider(color: Colors.grey, height: 1),
                _buildSettingTile(context, title: 'Payment', targetPage: const PaymentPage()),
                const Divider(color: Colors.grey, height: 1),
                _buildSettingTile(context, title: 'Help', targetPage: const HelpPage()),
                const Divider(color: Colors.grey, height: 1),
                _buildSettingTile(context, title: 'Support', targetPage: const SupportPage()),
                const Divider(color: Colors.grey, height: 1),
              ],
            ),

            const SizedBox(height: 50),

            // 🔹 Sign Out
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
              child: const Text(
                'Sign Out',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}