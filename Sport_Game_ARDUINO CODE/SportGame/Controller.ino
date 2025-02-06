#include <WiFi.h>
#include <esp_now.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Adafruit_NeoPixel.h>

// Device ID ///////////////////
const uint8_t MY_ID = 0;    ////
#define MASTER              ////
////////////////////////////////

// Defines
// Controler defines
#define NUM_OF_DEVICES 4
//#define NUM_OF_PLAYERS 1
#define TIME_THRESHOLD 60000  // in ms
#define MAX_TIMESTAMP_NUM TIME_THRESHOLD/500  // TODO: logic is that we will not have button press faster than every 0.5 sec, could think of better solution...
#define COUNTER_THRESHOLD 20

// Bluetooth defines
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// Button defines
#define PIN 27        // Broche connectée à DIN (fil jaune) //led 
#define NUMPIXELS 16 // Nombre total de LEDs dans la matrice//number of leds turn on 
#define BUTTON_PIN 33 // Broche connectée au bouton button pin 

// Enums
enum verbosity {LOW_VERB, MEDIUM_VERB, HIGH_VERB};
enum fsm_state {IDLE,WAIT_APP,LIGHT_ON,LIGHT_OFF,FINAL,HANDLE_TIMESTAMP,SEND_TIMESTAMP,HANDLE_INIT,INIT_STATUS_UDPATE,INIT_ERROR};
enum message_opcode {NONE,INIT,TURN_ON_LIGHT,STORE_TIMESTAMP,FINISH,SCAN_COLOR,SCAN_RESPONSE,INC_COLOR,INIT_COLOR};
enum light_color {OFF,RED,BLUE,ERROR};

// Structs
typedef struct struct_message {
    uint8_t sender_id;
    message_opcode opcode;
    unsigned long timestamp;
    light_color color;
    bool singlePlayerMode;
} struct_message;

typedef struct timestamp_entry {
  uint8_t id;
  unsigned long timestamp;
} timestamp_entry;

// Global variables ////////////////////////////////////////////////
bool startGame;
bool isSinglePlayerMode;// = NUM_OF_PLAYERS == 1;
light_color myColor;
uint8_t scanId;
bool scanAvailable;
uint8_t potentialNextDeviceIds [NUM_OF_DEVICES-2];
const verbosity MY_VERBOSITY = MEDIUM_VERB;  // Log verbosity (low - alot of prints, high - no prints)
const bool matrix_connected = true;  // flag indicating if button is connected to ESP, if false button is simulated randomly
// Light and Button
Adafruit_NeoPixel pixels(NUMPIXELS, PIN, NEO_GRB + NEO_KHZ800);
bool buttonState = HIGH;  // button state, TRUE: pressed, FALSE: not pressed
bool lastButtonState = HIGH;
bool lightState = false;   // light state, TRUE: ON, FALSE: OFF
bool hasError;
#ifdef MASTER
  bool init_status [NUM_OF_DEVICES];  // status of initialization round, send to app if failed
  uint8_t fail_init_counter;
  timestamp_entry timestamps [MAX_TIMESTAMP_NUM];  // timestamps, stored on master and send at end of game to app
  uint last_timestamp_index;  // index indicating next timestamp entry to be stored
  uint redPlayerCounter;
  uint bluePlayerCounter;
#endif
// ESP NOW ////////////////////////
esp_now_peer_info_t peerInfo;
esp_now_send_status_t esp_status;  // returned status after sending ESP Now message
bool received_esp_reply;  // flag indicating whether ESP Now message send was replyed with ACK/NACK

// Receive and Send messages
struct_message ReceiveData;
struct_message SendData;
////////////////////////////////////

#ifdef MASTER
  // APP Bluetooth //////////////////
  BLEServer* pServer = NULL;
  BLECharacteristic* pCharacteristic = NULL;
  bool deviceConnected = false;
  bool oldDeviceConnected = false;
  uint32_t value = 1;
  //////////////////////////////////
#endif

// Time related variables
unsigned long StartTime;  // time of game start, reference for all timestamps

