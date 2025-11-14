import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isLoading = false;

  // 🔔 Show message helper
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // 🔐 Register function (user only)
  Future<void> _register() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage("Please fill in all fields!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ Create Firebase user
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ✅ Store user info with fixed "user" role
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'name': name,
        'email': email,
        'role': 'user', // fixed role
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showMessage("Account created successfully!");
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String errorMsg;
      switch (e.code) {
        case 'email-already-in-use':
          errorMsg = "Email is already in use.";
          break;
        case 'invalid-email':
          errorMsg = "Invalid email format.";
          break;
        case 'weak-password':
          errorMsg = "Password should be at least 6 characters.";
          break;
        default:
          errorMsg = "Signup failed: ${e.message}";
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
            "Sign Up" ,
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.person_add, size: 80, color: Colors.deepPurpleAccent),
              const SizedBox(height: 20),

              // 👤 Name Field
              TextField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: "Full Name",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // ✉️ Email Field
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // 🔒 Password Field
              TextField(
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // 🟢 Signup Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.deepPurpleAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.deepPurpleAccent)
                    : const Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,color: Colors.black
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 🔁 Go to Login
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Already have an account? Login",
                  style: TextStyle(color: Colors.deepPurpleAccent, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
