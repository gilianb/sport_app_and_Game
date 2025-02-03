//import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final FirestoreService firestoreService = FirestoreService();
  //bool _hasInternet = true;

  /*@override
  void initState() {
    super.initState();
    _checkInternetConnection();
  }
*/
  /*Future<void> _checkInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _hasInternet = connectivityResult != ConnectivityResult.none;
    });
  }*/

  void _login() async {
    /*if (!_hasInternet) {
      _showErrorDialog("No internet connection. Please try again.");
      return;
    }*/

    final username = usernameController.text;
    final password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showErrorDialog("Please enter both username and password.");
      return;
    }

    final isValid = await firestoreService.validateUser(username, password);
    final userid = await firestoreService.GetUserID(username, password);

    if (isValid) {
      _navigateToHome(username, userid);
    } else {
      _showErrorDialog("Invalid username or password. Or create an account.");
    }
  }

  void _continueAsGuest() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyHomePage(title: 'Guest Mode', id: 'guest'),
      ),
    );
  }

  void _navigateToHome(String username, String? userid) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MyHomePage(title: 'Welcome back, $username!', id: userid),
      ),
    );
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegisterScreen(),
      ),
    );
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
        title: const Text(
          'Game Sport Login Screen',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: const Color(0xFFBFD9E7),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/login_screen.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Login to your Sports Game App',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
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
                  onPressed: _login,
                  child: const Text('Login'),
                ),
                TextButton(
                  onPressed: _navigateToRegister,
                  child: const Text('Create an Account'),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _continueAsGuest,
                  child: const Text('Continue as Guest'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
