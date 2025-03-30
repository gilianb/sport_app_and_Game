# IoT Sports Game

This repository contains an IoT-based sports game where players must press buzzers as quickly as possible. The system is controlled via a Flutter application and uses BLE and ESP-NOW for communication.

## Architecture
- **Flutter App** – Connects via BLE to the master ESP32 and manages the game.
- **Master Buzzer (ESP32)** – Communicates with the app via BLE and controls the game logic.
- **Player Buzzers (4x ESP32)** – Connected via ESP-NOW to the master, registering button presses.

## Repository Structure
- `app/` – Flutter application code.
- `Sport_Game_Arduino_Code/` – Arduino code for the master and player buzzers.

## Setup Instructions
1. Install dependencies in `pubspec.yaml` for Flutter.
2. Add required BLE permissions in `AndroidManifest.xml`.
3. Flash the ESP32 firmware using Arduino IDE.

## How It Works
1. The app starts and connects to the master ESP32 via BLE.
2. The master communicates with the four buzzers via ESP-NOW.
3. Players press their buzzers as fast as possible; the master registers the first press and updates the app.
4. At the end of the Game, the Data are sent to a firebase server and displayed on the App.

## Demo Videos
Short demonstration videos are available in the `Video/` folder.

---
Developed by Gilian Bensoussan