// FSM state
fsm_state state;

// MAC dictionary
uint8_t mac_addresses[NUM_OF_DEVICES][6] = {{0x0C, 0xB8, 0x15, 0x78, 0xB5, 0xA0},
                                            {0xC8, 0xF0, 0x9E, 0xA6, 0xC6, 0x2C},
                                            {0x7C, 0x9E, 0xBD, 0x06, 0x63, 0x7C},
                                            {0xC8, 0xF0, 0x9E, 0xA6, 0xA7, 0x34}};

//{0x24, 0x0A, 0xC4, 0xEE, 0x34, 0xD0},
//{0xC8, 0xF0, 0x9E, 0xA6, 0xA7, 0x34}
// {0x7C, 0x9E, 0xBD, 0x06, 0x63, 0x7C} (BLUE)


/////////////////////////////////////////////////////////////////////

// Methods

// Turn light ON
void turnLightOn() {
  Serial.println("Light ON");
  lightState = true;
  if(matrix_connected) {
    for (int i = 0; i < NUMPIXELS; i++) {
      if (myColor == ERROR) {
        pixels.setPixelColor(i, pixels.Color(255, 255, 255));
      } else if (myColor == RED || isSinglePlayerMode) {
        pixels.setPixelColor(i, pixels.Color(255, 0, 0)); // Rouge
      } else if (myColor == BLUE) {
        pixels.setPixelColor(i, pixels.Color(0, 0, 255));
      }
    }
    pixels.show();
  }
  return;
}

// Turn light off
void turnLightOff() {
  Serial.println("Light OFF");
  lightState = false;
  myColor = OFF;
  if(matrix_connected) {
    for (int i = 0; i < NUMPIXELS; i++) {
      pixels.setPixelColor(i, pixels.Color(0, 0, 0)); // Éteint
    }
    pixels.show();
  }
  return;
}

// Read button status
void readButton() {
  if(matrix_connected) {
    buttonState = digitalRead(BUTTON_PIN);
    if (buttonState == LOW && lastButtonState == HIGH){
      Serial.println("Button Pushed");
    }
    
  } else {
    int rand_num = random(1000);
    if (rand_num > 990){
      buttonState = true;;
    } else {
      buttonState = false;
    }
  }
}

// Perform FSM state transition according to current state and indications
void fsmTransition(bool received_message, message_opcode opcode, bool start_game, bool button_pressed, bool end_game) {
  if (state == FINAL && MY_ID == 0){
    state = WAIT_APP;
    return;
  }
  // Hanlde end of game
  if (opcode == FINISH) {
    if (MY_ID == 0) {
      state = FINAL;
    } else {
      state = IDLE;
    }
    
    if (lightState) {  // if light is on, turn it off at end of game
      turnLightOff();
    }
    return;
  }

  // Reply color scan
  if (opcode == SCAN_COLOR) {
    sendMessage(ReceiveData.sender_id, SCAN_RESPONSE);
    return;
  }

  if (opcode == SCAN_RESPONSE) {
    scanId = ReceiveData.sender_id;
    scanAvailable = ReceiveData.color == OFF;
    return;
  }

  if (opcode == INIT_COLOR) {
    myColor = BLUE;
    state = LIGHT_ON;
    turnLightOn();
  }

  // State transistions
  if (state == IDLE) {
    if (received_message) {
      if (opcode == TURN_ON_LIGHT) {
        state = LIGHT_ON;
        myColor = ReceiveData.color;
      } else if (opcode == FINISH) {
        state = FINAL;
      } else if (opcode == INIT) {
        state = HANDLE_INIT;
        StartTime = millis();  // Game start time (will be reference time for all other timestamps)
        Serial.print("StartTime: ");
        Serial.println(StartTime);
      } else if (opcode == STORE_TIMESTAMP) {
        state = HANDLE_TIMESTAMP; 
      } 
    }
  } else if (state == WAIT_APP) {
    if (start_game) {
      state = HANDLE_INIT;
    }
  } else if (state == LIGHT_ON) {
    if (buttonState == LOW && lastButtonState == HIGH) {
      if (MY_ID == 0) {
        state = HANDLE_TIMESTAMP;
      } else {
        state = SEND_TIMESTAMP;
      }
    }
  } else if (state == HANDLE_TIMESTAMP) {
    if (end_game) {
      state = FINAL;
    } else if (lightState) {
      state = LIGHT_OFF;
    } else {
      state = IDLE;
    }
  } else if (state == SEND_TIMESTAMP) {
    state = LIGHT_OFF;
  } else if (state == LIGHT_OFF) {
      state = IDLE;
  } else if (state == HANDLE_INIT) {
    if (MY_ID == 0) {
      state = INIT_STATUS_UDPATE;
    } else {
      state = IDLE;
    }
  } else if (INIT_STATUS_UDPATE) {
    if (hasError) {
      state = INIT_ERROR;
    } else {
      state = LIGHT_ON;
    }
    
  } else if (FINAL) {
    state = WAIT_APP;
  }
}


