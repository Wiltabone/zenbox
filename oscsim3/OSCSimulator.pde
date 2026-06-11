/**
 * OSC Simulator for Processing  —  v3
 * ─────────────────────────────────────────────────────────────────────────────
 * Control layout:
 *   Row 1 — 3× Analog pots           → /pot/0–2          (float 0–1)
 *   Row 2 — 3× Toggle 2-state        → /toggleA/0–2      (int 0/1)
 *   Row 3 — 2× Toggle 3-state        → /toggle3/0–1      (int 0/1/2)
 *   Row 4 — 4× Linear faders         → /slider/0–3       (float 0–1)
 *   Row 5 — 3× Momentary buttons     → /button/0–2       (int 1)
 *
 * Dependencies (install via Sketch → Import Library → Manage Libraries):
 *   oscP5      by Andreas Schlegel
 *   controlP5  by Andreas Schlegel
 * ─────────────────────────────────────────────────────────────────────────────
 */

import oscP5.*;
import netP5.*;
import controlP5.*;

// ── OSC Config ────────────────────────────────────────────────────────────────
final String OSC_HOST    = "127.0.0.1";
final int    OSC_PORT    = 9999;
final int    LISTEN_PORT = 9001;

OscP5      oscP5;
NetAddress target;
ControlP5  cp5;

// ── Canvas ────────────────────────────────────────────────────────────────────
final int W = 900;
final int H = 680;

// ── Palette ───────────────────────────────────────────────────────────────────
color BG           = color(16, 16, 20);
color PANEL_BG     = color(24, 24, 30);
color TRACK_BG     = color(36, 36, 44);
color ACCENT_CYAN  = color(0, 215, 195);
color ACCENT_AMB   = color(255, 178, 36);
color ACCENT_ROSE  = color(220, 60, 100);
color ACCENT_LILAC = color(160, 120, 255);
color MUTED        = color(70, 75, 92);
color TEXT_DIM     = color(120, 128, 148);
color TEXT_BRIGHT  = color(215, 220, 235);
color LOG_BG       = color(10, 11, 15);
color OK_GREEN     = color(50, 195, 95);

// ── Log ───────────────────────────────────────────────────────────────────────
final int LOG_X   = 620;
final int LOG_Y   = 56;
final int LOG_W   = 258;
final int LOG_H   = 580;
final int MAX_LOG = 22;
ArrayList<String>  logLines  = new ArrayList<String>();
ArrayList<Integer> logColors = new ArrayList<Integer>();

// ── State ─────────────────────────────────────────────────────────────────────
float[]   potValues    = new float[3];
boolean[] toggleA      = new boolean[3];
int[]     toggle3      = new int[2];    // values 0, 1, 2
float[]   sliderValues = new float[4];

// ── Panel geometry ────────────────────────────────────────────────────────────
final int PX  = 18;   // panel left
final int PW  = 580;  // panel width
final int PY  = 56;   // panel top

// Row Y positions (tops of content areas, below section header)
final int ROW_POT      = 90;
final int ROW_TOGGA    = 210;
final int ROW_TOGG3    = 290;
final int ROW_SLIDER   = 380;
final int ROW_BTN      = 540;
final int PANEL_BOTTOM = 588;

// ── 3-state toggle hit areas (drawn manually) ─────────────────────────────────
// Each 3-state toggle: 3 segments side by side
// We'll lay them out in drawToggle3 and detect clicks in mousePressed
final int T3_W  = 52;   // total width of one 3-state switch widget
final int T3_H  = 28;
final int T3_SEG = T3_W / 3;

// Computed x positions of 3-state toggles (set in buildControls)
int[] t3X = new int[2];
int   t3Y;

// ── 2-state toggle hit areas ──────────────────────────────────────────────────
final int T2_W = 52;
final int T2_H = 26;
int[] tAX = new int[3]; int tAY;

// ── Button hit areas ──────────────────────────────────────────────────────────
final int BTN_W = 80;
final int BTN_H = 34;
int[] btnX = new int[3]; int btnY;
boolean[] btnPressed = new boolean[3];

// ─────────────────────────────────────────────────────────────────────────────
void setup() {
  size(900, 620);
  surface.setTitle("Zen Box OSC Simulator v.3.0 — " + OSC_HOST + ":" + OSC_PORT);

  oscP5  = new OscP5(this, LISTEN_PORT);
  target = new NetAddress(OSC_HOST, OSC_PORT);

  cp5 = new ControlP5(this);
  cp5.setAutoDraw(false);

  // init default values
  for (int i = 0; i < 3; i++) potValues[i] = 0.5;
  for (int i = 0; i < 4; i++) sliderValues[i] = 0.5;

  buildControls();
  addLog("Ready → " + OSC_HOST + ":" + OSC_PORT, ACCENT_CYAN);
}

