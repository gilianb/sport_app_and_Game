import 'package:flutter/material.dart';
import 'dart:async';

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key, this.id, required this.remainTime});
  final String? id;
  final Duration remainTime;

  @override
  State<PlayScreen> createState() => PlayScreenState();
}

class PlayScreenState extends State<PlayScreen> {
  late Duration _remainingTime; // Temps restant pour le compte à rebours
  Timer? _timer; // Timer pour le compte à rebours
  bool _waitingForESP = false; // Indique si on attend un message de l'ESP

  @override
  void initState() {
    super.initState();
    _remainingTime = widget.remainTime;
    _startCountdown();
  }

  /// Démarre le compte à rebours
  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds <= 0) {
        setState(() {
          _timer?.cancel();
          _waitingForESP = true;
        });
        _waitForESP();
      } else {
        setState(() {
          _remainingTime -= const Duration(seconds: 1);
        });
      }
    });
  }

  /// Simule l'attente d'un message de l'ESP
  Future<void> _waitForESP() async {
    // Simule la réception d'un message après 5 secondes
    await Future.delayed(const Duration(seconds: 5));

    // Une fois le message reçu, revenir à la page ExercisePage
    if (mounted) {
      Navigator.pop(context); // Retour à l'écran précédent
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // Annule le timer lorsqu'on quitte l'écran
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Play Screen"),
        backgroundColor: const Color.fromARGB(255, 15, 91, 124),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/running_track.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: _waitingForESP
              ? const Text(
                  "Waiting for ESP message...",
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Time Remaining",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _formatDuration(_remainingTime),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.orangeAccent,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  /// Formate une durée en `mm:ss`
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}
