import 'package:flutter/material.dart';

class FunPage extends StatefulWidget {
  const FunPage({super.key, required this.title});

  final String title;

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  @override
  State<FunPage> createState() => FunPageState();
}

class FunPageState extends State<FunPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 15, 91, 124),
          title: Text(
            widget.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          )),
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    'assets/running_track.jpg'), // Add this image to your assets folder
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Content Overlay
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Motivational Text
                const Text(
                  'Push your limits!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Progress Indicator (Static for now)
                const Text(
                  'remain time: 15 min',
                  style: TextStyle(
                    fontSize: 20,
                    color: Color.fromARGB(255, 134, 68, 68),
                  ),
                ),
                const SizedBox(height: 40),
                // Start Game Button
                ElevatedButton(
                  onPressed: () {
                    // Add your START GAME logic here
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 32.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    backgroundColor: Colors.orangeAccent,
                    elevation: 5.0,
                  ),
                  child: const Text(
                    'START RUN',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add action for incrementing
        },
        tooltip: 'Track Progress',
        child: const Icon(Icons.directions_run),
      ),
    );
  }
}
