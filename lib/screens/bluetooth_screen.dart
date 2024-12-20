import 'dart:async';
//import 'package:flutter/cupertino.dart';
//import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
//import 'package:flutter_blue_plus/flutter_blue_plus.dart';
//import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'BLE_conn_scree.dart';

//----------------------------------------------------------------------------------------------------------//
//------------------------------------------Connection Page-------------------------------------------------//
//----------------------------------------------------------------------------------------------------------//

class ConnectPage extends StatefulWidget {
  final Widget homescreen;
  const ConnectPage({super.key, required this.homescreen});

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  var title = "Connect To\n Bluetooth";

  @override
  Widget build(BuildContext context) {
//--------------------------------------Choose Title According to Connection Result------------------------------------//
    bool success = (title == "Connecting Success!" ||
        title == "The device is\n already connected");
    bool first_reach = (title == "Connect To\n Bluetooth");
    return Scaffold(
        body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //homeIcon(widget.homescreen, context),
          Expanded(
            child: Center(
              child: Column(
                children: [
                  const Spacer(),
                  //------------------------------------Title Page-------------------------------------//
                  first_reach
                      ? Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                          softWrap: true,
                          textAlign: TextAlign.center,
                        )
                      :
                      //-------------------------------------Connection Text Result-------------------//
                      Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(
                                  color: success
                                      ? const Color.fromARGB(255, 119, 219, 123)
                                      : const Color.fromARGB(255, 255, 26, 10),
                                  fontSize: 30),
                          softWrap: true,
                        ),
                  //-------------------------------------Connection Icon Result-------------------//
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: first_reach
                        ? const Icon(
                            Icons.bluetooth,
                            size: 50,
                          )
                        : (success
                            ? const Icon(
                                Icons.check_circle,
                                size: 50,
                                color: Color.fromARGB(255, 119, 219, 123),
                              )
                            : const Icon(
                                Icons.error,
                                size: 50,
                                color: Color.fromARGB(255, 244, 28, 12),
                              )),
                  ),
                  //---------------------------------Displaying Connection Instruction-------------------//
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: IconButton(
                        iconSize: 25,
                        onPressed: () => {}, //instruction
                        icon: const Icon(Icons.help)),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Spacer(),
                      //---------------------------------Go Back--------------------------------------------------//
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => widget.homescreen),
                              );
                            },
                            child: Text("Back",
                                style:
                                    Theme.of(context).textTheme.displayMedium)),
                      ),
                      //------------------------------------Start Connecting-------------------------------------//
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: ElevatedButton(
                            style: Theme.of(context).elevatedButtonTheme.style,
                            onPressed: () async {
                              final res = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => LoadingPage()),
                              );
                              setState(() {
                                title = res;
                              });
                            },
                            child: (Text("Connect",
                                style: Theme.of(context)
                                    .textTheme
                                    .displayMedium))),
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    ));
  }
}

// ignore: must_be_immutable
class LoadingPage extends StatelessWidget {
  LoadingPage({super.key});

  String problem = "";

  Future<void> init_and_connect() async {
    BLE_Connection i = BLE_Connection();
    if (i.esp_device != null) // already connected
    {
      problem = "The device is\n already connected";
    } else {
      if (await i.initBluetooth()) // Activate Bluetooth
      {
        if (problem == "") //Find ESP32 Device
        {
          problem = await i.connectToDevice();
          if (problem == "") //Connection Success
          {
            try {
              await i
                  .write([9, 3, 3, 3]); //Default Writing for Connection Check
              await Future.delayed(const Duration(milliseconds: 3500));
              if (i.read_value[0] == 100) {
                problem = "Connecting Success!";
              } else {
                //i.disconnect();
                problem = "Please check your buttons!";
              }
            } catch (e) {
              i.disconnect();
              problem = "Please check your buttons!";
            }
          }
        }
      } else {
        problem = "Please activate\n Bluetooth on\n your device!";
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    init_and_connect()
        .timeout(const Duration(seconds: 11), onTimeout: () => {});
//-----------------------------Limit Connection Period---------------------------//
    Timer(const Duration(seconds: 11), () {
      Navigator.pop(context, problem);
    });
    return Scaffold(
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Connecting",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: const [
                  Spacer(
                    flex: 10,
                  ),
                  SpinKitThreeBounce(
                    color: Colors.white,
                    size: 30,
                  ),
                  Spacer(flex: 9),
                ],
              ))
        ],
      ),
    );
  }
}

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    //player.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      BLE_Connection().disconnect();
    }
  }

  @override
  Widget build(BuildContext context) {
    //var appState = context.watch<BLE_Connection>();
    /*Future.delayed(Duration.zero,() {
      asyncAlertESPNNow(const ConnectPage(homescreen: BluetoothPage(title: "")), context);
    });*/
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Spacer(flex: 2),
//-----------------------------------Image Logo--------------------------------//
            Container(
              margin: const EdgeInsets.all(10),
              width: MediaQuery.of(context).size.width,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(width: 5.0, color: Colors.white),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.5),
                    spreadRadius: 7,
                    blurRadius: 10,
                    offset: const Offset(4, 4),
                  )
                ],
                image: const DecorationImage(
                  fit: BoxFit.cover,
                  image: AssetImage('assets/images/Game_Logo.png'),
                ),
              ),
            ),
            const Spacer(flex: 3),
//--------------------------------Start Button---------------------------------//
            /*ElevatedButton(
                onPressed: () => {
                   if(BLE_Connection().esp_device != null)
                   {
                   Navigator.push(
                               context,
                               MaterialPageRoute(builder: (context) => const ChoosingGame()),
                             )
                  }
                  else
                  {
                   showAlert(const ConnectPage(homescreen: BluetoothPage(title: ""),),
                         context),
                  }
                }, 
                
                  //child: buttonTextDisplay(Text("Let's Start!",
                 //           style: Theme.of(context).textTheme.displayMedium)),
              ),*/
            const Spacer(),
//---------------------------------Bluetooth Connection Page---------------------------------//
            ElevatedButton(
              onPressed: () => {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ConnectPage(
                            homescreen: BluetoothPage(),
                          )),
                )
              },
              child: (Text("Settings",
                  style: Theme.of(context).textTheme.displayMedium)),
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}
