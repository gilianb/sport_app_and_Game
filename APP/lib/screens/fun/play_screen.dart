import 'package:flutter/material.dart';
import 'package:sport_app/screens/fun/game_screen.dart';
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
