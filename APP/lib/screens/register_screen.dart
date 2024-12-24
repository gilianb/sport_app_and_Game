import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/user.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final FirestoreService firestoreService = FirestoreService();
  bool isLoading = false; // Loading state

  void _register() async {
    final username = usernameController.text;
    final password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showErrorDialog('Please enter both username and password.');
      return;
    }

    setState(() {
      isLoading = true; // Show loading indicator
    });

    try {
      final user = User(username: username, password: password);
      await firestoreService.addUser(user);

      setState(() {
        isLoading = false; // Hide loading indicator
      });

      Navigator.pop(context); // Go back on success
    } catch (e) {
      setState(() {
        isLoading = false; // Hide loading indicator
      });

      // Handle specific errors
      if (e.toString().contains('User already exists')) {
        _showErrorDialog('User already exists. Please try another username.');
      } else {
        _showErrorDialog('Failed to connect. Please check your connection.');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create an Account'),
        backgroundColor: const Color.fromARGB(255, 47, 57, 198),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(), // Loading spinner
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Register for Sports Game App',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: false,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _register,
                    child: const Text('Register'),
                  ),
                ],
              ),
      ),
    );
  }
}
