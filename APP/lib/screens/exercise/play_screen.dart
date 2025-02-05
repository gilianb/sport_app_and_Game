import 'package:flutter/material.dart';
import 'package:sport_app/screens/exercise/game_screen.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen(
      {super.key,
      required this.id,
      required this.remainTime,
      required this.device});
  final String? id;
  final Duration remainTime;
  final BluetoothDevice? device;

  @override
  State<PlayScreen> createState() => PlayScreenState();
}

class PlayScreenState extends State<PlayScreen> {
  List<int> ESP_read_value = List.empty();
  int _selectedGameTime = 10; // default 1 minute
  int _selectedButtonCount = 4; // default 4 buttons

  @override
  void initState() {
    super.initState();
  }

  /* Future write_to_ESP(device) async {
    // Lit toutes les caractéristiques
    List<BluetoothService> services = await device.discoverServices();
    services.forEach((service) async {
      var characteristics = service.characteristics;
      for (BluetoothCharacteristic c in characteristics) {
        if (c.properties.write) {
          await c
              .write([1], withoutResponse: c.properties.writeWithoutResponse);
          if (c.properties.read) {
            List<int> a = await c.read();
            print(a);
          }
        }
      }
    });
  }*/

  void _showGameSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Game Settings"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Select Game Duration"),
              DropdownButton<int>(
                value: _selectedGameTime,
                items: const [
                  DropdownMenuItem(value: 10, child: Text("10 seconds")),
                  DropdownMenuItem(value: 30, child: Text("30 seconds")),
                  DropdownMenuItem(value: 60, child: Text("1 minute")),
                  DropdownMenuItem(value: 120, child: Text("2 minutes")),
                  DropdownMenuItem(value: 300, child: Text("5 minutes")),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedGameTime = value!;
                  });
                },
              ),
              const SizedBox(height: 20),
              const Text("Select Number of Buttons"),
              DropdownButton<int>(
                value: _selectedButtonCount,
                items: const [
                  DropdownMenuItem(value: 2, child: Text("2 buttons")),
                  DropdownMenuItem(value: 3, child: Text("3 buttons")),
                  DropdownMenuItem(value: 4, child: Text("4 buttons")),
                  DropdownMenuItem(value: 5, child: Text("5 buttons")),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedButtonCount = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToGame();
              },
              child: const Text("Start the Game"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _navigateToGame() async {
    List<BluetoothService>? services = await widget.device?.discoverServices();
    for (var service in services!) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.write && characteristic.properties.read) {
          await characteristic
              .write([1], withoutResponse: false); // 1 for exercise mode
        }
      }
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          remainTime: Duration(seconds: _selectedGameTime),
          id: widget.id,
          device: widget.device,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Play Screen"),
        backgroundColor: const Color.fromARGB(255, 15, 91, 124),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _showGameSettingsDialog,
          child: const Text("Configure and Start Game"),
        ),
      ),
    );
  }
}



/*import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key, this.id, required this.remainTime});
  final String? id;
  final Duration remainTime;

  @override
  State<PlayScreen> createState() => PlayScreenState();
}

class PlayScreenState extends State<PlayScreen> {
  late Duration _remainingTime;
  Timer? _timer;
  bool _waitingForESP = false;
  List<int> ESP_read_value = List.empty();
  int _selectedGameTime = 60; // default 1 minute
  int _selectedButtonCount = 4; // default 2 boutons

  @override
  void initState() {
    super.initState();
    _remainingTime = widget.remainTime;
    _startCountdown();
  }

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

  void _showGameSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Game Settings"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Select Game duration"),
              DropdownButton<int>(
                value: _selectedGameTime,
                items: const [
                  DropdownMenuItem(value: 60, child: Text("1 minute")),
                  DropdownMenuItem(value: 120, child: Text("2 minutes")),
                  DropdownMenuItem(value: 300, child: Text("5 minutes")),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedGameTime = value!;
                  });
                },
              ),
              const SizedBox(height: 20),
              const Text("Sélect number of buttons :"),
              DropdownButton<int>(
                value: _selectedButtonCount,
                items: const [
                  DropdownMenuItem(value: 2, child: Text("2 buttons")),
                  DropdownMenuItem(value: 3, child: Text("3 buttons")),
                  DropdownMenuItem(value: 4, child: Text("4 buttons")),
                  DropdownMenuItem(value: 5, child: Text("5 buttons")),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedButtonCount = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToGame();
              },
              child: const Text("Start the Game"),
            ),
          ],
        );
      },
    );
  }

  Future read_from_ESP(device) async {
    List<BluetoothService> services = await device.discoverServices();
    services.forEach((service) async {
      var characteristics = service.characteristics;
      Guid chara = Guid("beb5483e-36e1-4688-b7f5-ea07361b26a8");

      for (BluetoothCharacteristic c in characteristics) {
        if (c.characteristicUuid == chara) {
          if (c.properties.read) {
            ESP_read_value = await c.read();
          }
        }
      }
    });
  }

  void _navigateToGame() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayScreen(
          remainTime: Duration(seconds: _selectedGameTime),
          id: widget.id,
        ),
      ),
    );
  }

  Future<void> _waitForESP() async {
    if (ESP_read_value.isNotEmpty && ESP_read_value[0] == 0) {
      //show Game is about to start
      _showGameSettingsDialog();
    } else {
      Navigator.pop(context); // go back if something wrong
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // cancel the timer
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
*/