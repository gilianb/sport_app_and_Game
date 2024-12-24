import 'package:flutter/material.dart';
import 'exercise_screen.dart';
import 'fun_screen.dart';
import 'statistics_screen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.id});

  final String title;
  final String? id;

  @override
  State<MyHomePage> createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  void navigateToMode(String subtitle, String? id) {
    if (subtitle == 'Exercise') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExercisePage(
              title: ' $subtitle Mode',
              id: id), // Replace with different pages if needed
        ),
      );
    } else if (subtitle == 'Statistics') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StatisticsPage(
              title:
                  ' $subtitle Mode'), // Replace with different pages if needed
        ),
      );
    } else if (subtitle == 'Fun time') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FunPage(
              title:
                  ' $subtitle Mode'), // Replace with different pages if needed
        ),
      );
    }
  }

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
                image: AssetImage('assets/login_screen.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Content Overlay
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "Choose a Mode",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    children: [
                      _buildModeCard("Mode 1", Icons.directions_run, "Exercise",
                          widget.id),
                      _buildModeCard(
                          "Mode 2", Icons.sports_soccer, "Fun time", widget.id),
                      _buildModeCard(
                          "Mode 3", Icons.query_stats, "Statistics", widget.id),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard(
      String title, IconData icon, String subtitle, String? id) {
    return GestureDetector(
      onTap: () => navigateToMode(subtitle, id),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 4.0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 50, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
