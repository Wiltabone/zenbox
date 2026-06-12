/*
  The Reflective Zen Box
  Controller code for Arduino Mega
  by Wilbert Tabone & Thijs Prakken, 2026

  Sends control messages over Serial (USB) directly to the Raspberry Pi.
  Each message is one line: /address value\n

  Pin mapping:
    Dials    A0=/dial/1   A1=/dial/2   A2=/dial/3
    Sliders  A3=/slider/1 A4=/slider/2 A5=/slider/3 A6=/slider/4
    2-way    D2=/2way/1   D3=/2way/2   D4=/2way/3
    3-way    D5+D6=/3way/1  (both HIGH=0, D5 LOW=1, D6 LOW=2)
             D7+D8=/3way/2  (both HIGH=0, D7 LOW=1, D8 LOW=2)
    Buttons  D9=/button/1  D10=/button/2  D11=/button/3

  All digital inputs use INPUT_PULLUP — wire to GND when active.
  Analog values are scaled from 10-bit (0-1023) to 0-4096 to match
  the adcRes setting in index.html.
*/

// ── Analog pins ──────────────────────────────────────────────────
const int ANALOG_PINS[] = { A0, A1, A2, A3, A4, A5, A6 };
const char* ANALOG_ADDR[] = {
  "/dial/1", "/dial/2", "/dial/3",
  "/slider/1", "/slider/2", "/slider/3", "/slider/4"
};

// ── Digital pins ─────────────────────────────────────────────────
#define SW2_1_PIN  2
#define SW2_2_PIN  3
#define SW2_3_PIN  4
#define SW3_1A_PIN 5
#define SW3_1B_PIN 6
#define SW3_2A_PIN 7
#define SW3_2B_PIN 8
#define BTN1_PIN   9
#define BTN2_PIN   10
#define BTN3_PIN   11

const int   SW2_PINS[]  = { SW2_1_PIN,  SW2_2_PIN,  SW2_3_PIN  };
const char* SW2_ADDR[]  = { "/2way/1",  "/2way/2",  "/2way/3"  };
const int   BTN_PINS[]  = { BTN1_PIN,   BTN2_PIN,   BTN3_PIN   };
const char* BTN_ADDR[]  = { "/button/1", "/button/2", "/button/3" };

// ── Analog smoothing & threshold ─────────────────────────────────
const float SMOOTH = 0.7;   // 0=no smoothing, higher=smoother/slower
const int   THRESH = 8;     // minimum change required to send (0–4096 scale)

float smoothed[7];
int   prevAnalog[7];

// ── Digital history ───────────────────────────────────────────────
int prev2way[3] = { -1, -1, -1 };
int prev3way[2] = { -1, -1 };
int prevBtn[3]  = { -1, -1, -1 };

unsigned long btnLastChange[3]  = { 0, 0, 0 };
const unsigned long DEBOUNCE_MS = 50;

// ── Helpers ───────────────────────────────────────────────────────
void sendMsg(const char* addr, int val) {
  Serial.print(addr);
  Serial.print(' ');
  Serial.println(val);
}

// Returns 0, 1, or 2 based on which leg of the 3-way switch is pulled low.
int read3way(int pinA, int pinB) {
  if (!digitalRead(pinA)) return 1;
  if (!digitalRead(pinB)) return 2;
  return 0;
}

// ── Setup ─────────────────────────────────────────────────────────
void setup() {
  Serial.begin(115200);

  // Seed the smoother with the first real readings so startup is instant
  for (int i = 0; i < 7; i++) {
    pinMode(ANALOG_PINS[i], INPUT);
    smoothed[i]   = map(analogRead(ANALOG_PINS[i]), 0, 1023, 0, 4096);
    prevAnalog[i] = (int)smoothed[i];
  }

  // All digital inputs pulled high — active when connected to GND
  const int digitalPins[] = {
    SW2_1_PIN, SW2_2_PIN, SW2_3_PIN,
    SW3_1A_PIN, SW3_1B_PIN, SW3_2A_PIN, SW3_2B_PIN,
    BTN1_PIN, BTN2_PIN, BTN3_PIN
  };
  for (int i = 0; i < 10; i++) {
    pinMode(digitalPins[i], INPUT_PULLUP);
  }
}

// ── Loop ──────────────────────────────────────────────────────────
void loop() {

  // Analog inputs: smooth → threshold → send
  for (int i = 0; i < 7; i++) {
    int raw = map(analogRead(ANALOG_PINS[i]), 0, 1023, 0, 4096);
    smoothed[i] = raw * (1.0 - SMOOTH) + smoothed[i] * SMOOTH;
    int val = (int)smoothed[i];
    if (abs(val - prevAnalog[i]) > THRESH) {
      prevAnalog[i] = val;
      sendMsg(ANALOG_ADDR[i], val);
    }
  }

  // 2-way switches: send on change
  for (int i = 0; i < 3; i++) {
    int val = !digitalRead(SW2_PINS[i]);
    if (val != prev2way[i]) {
      prev2way[i] = val;
      sendMsg(SW2_ADDR[i], val);
    }
  }

  // 3-way switches: send on change
  int v3_1 = read3way(SW3_1A_PIN, SW3_1B_PIN);
  if (v3_1 != prev3way[0]) { prev3way[0] = v3_1; sendMsg("/3way/1", v3_1); }

  int v3_2 = read3way(SW3_2A_PIN, SW3_2B_PIN);
  if (v3_2 != prev3way[1]) { prev3way[1] = v3_2; sendMsg("/3way/2", v3_2); }

  // Buttons: debounce + send on change
  unsigned long now = millis();
  for (int i = 0; i < 3; i++) {
    int val = !digitalRead(BTN_PINS[i]);
    if (val != prevBtn[i] && (now - btnLastChange[i]) > DEBOUNCE_MS) {
      prevBtn[i]       = val;
      btnLastChange[i] = now;
      sendMsg(BTN_ADDR[i], val);
    }
  }

  delay(5);
}
