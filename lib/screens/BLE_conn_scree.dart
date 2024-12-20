import 'dart:async';
//import 'package:flutter/cupertino.dart';
//import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
//import 'package:provider/provider.dart';
//import 'package:flutter_spinkit/flutter_spinkit.dart';

//------------------------------------------------------------------------------------------------------------//
//----------------------------------------BLE Connection Class------------------------------------------------//
//------------------------------------------------------------------------------------------------------------//

class BLE_Connection extends ChangeNotifier {
  BLE_Connection._privateConstructor();
  static final BLE_Connection _instance = BLE_Connection._privateConstructor();

  factory BLE_Connection() {
    return _instance;
  }
  final FlutterBluePlus flutterblueplus = FlutterBluePlus();
  List<ScanResult> devices = [];
  BluetoothDevice? esp_device;
  BluetoothCharacteristic? characteristic;
  StreamSubscription<List<int>>? subscription;
  StreamSubscription<BluetoothDeviceState>? connectedSubscription;
  bool isScanning = false;
  bool isNotified = false;
  List<int> read_value = [15, 10];

//--------------------------------------------Check if Bluetooth is Activated------------------------------//
  Future<bool> initBluetooth() async {
    return await FlutterBluePlus.isOn;
  }

//-------------------------------------------Looking for ESP32 Device---------------------------------------//
  Future<String> scan() async {
    if (esp_device != null) {
      return "You are already connected to the device";
    }
    devices.clear();
    FlutterBluePlus.scan().listen((res) {
      if (!devices.contains(res)) {
        devices.add(res);
      }
    });
    await Future.delayed(const Duration(seconds: 2));
    FlutterBluePlus.stopScan();
    devices.forEach((scan_res) {
      if (scan_res.device.name == "ESP32") {
        esp_device = scan_res.device;
      }
    });
    if (esp_device == null) {
      return "Device is not found\n Please make\n sure you turn\n on the main device";
    }
    return "";
  }

//----------------------------------------Connect to The ESP32 and Listen for Norifications--------------------------------//

  Future<String> connectToDevice() async {
    try {
      await esp_device!.connect();
      connectedSubscription = esp_device!.state.listen((s) {
        if ((s == BluetoothDeviceState.disconnected) ||
            (s == BluetoothDeviceState.disconnecting)) {
          esp_device!.disconnect();
          esp_device = null;
          notifyListeners();
        }
      }) as StreamSubscription<BluetoothDeviceState>?;
      List<BluetoothService> services = await esp_device!.discoverServices();
      services.forEach((service) {
        List<BluetoothCharacteristic> characteristics = service.characteristics;
        characteristics.forEach((characteristic) {
          if (characteristic.uuid.toString() ==
              'beb5483e-36e1-4688-b7f5-ea07361b26a8') {
            // predefined characteristic uuid
            this.characteristic = characteristic;
            characteristic.setNotifyValue(true);
            subscription = characteristic.value.listen((value) {
              isNotified = true;
              read_value = value;
              if (value[0] != 100) {
                notifyListeners();
              }
            });
          }
        });
      });
      return "";
    } catch (e) {
      // if something went wrong
      return "Can't connect\n to the device\nPlease try\n on later";
    }
  }
//---------------------------------------------------Write Values to ESP32-------------------------------------//

  Future<void> write(List<int> message) async {
    if (esp_device != null && characteristic != null) {
      await characteristic?.write(message);
    }
  }

//-------------------------------------------------Disconnect--------------------------------------------------//
  Future<void> disconnect() async {
    if (esp_device != null) {
      subscription?.cancel();
      connectedSubscription?.cancel();
      await esp_device?.disconnect();
      esp_device = null;
    }
  }
}