// Callback when data is received
void onDataRecv(const uint8_t * mac, const uint8_t *incomingData, int len) {
  if(!(state == IDLE || state == LIGHT_ON || state == LIGHT_OFF)) {
    return;
  }
  memcpy(&ReceiveData, incomingData, sizeof(ReceiveData));
  bool received_valid_message = ReceiveData.sender_id < NUM_OF_DEVICES;
  if(MY_VERBOSITY < HIGH_VERB && received_valid_message) {
    Serial.print("Bytes received: ");
    Serial.println(len);
    Serial.print("Opcode: ");
    Serial.println(ReceiveData.opcode);
    Serial.print("Got from ID: ");
    Serial.println(ReceiveData.sender_id);
    Serial.print("Timestamp: ");
    Serial.println(ReceiveData.timestamp);
    Serial.print("Color (0:OFF, 1:RED, 2:BLUE): ");
    Serial.println(ReceiveData.color);
    Serial.print("singlePlayerMode: ");
    Serial.println(ReceiveData.singlePlayerMode);
    Serial.println();
  }
  
  fsmTransition(received_valid_message, ReceiveData.opcode, false, false,false);
}

// Callback when data is sent
void onDataSent(const uint8_t *mac_addr, esp_now_send_status_t status) {
  if(MY_VERBOSITY < HIGH_VERB) {
    Serial.print("\r\nLast Packet Send Status:\t");
    Serial.println(status == ESP_NOW_SEND_SUCCESS ? "Delivery Success" : "Delivery Fail");
  }
  received_esp_reply = true;
  esp_status = status;
}

// Get ID of device to send next message
uint8_t getNextId() {
  uint8_t rand_num = random(NUM_OF_DEVICES-1);
  // This calculation holds that new ID is different from MY_ID, while staying in range 0..NUM_OF_DEVICES-1
  return (MY_ID + rand_num + 1) % NUM_OF_DEVICES;  
}

// Build message after receiving message from other ESP
void buildMessage(message_opcode opcode) {
  SendData.sender_id = MY_ID;
  SendData.opcode = opcode;
  SendData.timestamp = millis() - StartTime;
  SendData.color = myColor;
  SendData.singlePlayerMode = isSinglePlayerMode;
}

void sendMessage(uint8_t dest_id, message_opcode opcode) {
  // Build new message
  buildMessage(opcode);
  
  // Send message via ESP-NOW
  received_esp_reply = false;
  esp_err_t result = esp_now_send(mac_addresses[dest_id], (uint8_t *) &SendData, sizeof(SendData));
  if(MY_VERBOSITY < HIGH_VERB) {
    if (result == ESP_OK) {    
      Serial.println("Sent with success");
    } else {
      Serial.println("Error sending the data");
    }
  }
}

