import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sport_app/screens/fun/game_screen.dart';
//import 'package:sport_app/screens/exercise/play_screen.dart';
import 'package:sport_app/screens/scan_screen.dart';
import '../../utils/bluetooth_device_provider';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class FunPage extends StatefulWidget {
  const FunPage({super.key, required this.title, required this.id});
  final String title;
  final String? id;

  @override
  State<FunPage> createState() => FunPageState();
}

class FunPageState extends State<FunPage> {
  final List<Map<String, dynamic>> performanceHistory = [];

  void CheckConn() async {
    final provider =
        Provider.of<BluetoothDeviceProvider>(context, listen: false);
    final connectedDevice = provider.connectedDevice;

    if (connectedDevice == null) {
      _showDialog("Error", "No device connected.");
      return;
    }

    try {
      List<BluetoothService> services =
          await connectedDevice.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write &&
              characteristic.properties.read) {
            await characteristic.write([1], withoutResponse: false);
            await characteristic.write([0], withoutResponse: false);

            /*List<int> response = await characteristic.read();

            if (response.isNotEmpty && response[0] == 0) {
              _showDialog("Connection OK", "ESP32 responded correctly.");
            } else {
              _showDialog("Error", "ESP32 response incorrect.");
            }*/
            return;
          }
        }
      }
      _showDialog("Error", "No valid characteristic found.");
    } catch (e) {
      _showDialog("Error", "Failed to communicate with ESP32: $e");
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _navigateToBluetooth() async {
    // Navigue vers l'écran Bluetooth et récupère l'appareil connecté
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ScanScreen(),
      ),
    );
  }

  void _navigateToGame(connected_device) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          remainTime: Duration(seconds: 60),
          id: widget.id,
          device: connected_device,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BluetoothDeviceProvider>(context);
    final connectedDevice = provider.connectedDevice;

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
                image: AssetImage('assets/exercise.jpg'),
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
                  'Push your limits! but with fun',
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
                // Section Bluetooth
                if (connectedDevice != null) ...[
                  Text(
                    'Connected to: ${connectedDevice.name}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Device ID: ${connectedDevice.remoteId}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ] else ...[
                  const Text(
                    'No device connected',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.red,
                    ),
                  ),
                ],
                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: () async {
                    if (connectedDevice == null) {
                      //if no device connected show error
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("No Device Connected"),
                            content: const Text(
                                "Please connect to a device first before starting the exercise."),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text("OK"),
                              ),
                            ],
                          );
                        },
                      );
                    } else {
                      CheckConn(); //send 1 to ESP
                      _navigateToGame(connectedDevice); //start the countdown
                    }
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
                  onPressed: _navigateToBluetooth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                  ),
                  child: const Text(
                    'Connect to Bluetooth',
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
