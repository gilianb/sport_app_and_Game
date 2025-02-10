#include <WiFi.h>
#include <esp_now.h>


// Defines
#define NUM_OF_DEVICES 3
#define COUNTER_THRESHOLD 30

// Enums
enum verbosity {LOW_VERB, MEDIUM_VERB, HIGH_VERB};
enum fsm_state {IDLE,LIGHT_ON,LIGHT_OFF,FINAL};

// Structs
typedef struct struct_message {
    uint8_t send_id;
    int button_counter;
} struct_message;

// Global variables ////////////////////////////////////////////////
const uint8_t MY_ID = 0;
const verbosity MY_VERBOSITY = MEDIUM_VERB;
const bool matrix_connected = true;
// Light and Button
const int buttonPin = 5;  // the number of the pushbutton pin
const int ledPin = 33;    // the number of the LED pin
bool buttonState;
bool lightState;

esp_now_peer_info_t peerInfo;

// Receive and Send messages
struct_message ReceiveData;
struct_message SendData;

// FSM state
fsm_state state;

// MAC dictionary
uint8_t mac_addresses[NUM_OF_DEVICES][6] = {{0x7C, 0x9E, 0xBD, 0x06, 0x63, 0x7C},
                                           {0x24, 0x0A, 0xC4, 0xEE, 0x34, 0xD0},
                                           {0xC8, 0xF0, 0x9E, 0xA6, 0xA7, 0x34}};

// Flag for first message sending
bool sent_first_message;
/////////////////////////////////////////////////////////////////////

// Methods
// Build first message with button counter = 0
void buildInitialMessage() {
  if (MY_ID != 0) {
    Serial.println("Error: Initial message with counter=0 is allowed only for ID=0");
    return;
  }
  SendData.send_id = 0;
  SendData.button_counter = 0;
}

// Build message after receiving message from other ESP
void buildMessage() {
  SendData.send_id = MY_ID;
  SendData.button_counter = ReceiveData.button_counter + 1;
}

// Perform FSM state transition according to current state and indications
void fsmTransition(bool received_message, bool button_pressed, bool counter_passed_threshold) {
  if (state == IDLE) {
    if (received_message) {
      state = LIGHT_ON;
    }
  } else if (state == LIGHT_ON) {
    if (button_pressed) {
      state = LIGHT_OFF;
    }
  } else if (state == LIGHT_OFF) {
    if (counter_passed_threshold) {
      state = FINAL;
    } else {
      state = IDLE;
    }
  }
}

// Callback when data is received
void onDataRecv(const uint8_t * mac, const uint8_t *incomingData, int len) {
  if(state != IDLE) {
    return;
  }
  memcpy(&ReceiveData, incomingData, sizeof(ReceiveData));
  bool received_valid_message = ReceiveData.send_id < NUM_OF_DEVICES && ReceiveData.button_counter <= COUNTER_THRESHOLD;

  if(MY_VERBOSITY < HIGH_VERB && received_valid_message) {
    Serial.print("Bytes received: ");
    Serial.println(len);
    Serial.print("Counter: ");
    Serial.println(ReceiveData.button_counter);
    Serial.print("Got from ID: ");
    Serial.println(ReceiveData.send_id);
    Serial.println();
  }
  
  fsmTransition(received_valid_message, false, false);
}

// Callback when data is sent
void onDataSent(const uint8_t *mac_addr, esp_now_send_status_t status) {
  if(MY_VERBOSITY < HIGH_VERB) {
    Serial.print("\r\nLast Packet Send Status:\t");
    Serial.println(status == ESP_NOW_SEND_SUCCESS ? "Delivery Success" : "Delivery Fail");
  }
}

// Get ID of device to send next message
uint8_t getNextid(bool counter_passed_threhold) {
  if(counter_passed_threhold) { // Final state returns to device with ID=0
    return 0;
  }
  uint8_t rand_num = random(NUM_OF_DEVICES-1);
  // This calculation holds that new ID is different from MY_ID, while staying in range 0..NUM_OF_DEVICES-1
  return (MY_ID + rand_num + 1) % NUM_OF_DEVICES;  
}

void sendMessage(uint8_t chosen_id) {
  if (MY_ID == 0 && !sent_first_message) {
    sent_first_message = true;
    buildInitialMessage();
  } else {
    buildMessage();
  }

  // Send message via ESP-NOW
  esp_err_t result = esp_now_send(mac_addresses[chosen_id], (uint8_t *) &SendData, sizeof(SendData));
   
  if(MY_VERBOSITY < HIGH_VERB) {
    if (result == ESP_OK) {
      Serial.println("Sent with success");
    }
    else {
      Serial.println("Error sending the data");
    }
  }
}

// Turn light ON
void turnLightOn() {
  // TODO: need to implement
  Serial.println("Light ON");
  lightState = true;
  if(matrix_connected) {
    digitalWrite(ledPin, HIGH);
  }
  return;
}

// Turn light off
void turnLightOff() {
  // TODO: need to implement
  Serial.println("Light OFF");
  lightState = false;
  if(matrix_connected) {
    digitalWrite(ledPin, LOW);
  }
  return;
}

// Read button status
bool readButton() {
  // TODO: need to implement
  if(matrix_connected) {
    return digitalRead(buttonPin);
  } else {
    int rand_num = random(1000);
    if (rand_num > 990){
      buttonState = true;
      return true;
    } else {
      buttonState = false;
      return false;
    }
  }
}


void setup() {
  // put your setup code here, to run once:
  
  // Initialize the LED pin as an output:
  pinMode(ledPin, OUTPUT);
  // Initialize the pushbutton pin as an input:
  pinMode(buttonPin, INPUT);

  // Initialize Serial Monitor
  Serial.begin(115200);
  
  // Set device as a Wi-Fi Station
  WiFi.mode(WIFI_STA);

  // Init ESP-NOW
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

  ReceiveData.button_counter=0;

  // FSM state init according to device ID
  if (MY_ID == 0) {
    state = LIGHT_ON;
    sent_first_message = false;
  } else {
    state = IDLE;
  }
}

void loop() {
  // put your main code here, to run repeatedly:
  if (state == IDLE) {
    if(MY_VERBOSITY == LOW_VERB) {
      Serial.println("In IDLE state");
    }
    buttonState = false;
  } else if(state == LIGHT_ON) {
    if(MY_VERBOSITY == LOW_VERB) {
      Serial.println("In LIGHT_ON state");
    }
    if (!lightState) {
      turnLightOn();
    }
    readButton();
    fsmTransition(false,buttonState, false);
  } else if(state == LIGHT_OFF) {
    if(MY_VERBOSITY == LOW_VERB) {
      Serial.println("In LIGHT_OFF state");
    }
    turnLightOff();
    bool counter_passed_threhold = ReceiveData.button_counter + 1 >= COUNTER_THRESHOLD;
    uint8_t next_id = getNextid(counter_passed_threhold);
    if (next_id != MY_ID) {  // To handle FINAL state transition case
      sendMessage(next_id);
    }
    fsmTransition(false,false,counter_passed_threhold);
  } else if(state == FINAL) {
    if(MY_VERBOSITY == LOW_VERB) {
      Serial.println("In FINAL state");
    }
    Serial.println("DONE");
    while(true){ // TODO: need to send data to application here
      delay(1000);
    }
  }
  delay(100);
}