// ─────────────────────────────────────────────────────────────────────────────
void draw() {
  background(BG);
  drawPanel();
  drawSections();
  drawToggle2Row(tAX, tAY, toggleA, "toggleA");
  drawToggle3Row();
  drawValueReadouts();
  drawButtons();
  drawLogPanel();
  cp5.draw();
  drawTargetBadge();
}

// ─────────────────────────────────────────────────────────────────────────────
//  Build controlP5 controls (pots + sliders only — toggles/buttons drawn raw)
// ─────────────────────────────────────────────────────────────────────────────
void buildControls() {
  int spacing = 160;
  int sx = PX + 40;

  // ── Pots ──────────────────────────────────────────────────────────────────
  String[] potLabels = { "FREQUENCY", "RESONANCE", "CHAOS" };
  for (int i = 0; i < 3; i++) {
    final int fi = i;
    cp5.addKnob("pot_" + i)
       .setPosition(sx + i * spacing, ROW_POT)
       .setSize(80, 80)
       .setRange(0, 4096)
       .setValue(2048)
       .setLabel(potLabels[i])
       .setColorForeground(ACCENT_CYAN)
       .setColorBackground(TRACK_BG)
       .setColorActive(color(0, 255, 235))
       .setColorLabel(TEXT_DIM)
       .onChange(new CallbackListener() {
         public void controlEvent(CallbackEvent e) {
           float v = e.getController().getValue();
           potValues[fi] = v;
           int inc_fi = fi+1;
           sendOSCf("/dial/" + inc_fi, v);
         }
       });
  }

  // ── Sliders ───────────────────────────────────────────────────────────────
  String[] sliderLabels = { "RATE", "DEPTH", "DECAY", "BLUR" };
  int sliderSpacing = 130;
  int sliderSX = PX + 40;
  for (int i = 0; i < 4; i++) {
    final int fi = i;
    cp5.addSlider("slider_" + i)
       .setPosition(sliderSX + i * sliderSpacing, ROW_SLIDER + 10)
       .setSize(18, 120)
       .setRange(0, 4096)
       .setValue(2048)
       .setLabel(sliderLabels[i])
       .setColorForeground(ACCENT_AMB)
       .setColorBackground(MUTED)
       .setColorActive(color(255, 210, 80))
       .setColorLabel(TEXT_DIM)
       .onChange(new CallbackListener() {
         public void controlEvent(CallbackEvent e) {
           float v = e.getController().getValue();
           sliderValues[fi] = v;
           int incfi_slider = fi+1;
           sendOSCf("/slider/" + incfi_slider, v);
         }
       });
  }

  // ── Precompute hit-areas for hand-drawn controls ──────────────────────────
  int toggleSpacing = 160;
  int toggleSX = PX + 50;

  // 2-state row A
  tAY = ROW_TOGGA;
  for (int i = 0; i < 3; i++) tAX[i] = toggleSX + i * toggleSpacing;

  // 3-state row
  t3Y = ROW_TOGG3;
  int t3Spacing = 160;
  int t3SX = PX + 50;
  for (int i = 0; i < 2; i++) t3X[i] = t3SX + i * t3Spacing;

  // Buttons
  btnY = ROW_BTN;
  int btnSpacing = 160;
  int btnSX = PX + 50;
  for (int i = 0; i < 3; i++) btnX[i] = btnSX + i * btnSpacing;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Draw helpers
// ─────────────────────────────────────────────────────────────────────────────

void drawPanel() {
  fill(PANEL_BG);
  noStroke();
  rect(PX, PY, PW, PANEL_BOTTOM - PY, 6);
}

void drawSections() {
  // Section labels + dividers
  PFont mono = createFont("Courier", 9, true);
  textFont(mono);
  textAlign(LEFT, CENTER);
  textSize(9);

  String[][] sections = {
    { "ANALOG POTS",             "/pot/0–2",      str(PY + 14),   str(ROW_POT - 4) },
    { "TOGGLE SWITCHES",         "/toggleA/0–2",  str(ROW_TOGGA - 20), str(ROW_TOGGA - 4) },
    { "3-STATE SELECTORS",       "/toggle3/0–1",  str(ROW_TOGG3 - 20), str(ROW_TOGG3 - 4) },
    { "LINEAR FADERS",           "/slider/0–3",   str(ROW_SLIDER - 20), str(ROW_SLIDER - 4) },
    { "BUTTONS",                 "/button/0–2",   str(ROW_BTN - 20),   str(ROW_BTN - 4) },
  };

  for (String[] s : sections) {
    int labelY = int(s[2]);
    int lineY  = int(s[3]);
    fill(TEXT_DIM);
    text(s[0], PX + 14, labelY);
    fill(MUTED);
    text("  ·  " + s[1], PX + 14 + textWidth(s[0]), labelY);
    stroke(MUTED, 140);
    strokeWeight(1);
    line(PX + 14, lineY, PX + PW - 14, lineY);
    noStroke();
  }
}

// ── 2-state toggle row ────────────────────────────────────────────────────────
void drawToggle2Row(int[] xs, int y, boolean[] states, String group) {
  String[] labels = group.equals("toggleA")
    ? new String[]{ "FREEZE", "INVERT", "MIRROR" }
    : new String[]{ "STROBE", "LOOP",   "MUTE"   };

  for (int i = 0; i < 3; i++) {
    boolean on = states[i];
    int x = xs[i];

    // track
    noStroke();
    fill(on ? color(0, 100, 90) : TRACK_BG);
    rect(x, y, T2_W, T2_H, 4);

    // thumb
    int thumbX = on ? x + T2_W - T2_H + 2 : x + 2;
    fill(on ? ACCENT_CYAN : MUTED);
    rect(thumbX, y + 2, T2_H - 4, T2_H - 4, 3);

    // LED dot
    noStroke();
    fill(on ? ACCENT_CYAN : MUTED, on ? 255 : 120);
    ellipse(x + T2_W / 2, y - 8, 6, 6);
    if (on) { fill(ACCENT_CYAN, 50); ellipse(x + T2_W / 2, y - 8, 14, 14); }

    // label
    fill(TEXT_DIM);
    textAlign(CENTER, TOP);
    textSize(8);
    text(labels[i], x + T2_W / 2, y + T2_H + 4);
  }
}

// ── 3-state toggle row ────────────────────────────────────────────────────────
void drawToggle3Row() {
  String[][] segLabels = {
    { "OFF", "A", "B" },
    { "OFF", "X", "Y" }
  };
  color[] segColors = { MUTED, OK_GREEN, ACCENT_LILAC };

  for (int i = 0; i < 2; i++) {
    int x = t3X[i];
    int y = t3Y;
    int state = toggle3[i];

    // background track
    noStroke();
    fill(TRACK_BG);
    rect(x, y, T3_W, T3_H, 4);

    // active segment highlight
    fill(segColors[state], 60);
    rect(x + state * T3_SEG, y, T3_SEG, T3_H,
         state == 0 ? 4 : 0, state == 2 ? 4 : 0, state == 2 ? 4 : 0, state == 0 ? 4 : 0);

    // segment dividers + labels
    for (int s = 0; s < 3; s++) {
      boolean active = (s == state);
      // divider line
      if (s > 0) {
        stroke(MUTED, 100);
        line(x + s * T3_SEG, y + 4, x + s * T3_SEG, y + T3_H - 4);
        noStroke();
      }
      // label
      fill(active ? segColors[s] : TEXT_DIM);
      textAlign(CENTER, CENTER);
      textSize(8);
      text(segLabels[i][s], x + s * T3_SEG + T3_SEG / 2, y + T3_H / 2);
    }

    // outer border
    strokeWeight(1);
    stroke(active3Color(state));
    noFill();
    rect(x, y, T3_W, T3_H, 4);
    noStroke();

    // LED
    noStroke();
    fill(segColors[state], 200);
    ellipse(x + T3_W / 2, y - 8, 6, 6);
    fill(segColors[state], 50);
    ellipse(x + T3_W / 2, y - 8, 14, 14);

    // label below
    fill(TEXT_DIM);
    textAlign(CENTER, TOP);
    textSize(8);
    text("SELECT " + i, x + T3_W / 2, y + T3_H + 4);

    // value readout
    fill(segColors[state]);
    textSize(9);
    text("" + state, x + T3_W / 2, y + T3_H + 16);
  }
}

color active3Color(int state) {
  if (state == 0) return MUTED;
  if (state == 1) return OK_GREEN;
  return ACCENT_LILAC;
}

// ── Buttons ───────────────────────────────────────────────────────────────────
void drawButtons() {
  String[] labels = { "TRIGGER", "RESET", "PULSE" };
  for (int i = 0; i < 3; i++) {
    boolean pressed = btnPressed[i];
    int x = btnX[i];
    int y = btnY;
    noStroke();
    fill(pressed ? ACCENT_ROSE : color(80, 20, 40));
    rect(x, y, BTN_W, BTN_H, 4);
    // top highlight
    fill(255, pressed ? 0 : 30);
    rect(x, y, BTN_W, 2, 4, 4, 0, 0);
    // label
    fill(TEXT_BRIGHT);
    textAlign(CENTER, CENTER);
    textSize(9);
    text(labels[i], x + BTN_W / 2, y + BTN_H / 2);
  }
}

// ── Value readouts under pots/sliders ─────────────────────────────────────────
void drawValueReadouts() {
  textAlign(CENTER, TOP);
  textSize(9);
  int spacing = 160;
  int sx = PX + 40;
  for (int i = 0; i < 3; i++) {
    fill(ACCENT_CYAN);
    text(nf(potValues[i], 1, 2), sx + i * spacing + 40, ROW_POT + 86);
  }
  int sliderSpacing = 130;
  int sliderSX = PX + 40;
  for (int i = 0; i < 4; i++) {
    fill(ACCENT_AMB);
    text(nf(sliderValues[i], 1, 2), sliderSX + i * sliderSpacing + 9, ROW_SLIDER + 138);
  }
}

// ── Log panel ─────────────────────────────────────────────────────────────────
void drawLogPanel() {
  noStroke();
  fill(LOG_BG);
  rect(LOG_X, LOG_Y, LOG_W, LOG_H, 4);
  fill(PANEL_BG);
  rect(LOG_X, LOG_Y, LOG_W, 22, 4, 4, 0, 0);
  fill(TEXT_DIM);
  textAlign(LEFT, CENTER);
  textSize(9);
  PFont mono = createFont("Courier", 9, true);
  textFont(mono);
  text("OSC LOG", LOG_X + 10, LOG_Y + 11);
  textSize(9);
  for (int i = 0; i < logLines.size(); i++) {
    fill(logColors.get(i));
    text(logLines.get(i), LOG_X + 8, LOG_Y + 30 + i * 24);
  }
}

void drawTargetBadge() {
  noStroke();
  fill(MUTED, 180);
  rect(LOG_X, 14, LOG_W, 32, 4);
  fill(TEXT_BRIGHT);
  textAlign(CENTER, CENTER);
  textSize(11);
  text(OSC_HOST + ":" + OSC_PORT, LOG_X + LOG_W / 2, 30);
  fill(TEXT_DIM);
  textSize(8);
  text("OSC TARGET", LOG_X + LOG_W / 2, 18);
}

// ─────────────────────────────────────────────────────────────────────────────
//  Mouse interaction (for hand-drawn controls)
// ─────────────────────────────────────────────────────────────────────────────
void mousePressed() {
  // 2-state toggles A
  for (int i = 0; i < 3; i++) {
    if (hitTest(mouseX, mouseY, tAX[i], tAY, T2_W, T2_H)) {
      toggleA[i] = !toggleA[i];
      int inc2way = i+1;
      sendOSCi("/2way/" + inc2way, toggleA[i] ? 1 : 0);
    }
  }
  // 3-state toggles — click on a segment to select it
  for (int i = 0; i < 2; i++) {
    if (hitTest(mouseX, mouseY, t3X[i], t3Y, T3_W, T3_H)) {
      int seg = (mouseX - t3X[i]) / T3_SEG;
      seg = constrain(seg, 0, 2);
      toggle3[i] = seg;
      int inc3way = i+1;
      sendOSCi("/3way/" + inc3way, seg);
    }
  }
  // Buttons
  for (int i = 0; i < 3; i++) {
    if (hitTest(mouseX, mouseY, btnX[i], btnY, BTN_W, BTN_H)) {
      btnPressed[i] = true;
      int incbtn = i+1;
      sendOSCi("/button/" + incbtn, 1);
    }
  }
}

void mouseReleased() {
  for (int i = 0; i < 3; i++) btnPressed[i] = false;
}

boolean hitTest(int mx, int my, int x, int y, int w, int h) {
  return mx >= x && mx <= x + w && my >= y && my <= y + h;
}

// ─────────────────────────────────────────────────────────────────────────────
//  OSC
// ─────────────────────────────────────────────────────────────────────────────
void sendOSCf(String address, float value) {
  OscMessage msg = new OscMessage(address);
  msg.add(value);
  oscP5.send(msg, target);
  addLog("→ " + address + "  " + nf(value, 1, 3), ACCENT_CYAN);
}

void sendOSCi(String address, int value) {
  OscMessage msg = new OscMessage(address);
  msg.add(value);
  oscP5.send(msg, target);
  color c = address.startsWith("/toggle3") ? ACCENT_LILAC
          : address.startsWith("/button")  ? ACCENT_ROSE
          : OK_GREEN;
  addLog("→ " + address + "  " + value, c);
}

void oscEvent(OscMessage msg) {
  String info = "← " + msg.addrPattern();
  if (msg.checkTypetag("f"))      info += "  " + nf(msg.get(0).floatValue(), 1, 3);
  else if (msg.checkTypetag("i")) info += "  " + msg.get(0).intValue();
  else if (msg.checkTypetag("s")) info += "  " + msg.get(0).stringValue();
  addLog(info, OK_GREEN);
}

void addLog(String line, color c) {
  logLines.add(line);
  logColors.add(c);
  if (logLines.size() > MAX_LOG) {
    logLines.remove(0);
    logColors.remove(0);
  }
}
