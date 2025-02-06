import 'package:flutter/material.dart';

class RulesPage extends StatelessWidget {
  final String title;
  final String? id;

  const RulesPage({super.key, required this.title, this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 15, 91, 124),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "How to Play",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "1.	Set Up the Buzzers  Arrange the buzzers in a square as shown below. Pay attention to the numbers on each buzzer!\n"
              "2.	Start the Game Once the game begins, a light will turn on. Sprint to the corresponding buzzer and hit it as fast as you can!\n"
              "3.	Beat the Clock  You have 1 minute to tap as many buzzers as possible.\n"
              "4.	Game Over – When the last buzzer turns off, the game is done. Don’t forget to check your stats!\n"
              "5.	Have Fun & Break a Sweat",
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            const Text(
              "How to Place the Boxes",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Image.asset(
                'assets/place_the_box.jpg',
                width: 300, // Set a fixed width
                height: 200, // Set a fixed height
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Differents modes of the game",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "• Exercise mode is a run mode where you need space at least a 10 meter square\n"
              "• Fun mode is a mode where you can chose the distance between the different buzzers\n Stats are not kept just and enjoy !\n"
              "• Duel Mode challenge your friends and show them who is the best",
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 15, 91, 124),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: const Text(
                  "Back to Menu",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