void sendSwitchLightMessage(uint8_t dest_id, light_color nextColor) {
  // Build new message
  SendData.sender_id = MY_ID;
  SendData.opcode = TURN_ON_LIGHT;
  SendData.timestamp = millis() - StartTime;
  SendData.color = nextColor;
  SendData.singlePlayerMode = isSinglePlayerMode;
  // Send message via ESP-NOW
  received_esp_reply = false;
  esp_err_t result = esp_now_send(mac_addresses[dest_id], (uint8_t *) &SendData, sizeof(SendData));
  if(MY_VERBOSITY < HIGH_VERB) {
    if (result == ESP_OK) {    
      Serial.println("Sent with success");
    } else {
      Serial.println("Error sending the data");
    }
  }
}

#ifdef MASTER
// Initialization round that master controls
void masterInitControl() {
  // For each device master controls, send INIT message, check if responds
  for (uint8_t device_id=1; device_id < NUM_OF_DEVICES; device_id++) {  // start from ID=1
    sendMessage(device_id, INIT);
    while(!received_esp_reply) {  // wait for response
      delay(1);
    }
    // Store status and update sticky error indication
    // has_error = has_error || esp_status != ESP_NOW_SEND_SUCCESS;
    if (esp_status != ESP_NOW_SEND_SUCCESS) {
      fail_init_counter++;
    }
    init_status[device_id] = (esp_status == ESP_NOW_SEND_SUCCESS);
  }
  hasError = (fail_init_counter != 0);
}

void sendEndOfGame() {
  for (uint8_t device_id=1; device_id < NUM_OF_DEVICES; device_id++) {  // start from ID=1
    sendMessage(device_id, FINISH); // Send all controled devices that game has finished
  }
}

void sendAppInitDone() {
  if (deviceConnected) {
      // Send the number of init failures encountered, 0 means SUCCESS
      pCharacteristic->setValue((uint8_t*)&fail_init_counter, 1);
      pCharacteristic->notify();
      delay(10); // bluetooth stack will go into congestion, if too many packets are sent, in 6 hours test i was able to go as low as 3ms

      // Send all device IDs that failed
      for (uint8_t device_id=1; device_id < NUM_OF_DEVICES; device_id++) {  // start from ID=1
        if (init_status[device_id] == false) {
          pCharacteristic->setValue((uint8_t*)&device_id, 1);
          pCharacteristic->notify();
          delay(10);
        }
      }
  }

}

void sendAppGameDoneSinglePlayer() {
  if (deviceConnected) {
      // Send the number of timestamps stored on Master
      pCharacteristic->setValue((uint8_t*)&last_timestamp_index,4);
      pCharacteristic->notify();
      delay(1000); // bluetooth stack will go into congestion, if too many packets are sent, in 6 hours test i was able to go as low as 3ms

      for (uint timestamp_indx=0; timestamp_indx < last_timestamp_index; timestamp_indx++) {
        uint8_t curr_id = timestamps[timestamp_indx].id;
        unsigned long curr_timestamp = timestamps[timestamp_indx].timestamp;
        pCharacteristic->setValue((uint8_t*)&curr_id,1);
        pCharacteristic->notify();
        delay(100);
      /*  pCharacteristic->setValue((uint8_t*)&curr_timestamp,8);
        pCharacteristic->notify();
        delay(1000);*/
      }
      uint non_id_value=0; 
      uint temp = 100-last_timestamp_index;
     
      for (uint i=0; i<temp; i++){
        pCharacteristic->setValue((uint8_t*)&non_id_value,4);
        pCharacteristic->notify();
        delay(100);
      }

  
     // calculate distance 
     /* uint timestamp_indx_2 = 0;
      uint distance=0;
      for(uint timestamp_indx_1=1; timestamp_indx_1 < last_timestamp_index; timestamp_indx_1++){
        if(abs(timestamps[timestamp_indx_1].id - timestamps[timestamp_indx_2].id) == 1 || abs(timestamps[timestamp_indx_1].id - timestamps[timestamp_indx_2].id) == 3){
          distance = distance+10;
          timestamp_indx_2++;
        }
        if(abs(timestamps[timestamp_indx_1].id - timestamps[timestamp_indx_2].id) == 2){
          distance = distance+20;
          timestamp_indx_2++;
        }
      }
       pCharacteristic->setValue((uint8_t*)&distance,4);
      pCharacteristic->notify();
      Serial.println("distance");
      Serial.println(distance);*/
  }
  
}

