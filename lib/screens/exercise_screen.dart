import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key, required this.title, required this.id});

  final String title;
  final String? id;

  @override
  State<ExercisePage> createState() => ExercisePageState();
}

class ExercisePageState extends State<ExercisePage> {
  final List<Map<String, dynamic>> performanceHistory = [];

  void _addPerformance() {
    final TextEditingController dateController = TextEditingController();
    final TextEditingController distanceController = TextEditingController();
    final TextEditingController timeController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Add Performance"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: dateController,
                  decoration:
                      const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
                ),
                TextField(
                  controller: distanceController,
                  decoration: const InputDecoration(labelText: 'Distance (km)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: timeController,
                  decoration:
                      const InputDecoration(labelText: 'Time (hh:mm:ss)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (dateController.text.isNotEmpty &&
                    distanceController.text.isNotEmpty &&
                    timeController.text.isNotEmpty) {
                  final performance = {
                    'date': dateController.text,
                    'distance': double.parse(distanceController.text),
                    'time': timeController.text,
                    //'timestamp': Timestamp.now(),
                  };

                  // Mise à jour Firestore
                  final userRef = FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget
                          .id); // Remplacez 'username' par l'ID utilisateur
                  final userDoc = await userRef.get();

                  if (userDoc.exists) {
                    await userRef.update({
                      'performanceHistory':
                          FieldValue.arrayUnion([performance]),
                    });
                  } else {
                    await userRef.set({
                      'username': 'username', // Remplacez par l'ID utilisateur
                      'password': 'password', // Remplacez par le mot de passe
                      'performanceHistory': [performance],
                    });
                  }

                  Navigator.of(context).pop();
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
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
        ),
      ),
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/running_track.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Content Overlay
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                const Text(
                  'remain time: 15 min',
                  style: TextStyle(
                    fontSize: 20,
                    color: Color.fromARGB(255, 134, 68, 68),
                  ),
                ),
                const SizedBox(height: 40),
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
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _addPerformance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                  ),
                  child: const Text(
                    'Add Performance',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
