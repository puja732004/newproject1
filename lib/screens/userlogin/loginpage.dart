import 'dart:math';

import '../userhome/homepage.dart';
import 'signuppage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _login() async {
    final email = _email.text.trim();
    final password = _password.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage("Please enter both email and password!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ Firebase Authentication Login
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        _showMessage("Login failed — user not found.");
        return;
      }

      // ✅ Save or Update User Info inside nested path:
      // users/{uid}/ammu/{uid}
      final userDoc = FirebaseFirestore.instance
          .collection('ammu')
          .doc("db")
          .collection('users')
          .doc(user.uid);

      await userDoc.set({
        'email': user.email,
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _showMessage("Welcome back, ${user.email}!");

      // ✅ Navigate to Homepage
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePageUI()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg;
      switch (e.code) {
        case 'user-not-found':
          errorMsg = "No user found for that email.";
          break;
        case 'wrong-password':
          errorMsg = "Incorrect password.";
          break;
        case 'invalid-email':
          errorMsg = "Invalid email format.";
          break;
        default:
          errorMsg = "Login failed: ${e.message}";
      }
      _showMessage(errorMsg);
    } catch (e) {
      _showMessage("An unexpected error occurred: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white70,
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent,
        title: const Text(
          "Login",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.storefront, size: 90, color: Colors.deepPurpleAccent),
              const SizedBox(height: 20),
              const Text(
                "ZyloMart",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.deepPurple,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Welcome Back!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 40),

              // ✉️ Email Field
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: const Icon(Icons.email, color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white38,
                ),
              ),
              const SizedBox(height: 20),


// 🔒 Password Field with Eye Icon on Left
              TextField(
                controller: _password,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.black54,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white38,
                ),
              ),
              const SizedBox(height: 10),

// 🔑 Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                    );
                  },
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: Colors.deepPurpleAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // 🔘 Login Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                  "Login",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 🧾 Register Navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don’t have an account? ",
                    style: TextStyle(color: Colors.deepPurpleAccent),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SignUpPage()),
                      );
                    },
                    child: const Text(
                      "Create one",
                      style: TextStyle(
                        color: Colors.deepPurpleAccent,
                        fontWeight: FontWeight.bold,
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

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _inputController = TextEditingController();

  void _goToOtp() {
    final input = _inputController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please enter your email or phone.")));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OtpVerificationPage(userInput: input)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Forgot Password"),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter your registered Email or Phone number",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _inputController,
              decoration: InputDecoration(
                labelText: "Email or Phone",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: _goToOtp,
              child: const Text("Next", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class OtpVerificationPage extends StatefulWidget {
  final String userInput;
  const OtpVerificationPage({super.key, required this.userInput});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  late String _generatedOtp;
  final List<TextEditingController> _otpControllers =
  List.generate(6, (_) => TextEditingController());

  @override
  void initState() {
    super.initState();
    _generatedOtp = _generateOtp();

    // ✅ Run after the first frame so context is safe to use
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendOtp(widget.userInput, _generatedOtp);
      _autoFillOtp(_generatedOtp);
    });
  }

  String _generateOtp() {
    final rand = Random();
    return List.generate(6, (_) => rand.nextInt(10).toString()).join();
  }

  void _sendOtp(String destination, String otp) {
    // ✅ In real app: integrate email or SMS OTP send
    debugPrint("Sending OTP $otp to $destination");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("OTP sent to ${widget.userInput}")),
    );
  }

  void _autoFillOtp(String otp) async {
    await Future.delayed(const Duration(seconds: 2));
    for (int i = 0; i < 6; i++) {
      _otpControllers[i].text = otp[i];
    }
  }

  void _verifyOtp() {
    final enteredOtp = _otpControllers.map((c) => c.text).join();
    if (enteredOtp == _generatedOtp) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateNewPasswordPage(email: widget.userInput),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid OTP. Try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify OTP"),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const Text("Enter the 6-digit OTP sent to your email/phone"),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                6,
                    (i) => SizedBox(
                  width: 40,
                  child: TextField(
                    controller: _otpControllers[i],
                    maxLength: 1,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      counterText: "",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: _verifyOtp,
              child: const Text("Next", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateNewPasswordPage extends StatefulWidget {
  final String email;
  const CreateNewPasswordPage({super.key, required this.email});

  @override
  State<CreateNewPasswordPage> createState() => _CreateNewPasswordPageState();
}

class _CreateNewPasswordPageState extends State<CreateNewPasswordPage> {
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _showNew = false;
  bool _showConfirm = false;
  bool _isLoading = false;

  Future<void> _resetPassword() async {
    final newPass = _newPassword.text.trim();
    final confirmPass = _confirmPassword.text.trim();

    if (newPass.isEmpty || confirmPass.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("All fields required")));
      return;
    }

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ Firebase reset link (email only)
      await FirebaseAuth.instance.sendPasswordResetEmail(email: widget.email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset link sent to your email")),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Loginpage()),
            (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create New Password"),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            TextField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Email",
                hintText: widget.email,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _newPassword,
              obscureText: !_showNew,
              decoration: InputDecoration(
                labelText: "New Password",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: IconButton(
                  icon: Icon(_showNew ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _showNew = !_showNew),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _confirmPassword,
              obscureText: !_showConfirm,
              decoration: InputDecoration(
                labelText: "Confirm Password",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: IconButton(
                  icon: Icon(_showConfirm ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _showConfirm = !_showConfirm),
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: _isLoading ? null : _resetPassword,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Next", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Wishlist"),
        backgroundColor: Colors.orange,
      ),
      body: const Center(
        child: Text(
          "💖 Your Wishlist items will appear here.",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}


class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search"),
        backgroundColor: Colors.orange,
      ),
      body: const Center(
        child: Text(
          "🔍 Search your favorite foods here.",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}


class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Loginpage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.orange,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              user?.email ?? "Unknown User",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}