void sendAppGameDoneMultiPlayer() {
  if (deviceConnected) {
      // Send the player that won (0: Red, 1: Blue)
      uint8_t result = (redPlayerCounter > bluePlayerCounter) ? 0 : 1;
      pCharacteristic->setValue((uint8_t*)&result,1);
      pCharacteristic->notify();
      delay(1000); // bluetooth stack will go into congestion, if too many packets are sent, in 6 hours test i was able to go as low as 3ms
  }
}

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
    }
};

class MyCallbacks : public BLECharacteristicCallbacks
{
  void onWrite(BLECharacteristic *pCharacteristic)
  {
    std::string value_from_app = pCharacteristic->getValue();
    if ((static_cast<int>(value_from_app[0])) == 1)
    {
      startGame = true;
      isSinglePlayerMode = true;
    } else if ((static_cast<int>(value_from_app[0])) == 2) {
      startGame = true;
      isSinglePlayerMode = false;
    }
    Serial.print("isSinglePlayerMode: ");
    Serial.println(isSinglePlayerMode);
    Serial.print("startGame: ");
    Serial.println(startGame);
  }
};

void keepAppConnection() {
    // notify changed value
    if (deviceConnected) {
        pCharacteristic->setValue((uint8_t*)&value, 4);//set value: tekes value and give 4 bit in the memory for rep
        pCharacteristic->notify();//send the app the messege
        if( value != 0){
        value++;
        }
        delay(1000); // bluetooth stack will go into congestion, if too many packets are sent, in 6 hours test i was able to go as low as 3ms (1000 is one sec)
    }
    // disconnecting
    if (!deviceConnected && oldDeviceConnected) {
        delay(500); // give the bluetooth stack the chance to get things ready
        pServer->startAdvertising(); // restart advertising
        Serial.println("start advertising");
        oldDeviceConnected = deviceConnected;
    }
    // connecting
    if (deviceConnected && !oldDeviceConnected) {
        // do stuff here on connecting
        oldDeviceConnected = deviceConnected;
    }

    if(startGame == true){ // if we turn the flag true we set value 0 and send 0 always
      //start the game
      value = 0;
    }
    //delay(2000);
    //startGame = true;
}
#endif


