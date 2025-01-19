import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:sport_app/screens/play_screen.dart';
import 'package:sport_app/screens/scan_screen.dart';
import '../utils/bluetooth_device_provider';
import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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
                    //DateTime now = new DateTime.now();
                    //DateTime date = new DateTime(now.year, now.month, now.day);
                  };

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

  void _navigateToBluetooth() async {
    // Navigue vers l'écran Bluetooth et récupère l'appareil connecté
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ScanScreen(),
      ),
    );
  }

  void _navigateToPlay() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PlayScreen(
          remainTime: Duration(seconds: 10), // Exemple : 15 minutes
        ),
      ),
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
            List<int> value = await c.read();
            print('value : $value');
            print('characteristique : $c');
          }
        }
      }
    });
  }

  Future write_to_ESP(device) async {
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
                  'Remain time: 15 min',
                  style: TextStyle(
                    fontSize: 20,
                    color: Color.fromARGB(255, 134, 68, 68),
                  ),
                ),
                const SizedBox(height: 40),

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
                      await write_to_ESP(connectedDevice); //send 1 to ESP
                      _navigateToPlay(); //start the countdown
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
                  onPressed: _addPerformance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                  ),
                  child: const Text(
                    'Add Performance',
                    style: TextStyle(color: Colors.white),
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