void singlePlayerLoop() {
  myColor = RED;
  if (state == IDLE) {
    if(MY_VERBOSITY == LOW_VERB) {
      Serial.println("In IDLE state");
    }
    buttonState = false;
  } else if (state == WAIT_APP) {
    if(MY_VERBOSITY == LOW_VERB) {
      Serial.println("In WAIT_APP state");
    }
    #ifdef MASTER
      keepAppConnection(); // check if app started game
      buttonState = false;
      last_timestamp_index = 0;
    #endif
    fsmTransition(false, NONE,startGame, false,false);
  } else if (state == HANDLE_INIT) {
    if(MY_VERBOSITY == LOW_VERB) {
      Serial.println("In HANDLE_INIT state");
    }
    
    if (MY_ID == 0) {
      #ifdef MASTER
        masterInitControl();
        StartTime = millis();  // Game start time (will be reference time for all other timestamps)
        Serial.print("StartTime: ");
        Serial.println(StartTime);
      #endif
      fsmTransition(false, NONE,false, false ,false);
    } else {
      isSinglePlayerMode = ReceiveData.singlePlayerMode;
      fsmTransition(false, NONE,false, false,false);
    }
  } else if (state == INIT_STATUS_UDPATE) {
    if(MY_VERBOSITY == LOW_VERB) {
      Serial.println("In INIT_STATUS_UDPATE state");
    }
    #ifdef MASTER
      sendAppInitDone();  // handle init error (notify app and send status)
    #endif
    fsmTransition(false, NONE,false, false,false);
  } else if (state == INIT_ERROR) {
    if(MY_VERBOSITY == LOW_VERB) {
      Serial.println("In INIT_ERROR state");
    }
    #ifdef MASTER
      myColor = ERROR;
      delay(10);
      turnLightOn();
    #endif
  } else if (state == HANDLE_TIMESTAMP) {
    if(MY_VERBOSITY == LOW_VERB) {
      Serial.println("In HANDLE_TIMESTAMP state");
    }
    #ifdef MASTER
    if (lightState) {  // handle timestamp of master (ID==0)
      timestamps[last_timestamp_index].id = 0;
      timestamps[last_timestamp_index].timestamp = millis() - StartTime;
      Serial.print("StartTime: ");
      Serial.println(StartTime);
      Serial.print("millis(): ");
      Serial.println(millis());
    } else {  // handle timestamp of other ESP (ID != 0)
      timestamps[last_timestamp_index].id = ReceiveData.sender_id;
      timestamps[last_timestamp_index].timestamp = ReceiveData.timestamp;
      Serial.print("StartTime: ");
      Serial.println(StartTime);
      Serial.print("ReceiveData.timestamp: ");
      Serial.println(ReceiveData.timestamp);
    }
    if (timestamps[last_timestamp_index].timestamp >= TIME_THRESHOLD) {  // reached time limit, end the game
      sendEndOfGame(); // send other devices that game ended
      fsmTransition(false, NONE,false, false, true);
    } else {  // game still running, update index and FSM
      last_timestamp_index++;
      fsmTransition(false, NONE,false, false,false);
    }
    #endif
  } else if(state == LIGHT_ON) {
    if(MY_VERBOSITY == LOW_VERB) {
      Serial.println("In LIGHT_ON state");
    }

    if (!lightState) {
      turnLightOn();
    }
    
    readButton();  // check if button is pressed
    fsmTransition(false, NONE,false, buttonState,false);
  } else if (state == SEND_TIMESTAMP) {
    if(MY_VERBOSITY == LOW_VERB) {
      Serial.println("In SEND_TIMESTAMP state");
    }
    sendMessage(0,STORE_TIMESTAMP);
    fsmTransition(false, NONE,false, false, false);
  } else if(state == LIGHT_OFF) {
    if(MY_VERBOSITY == LOW_VERB) {
      Serial.println("In LIGHT_OFF state");
    }
    turnLightOff();
    uint8_t next_id = getNextId();  // get next random light to turn on
    Serial.print("Chosen nex ID: ");
    Serial.println(next_id);
    if (next_id != MY_ID) {  // To handle FINAL state transition case
      sendMessage(next_id, TURN_ON_LIGHT);
    }
    fsmTransition(false,NONE,false,false,false);
  } else if(state == FINAL) {  // Final state at end of game
    if(MY_VERBOSITY == LOW_VERB) {
      Serial.println("In FINAL state");
    }
    #ifdef MASTER
      if (lightState) {  // if light is on, turn it off at end of game
        turnLightOff();
      }
      delay(10);
      sendAppGameDoneSinglePlayer();  // send app all timestamps
      Serial.println("DONE");
    #endif
    fsmTransition(false,NONE,false,false,false);
  }
}


void multiPlayerLoop() {
  if (state == IDLE) {
    if(MY_VERBOSITY == LOW_VERB) {
      Serial.println("In IDLE state");
    }
    buttonState = false;
  } else if (state == WAIT_APP) {
    if(MY_VERBOSITY == LOW_VERB) {
      Serial.println("In WAIT_APP state");
    }
    #ifdef MASTER
      keepAppConnection(); // check if app started game
      buttonState = false;
      last_timestamp_index = 0;
    #endif
    fsmTransition(false, NONE,startGame, false,false);
  } else if (state == HANDLE_INIT) {
    if(MY_VERBOSITY == LOW_VERB) {
      Serial.println("In HANDLE_INIT state");
    }
    if (MY_ID == 0) {
      #ifdef MASTER
        masterInitControl();
        StartTime = millis();  // Game start time (will be refernce time for all other timestamps)
      #endif
      fsmTransition(false, NONE,false, false ,false);
    } else {
      isSinglePlayerMode = ReceiveData.singlePlayerMode;
      fsmTransition(false, NONE,false, false,false);
    }
  } else if (state == INIT_STATUS_UDPATE) {
    if(MY_VERBOSITY == LOW_VERB) {
      Serial.println("In INIT_STATUS_UDPATE state");
    }
    #ifdef MASTER
      sendAppInitDone();  // handle init error (notify app and send status)
      if (!hasError) {
        sendMessage(1,INIT_COLOR);
      }
    #endif
    fsmTransition(false, NONE,false, false,false);
  } else if (state == INIT_ERROR) {
    if(MY_VERBOSITY == LOW_VERB) {
      Serial.println("In INIT_ERROR state");
    }
    #ifdef MASTER
      myColor = ERROR;
      delay(10);
      turnLightOn();
    #endif
  } else if (state == HANDLE_TIMESTAMP) {
    if(MY_VERBOSITY == LOW_VERB) {
      Serial.println("In HANDLE_TIMESTAMP state");
    }
    #ifdef MASTER
    if (lightState) {  // handle timestamp of master (ID==0)
      if (myColor == RED) {
        redPlayerCounter++;
      } else if (myColor == BLUE) {
        bluePlayerCounter++;
      }
    } else {  // handle timestamp of other ESP (ID != 0)
      if (ReceiveData.color == RED) {
        redPlayerCounter++;
      } else if (ReceiveData.color == BLUE) {
        bluePlayerCounter++;
      }
    }
    if (redPlayerCounter >= COUNTER_THRESHOLD || bluePlayerCounter >= COUNTER_THRESHOLD) {  // reached time limit, end the game
      sendEndOfGame(); // send other devices that game ended
      fsmTransition(false, NONE,false, false, true);
    } else {  // game still running, update index and FSM
      fsmTransition(false, NONE,false, false,false);
    }
    #endif
  } else if(state == LIGHT_ON) {
    if(MY_VERBOSITY == LOW_VERB) {
      Serial.println("In LIGHT_ON state");
    }
    if (!lightState) {
      turnLightOn();
    }
    readButton();  // check if button is pressed
    fsmTransition(false, NONE,false, buttonState,false);
  } else if (state == SEND_TIMESTAMP) {
    if(MY_VERBOSITY == LOW_VERB) {
      Serial.println("In SEND_TIMESTAMP state");
    }
    sendMessage(0,STORE_TIMESTAMP);
    fsmTransition(false, NONE,false, false, false);
  } else if(state == LIGHT_OFF) {
    if(MY_VERBOSITY == LOW_VERB) {
      Serial.println("In LIGHT_OFF state");
    }

    Serial.print("Color (0:OFF, 1:RED, 2:BLUE): ");
    Serial.println(myColor);
    light_color nextColor;
    if (myColor == RED){
      nextColor = RED;
    } else {
      nextColor = BLUE;
    }
    
    // Scan other lights
    uint8_t potentialDeviceInd = 0;
    Serial.println("DEBUG: Start scan");
    for (uint8_t device_id=0; device_id < NUM_OF_DEVICES; device_id++) {
      if (device_id == MY_ID) {
        continue;
      }
      Serial.println("DEBUG: Device ID");
      Serial.println(device_id);
      Serial.println("DEBUG: Sending scan..");
      sendMessage(device_id,SCAN_COLOR);
      delay(100);
      Serial.println("DEBUG: Checking scan response");
      Serial.println("DEBUG: Response color: ");
      Serial.println(scanId);
      if (scanAvailable) {
        Serial.println("DEBUG: Adding potential device");
        Serial.println(device_id);
        Serial.println(ReceiveData.sender_id);
        potentialNextDeviceIds[potentialDeviceInd] = device_id;
        potentialDeviceInd++;
      }
    }

    uint8_t rand_num = random(NUM_OF_DEVICES-2);
    uint8_t next_id = potentialNextDeviceIds[rand_num];
    Serial.println("DEBUG: Chosen random index");
    Serial.println(rand_num);
    Serial.println("DEBUG: Next device ID");
    Serial.println(next_id);
    
    Serial.print("Color (0:OFF, 1:RED, 2:BLUE): ");
    Serial.println(nextColor);
    if (next_id != MY_ID) {  // To handle FINAL state transition case
      sendSwitchLightMessage(next_id, nextColor);
    }
    

    delay(100);

    turnLightOff();

    fsmTransition(false,NONE,false,false,false);
  } else if(state == FINAL) {  // Final state at end of game
    if(MY_VERBOSITY == LOW_VERB) {
      Serial.println("In FINAL state");
    }
    #ifdef MASTER
      // if (lightState) {  // if light is on, turn it off at end of game
      //   turnLightOff();
      // }
      sendAppGameDoneMultiPlayer();  // send app all timestamps
      Serial.println("DONE");
    #endif
    fsmTransition(false,NONE,false,false,false);
  }
}


void setup() {
  // Initialize Serial Monitor
  Serial.begin(115200);
  
  // Initialize LEDs
  pixels.begin();

  // Init LEDs to be turned off at setup
  for (int i = 0; i < NUMPIXELS; i++) {
    pixels.setPixelColor(i, pixels.Color(0, 0, 0)); // Rouge
  }
  pixels.show();

  pinMode(BUTTON_PIN, INPUT_PULLUP);


  // Set device as a Wi-Fi Station
  WiFi.mode(WIFI_STA);

  // ESP NOW - INIT ///////////////////////////////////////////////////////////////
  if (esp_now_init() != ESP_OK) {
    Serial.println("Error initializing ESP-NOW");
    return;
  }

  // Once ESPNow is successfully Init, we will register for recv CB to
  // get recv packer info
  esp_now_register_recv_cb(esp_now_recv_cb_t(onDataRecv));
  // Once ESPNow is successfully Init, we will register for Send CB to
  // get the status of Trasnmitted packet
  esp_now_register_send_cb(onDataSent);

  // Register peers
  for(uint8_t device_id=0; device_id < NUM_OF_DEVICES; device_id++){
    memcpy(peerInfo.peer_addr, mac_addresses[device_id], 6);
    peerInfo.channel = 0;  
    peerInfo.encrypt = false;
    // Add peer
    if(device_id != MY_ID) {        
      if (esp_now_add_peer(&peerInfo) != ESP_OK){
        Serial.println("Failed to add peer");
        return;
      }
    }
  }

  // ESP NOW - END INIT //////////////////////////////////////////////////////

  #ifdef MASTER
    // BLUETOOTH - INIT ////////////////////////////////////////////////////////
    // Create the BLE Device
    BLEDevice::init("ESP320");

    // Create the BLE Server
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new MyServerCallbacks());

    // Create the BLE Service
    BLEService *pService = pServer->createService(SERVICE_UUID);

    // Create a BLE Characteristic
    pCharacteristic = pService->createCharacteristic(
                        CHARACTERISTIC_UUID,
                        BLECharacteristic::PROPERTY_READ   |
                        BLECharacteristic::PROPERTY_WRITE  |
                        BLECharacteristic::PROPERTY_NOTIFY |
                        BLECharacteristic::PROPERTY_INDICATE
                      );
    // Set callbacks
    pCharacteristic->setCallbacks(new MyCallbacks());

    // Start the service
    pService->start();

    // Start advertising
    BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(false);
    pAdvertising->setMinPreferred(0x0);  // set value to 0x00 to not advertise this parameter
    BLEDevice::startAdvertising();
    Serial.println("Waiting a client connection to notify...");
    // BLUETOOTH - END INIT ////////////////////////////////////////////////////
  #endif

  // FSM state init according to device ID
  lightState = false;
  if (MY_ID == 0) {
    #ifdef MASTER
      state = WAIT_APP;
      last_timestamp_index = 0;
      fail_init_counter = 0;
      myColor = RED;
      hasError = false;
    #endif
  } else {
    state = IDLE;
    myColor = OFF;
  }
}

void loop() {
  if (isSinglePlayerMode) {
    singlePlayerLoop();
  } else {
    multiPlayerLoop();
  }
  
  lastButtonState = buttonState;
  delay(100);
}
