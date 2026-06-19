import java.util.HashMap;
import java.util.ArrayList;
import processing.core.PImage;
import processing.core.PFont;
import processing.core.PGraphics;
import android.content.Context;
import android.view.inputmethod.InputMethodManager;
import android.view.WindowManager;

// @pde.add-android-attr(android:resizeableActivity, "true") 

HashMap<String, PImage> charImages;
HashMap<String, String> charDescriptions;
HashMap<String, String[]> predefinedCommands;
String inputText = "";
int displayMode = 1;
int charSize = 150;
float latinScaleFactor = 0.5;
float latinBaselineOffset = -3;
float latinCharSpacing = 5;
float specialCharScaleFactor = 1;
float specialCharBaselineOffset = -4;
float lineThickness = 5;
int lastClickTime = 0;
int doubleClickThreshold = 300;
int maxTextLength = 50;
boolean inputActive = false;
int activeSigilIndex = -1;
boolean uiActive=true;
PFont font;
PGraphics displayGraphics; // NEW: PGraphics object for off-screen drawing
float blackPixel = 50;
// NEW: Class to hold sigil data
class Sigil {
  String input = "";
  color c;
  // NEW: Animation state for each sigil
  float progress = 0;
  float prevPointX = 0;
  float prevPointY = 0;
  boolean firstDraw = true;
}

ArrayList<Sigil> sigils = new ArrayList<Sigil>();
String[] doubleCharKeys = {"ch", "sh", "s2", "t2", "sch"};
float outerCircleRadiusOffset = 50;
float innerCircleRadiusOffset = -50;
float outerCircleThickness = 2;
float innerCircleThickness = 2;

float manualRadius = 0;
float manualSquareSize = 0;
float manualCircularCharSize = 150;
float manualSquareCharSize = 150;
color[] colorPalette;
float startAngleOffset = 0;
float animationSpeed = 0.01;
float trailHardness = 50;
float spriteSize=lineThickness*2;
// NEW: save settings on app pause
void onPause() {
  super.onPause();
  saveSettings();
}

int bgColor=0;
int drawColor=200;
float boxXbgBlack;
float boxXbgWhite;
float boxYbg;
               



boolean showInstructions=true;
int count=0;
String[] explanation1 = {
      "+/- : Neues Sigill / Sigill löschen.",
      "Wischen vertikal links: Größe.",
      "Wischen vertikal rechts: Winkel.",
      "Doppeltipp: Nächste Seite."
};
 
String[] explanation25 = {
      "Wischen vertikal: Schriftgröße.",
      "Lange drücken: Hintergrund Ausblenden.",
      "Doppeltipp: Nächste Seite."
};
 
String[] explanation36 = {
      "Wischen vertikal links: Geschwindigkeit.",
      "Wischen vertikal rechts: Spurlänge.",
      "Lange drücken: Hintergrund Ausblenden.",
      "Doppeltipp: Nächste Seite."
};
 
String[] explanation4 = {
      "Planetenquadrate:",
      "*saturn *jupiter *mars *sonne",
      "*venus *merkur *mond",
      " ",
      "+/- : Neues Sigill / Sigill löschen.",
      "Wischen vertikal links: Größe.",
      "Doppeltipp: Nächste Seite."
};

// NEW: added for long press functionality
long touchStartTime = 0;
boolean isDrawingBackground = true;
// NEW: to check if there was a swipe
float touchStartX, touchStartY;


void saveSettings() {
  String[] settings = new String[20 + sigils.size() * 2];
  settings[0] = inputText;
  settings[1] = str(displayMode);
  settings[2] = str(charSize);
  settings[3] = str(latinScaleFactor);
  settings[4] = str(latinBaselineOffset);
  settings[5] = str(latinCharSpacing);
  settings[6] = str(specialCharScaleFactor);
  settings[7] = str(specialCharBaselineOffset);
  settings[8] = str(lineThickness);
  settings[9] = str(manualRadius);
  settings[10] = str(manualSquareSize);
  settings[11] = str(manualCircularCharSize);
  settings[12] = str(manualSquareCharSize);
  settings[13] = str(startAngleOffset);
  settings[14] = str(animationSpeed);
  settings[15] = str(trailHardness);
  settings[16] = str(uiActive);
  settings[17] = str(sigils.size());
  settings[18] = str(isDrawingBackground); // NEW

  int index = 19;
  for (Sigil s : sigils) {
    settings[index++] = s.input;
    settings[index++] = str(s.c);
  }
  
  saveStrings("settings.dat", settings);
  println("Settings saved.");
}

void loadSettings() {
  String[] settings = loadStrings("settings.dat");
  if (settings != null) {
    inputText = settings[0];
    displayMode = int(settings[1]);
    charSize = int(settings[2]);
    latinScaleFactor = float(settings[3]);
    latinBaselineOffset = float(settings[4]);
    latinCharSpacing = float(settings[5]);
    specialCharScaleFactor = float(settings[6]);
    specialCharBaselineOffset = float(settings[7]);
    lineThickness = float(settings[8]);
    manualRadius = float(settings[9]);
    manualSquareSize = float(settings[10]);
    manualCircularCharSize = float(settings[11]);
    manualSquareCharSize = float(settings[12]);
    startAngleOffset = float(settings[13]);
    animationSpeed = float(settings[14]);
    trailHardness = float(settings[15]);
    uiActive = boolean(settings[16]);

    sigils.clear();
    int numSigils = int(settings[17]);
    isDrawingBackground = boolean(settings[18]); // NEW
    int index = 19;
    for (int i = 0; i < numSigils; i++) {
      Sigil s = new Sigil();
      s.input = settings[index++];
      s.c = color(int(settings[index++]));
      sigils.add(s);
    }
    println("Settings loaded.");
  } else {
    println("No settings file found, using defaults.");
    Sigil defaultSigil = new Sigil();
    defaultSigil.c = colorPalette[0];
    sigils.add(defaultSigil);
  }
}

void setup() {
  fullScreen();
//  frameRate(20);
  background(bgColor);
  font = createFont("Serif", charSize);
  textFont(font);
  colorPalette = new color[]{
    color(255),
    color(0, 191, 255),
    color(69, 139, 116),
    color(255, 0, 0),
    color(255, 215, 0),
    color(139, 69, 19),
    color(0)
  };
// NEW: Load settings at startup
  loadSettings();
  displayGraphics = createGraphics(width, height);
// NEW: Initialize PGraphics

  charImages = new HashMap<String, PImage>();
  charDescriptions = new HashMap<String, String>();
  predefinedCommands = new HashMap<String, String[]>();
  String[] lines = loadStrings("malachim.txt");
  if (lines == null || lines.length == 0) {
    return;
  }
  
  for (int i = 0; i < lines.length; i++) {
    String line = lines[i].trim();
    if (line.isEmpty() || line.startsWith("//")) continue;

    if (line.startsWith("*")) {
        String trimmedLine = line.substring(1).trim();
        int firstSpaceIndex = trimmedLine.indexOf(' ');
        if (firstSpaceIndex != -1) {
            String key = trimmedLine.substring(0, firstSpaceIndex);
            String valuesString = trimmedLine.substring(firstSpaceIndex + 1);
            String[] values = split(valuesString, ';');
            predefinedCommands.put(key, values);
        }
        continue;
    }

    String[] parts = split(line, ' ');
    if (parts.length >= 2) {
      String key = parts[0];
      String filename = parts[1];
      String description = null;
      if (parts.length >= 3) {
          description = join(subset(parts, 2), " ");
      }
      PImage img = loadImage(filename);
      if (img != null) {
        
       
      img = makeBlackTransparent(img);
       
        
        charImages.put(key, img);
        if (description != null) {
          charDescriptions.put(key, description);
        }
      }
    }
  }
}



PImage makeBlackTransparent(PImage img) {
  img.loadPixels();
  
  // Invertiere die Pixel manuell bei Zeichen Schwarz auf Weiß 
 
    for (int i = 0; i < img.pixels.length; i++) {
      int pixel = img.pixels[i];
      int r = (pixel >> 16) & 0xFF;
      int g = (pixel >> 8) & 0xFF;
      int b = pixel & 0xFF;
    
      // Invertierung: 255 - Farbwert
    
      r = 255 - r;
      g = 255 - g;
      b = 255 - b;
      img.pixels[i] = 0xFF000000 | (r << 16) | (g << 8) | b;
    
      // Schwarze Pixel transparent machen
    
      if (r<blackPixel && g<blackPixel && b<blackPixel){
      img.pixels[i] = color(0, 0, 0, 0);
      }
   }
  
   img.updatePixels();
   return img;
  
}

void draw() {
  
  if (displayMode == 2 || displayMode == 5) {
      frameRate(5);
  } else if (displayMode == 3 || displayMode == 6) {
      frameRate(30);
  } else {
      frameRate(20);
  }
  
  try {
    if (getActivity() != null) {
      getActivity().runOnUiThread(new Runnable() {
        @Override
        public void run() {
          if (displayMode == 3 || displayMode == 6) {
            getActivity().getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
          } else {
         
           getActivity().getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
          }
        }
      });
    }
  } catch (Exception e) {
    println("Fehler bei FLAG_KEEP_SCREEN_ON: " + e.getMessage());
  }

// NEW: Start drawing on the PGraphics object
  displayGraphics.beginDraw();
// NEW: Draw the semi-transparent background on the PGraphics object for trailing effect
  if (displayMode == 3 || displayMode == 6) {
    displayGraphics.fill(bgColor, trailHardness);
    displayGraphics.noStroke();
    displayGraphics.rect(0, 0, width, height);
  } else {
    displayGraphics.background(bgColor);
  }
  
  String cleanedText = inputText;
  ArrayList<float[]> sigilPositions = null;
  // NEW: Check if characters and shapes should be drawn
  if (isDrawingBackground) {
      if (displayMode == 1 || displayMode == 2 || displayMode == 3) {
          sigilPositions = drawCircular(cleanedText, width/2, height/2, displayGraphics);
      } else if (displayMode == 4 || displayMode == 5 || displayMode == 6) {
          sigilPositions = drawSquare(cleanedText, width/2, height/2, displayMode, displayGraphics);
      }
  } else {
      // Wenn keine Hintergrundelemente gezeichnet werden, müssen die Positionen trotzdem berechnet werden,
      // damit die Sigillenlinien richtig gezeichnet werden können
      if (displayMode == 1 || displayMode == 2 || displayMode == 3) {
          sigilPositions = getCircularPositions(cleanedText, width/2, height/2, displayGraphics);
      } else if (displayMode == 4 || displayMode == 5 || displayMode == 6) {
          sigilPositions = getSquarePositions(cleanedText, width/2, height/2, displayMode, displayGraphics);
      }
  }
  
  if (sigilPositions != null) {
      for (Sigil s : sigils) {
          if (!s.input.isEmpty()) {
              drawSigilLines(sigilPositions, displayMode, s, displayGraphics);
          }
      }
  }
 
  if (uiActive) {
    drawUI(displayGraphics);
  }
  
  if (showInstructions) {
    drawInstructions(displayGraphics);
  } else {
    displayGraphics.fill(bgColor, 255);
    displayGraphics.noStroke();
    displayGraphics.rect(0, height, width, -height/4);
  }
  
// NEW: End drawing and display the PGraphics object on the main screen
  displayGraphics.endDraw();
  image(displayGraphics, 0, 0);
}

// NEW: drawUI now draws to a PGraphics object
void drawUI(PGraphics pg) {
    pg.pushStyle();
    pg.noStroke();
    float inputWidth = width * 0.4;
    float inputHeight = height * 0.05;
    float inputX = width * 0.02;
    float inputY1 = height * 0.05;
    
    pg.fill(drawColor);
    pg.textSize(min(width, height) * 0.04);
    pg.fill(inputActive ? 100 : 50);
    pg.stroke(drawColor);
    pg.rect(inputX, inputY1, inputWidth, inputHeight);
    pg.fill(drawColor);
    pg.textAlign(LEFT, CENTER);
    pg.text(inputText, inputX + 5, inputY1 + inputHeight/2);
    
    float sigilInputY = height * 0.15;
    for (int i = 0; i < sigils.size(); i++) {
        Sigil s = sigils.get(i);
        pg.fill(i == activeSigilIndex ? 100 : 50);
        pg.stroke(drawColor);
        pg.rect(inputX, sigilInputY + i * (inputHeight + 10), inputWidth, inputHeight);
        pg.fill(drawColor);
        pg.textAlign(LEFT, CENTER);
        pg.text(s.input, inputX + 5, sigilInputY + i * (inputHeight + 10) + inputHeight/2);
        if (!inputActive && activeSigilIndex == -1) {
            float boxSize = min(width, height) * 0.06;
            float startX = width - boxSize * colorPalette.length - ((colorPalette.length - 1) * 10) - width * 0.02;
            float startY = sigilInputY + i * (inputHeight + 10);
            
            // Palette Hintergrundfarbe 
            float startXbg = width - boxSize * colorPalette.length - ((colorPalette.length - 1) * 10) - width * 0.02;
            float startYbg = inputY1 + i * (inputHeight + 10);
            boxXbgBlack = startXbg + (boxSize + 10) * 1;
            boxXbgWhite = startXbg + (boxSize + 10) * 0;
            boxYbg = startYbg;
                
            pg.fill(0);
            pg.stroke(200);
            pg.rect(boxXbgBlack, boxYbg, boxSize, boxSize);
             
            pg.fill(255);
            pg.rect(boxXbgWhite, boxYbg, boxSize, boxSize);
             
                
            for (int j = 0; j < colorPalette.length; j++) {
                float boxX = startX + (boxSize + 10) * j;
                float boxY = startY;
                
                pg.fill(colorPalette[j]);
                pg.stroke(200);
                pg.rect(boxX, boxY, boxSize, boxSize);
                if (s.c == colorPalette[j]) {
                    pg.stroke(255, 215, 0);
                    pg.strokeWeight(3);
                    pg.noFill();
                    pg.rect(boxX, boxY, boxSize, boxSize);
                }
            }
        }
    }
    
    float buttonSize = min(width, height) * 0.05;
    float buttonX = inputX;
    float buttonY = sigilInputY + sigils.size() * (inputHeight + 10);

    pg.fill(50, 100, 50);
    pg.stroke(200);
    pg.rect(buttonX, buttonY, buttonSize, buttonSize);
    pg.fill(200);
    pg.textSize(min(width, height) * 0.05);
    pg.textAlign(CENTER, CENTER);
    pg.text("+", buttonX + buttonSize/2, buttonY + buttonSize/2);
    float removeButtonX = buttonX + buttonSize + 10;
    pg.fill(100, 50, 50);
    pg.stroke(200);
    pg.rect(removeButtonX, buttonY, buttonSize, buttonSize);
    pg.fill(200);
    pg.text("-", removeButtonX + buttonSize/2, buttonY + buttonSize/2);

    float contentX = width * 0.6;
    if (inputActive || activeSigilIndex != -1) {
        pg.textSize(min(width, height) * 0.03);
        pg.fill(drawColor);
        pg.textAlign(LEFT, TOP);
        pg.text("Sonderzeichen", contentX, height * 0.05);
        int listY = (int)(height * 0.09);
        for (String key : charDescriptions.keySet()) {
            pg.text(key + " -> " + charDescriptions.get(key), contentX, listY);
            listY += min(width, height) * 0.04;
        }
    }
    pg.popStyle();
}


// NEW: drawInstructions now draws to a PGraphics object
void drawInstructions(PGraphics pg) {
    pg.pushStyle();
    pg.textSize(min(width, height) * 0.04);
    pg.fill(drawColor);
    pg.textAlign(CENTER, BOTTOM);
    float textY = height - 20;
    float lineHeight = min(width, height) * 0.05;
    if (displayMode == 1) {
        for (int i = 0; i < explanation1.length; i++) {
            pg.text(explanation1[i], width / 2, textY - (explanation1.length - 1 - i) * lineHeight);
        }
    } else if (displayMode == 2 || displayMode == 5) {
        showInstructions = false;
        if (count <= 15) {
            count++;
            showInstructions = true;
        }
        for (int i = 0; i < explanation25.length; i++) {
            pg.text(explanation25[i], width / 2, textY - (explanation25.length - 1 - i) * lineHeight);
        }
    } else if (displayMode == 3 || displayMode == 6) {
        showInstructions = false;
        if (count <= 90) {
            count++;
            showInstructions = true;
        }
        for (int i = 0; i < explanation36.length; i++) {
            pg.text(explanation36[i], width / 2, textY - (explanation36.length - 1 - i) * lineHeight);
        }
    } else if (displayMode == 4) {
        for (int i = 0; i < explanation4.length; i++) {
            pg.text(explanation4[i], width / 2, textY - (explanation4.length - 1 - i) * lineHeight);
        }
    }
    pg.popStyle();
}


void keyPressed() {
  
  boolean active = inputActive ||
  activeSigilIndex != -1;
  if (!active) return;
  
  String activeInput = "";
  if (inputActive) {
    activeInput = inputText;
  } else {
    activeInput = sigils.get(activeSigilIndex).input;
  }
  
  if ((key >= 'a' && key <= 'z') || (key >= 'A' && key <= 'Z') || (key >= '0' && key <= '9') || key == '_' || key == ' ' || key == '.' || key == '*') {
    if (activeInput.length() < maxTextLength) {
      if (inputActive) {
        inputText += key;
        if (inputText.startsWith("*")) {
            String command = inputText.substring(1).trim();
            if (predefinedCommands.containsKey(command)) {
                String[] values = predefinedCommands.get(command);
                if (values.length > 0) {
                    inputText = join(values, " ");
                    sigils.get(0).input = "";
                    if (sigils.size() > 1) {
                      sigils = new ArrayList<Sigil>();
                      Sigil defaultSigil = new Sigil();
                      defaultSigil.c = colorPalette[0];
                      sigils.add(defaultSigil);
                    }
                } else {
                    inputText = "";
                    sigils.get(0).input = "";
                }
                
                inputActive = false;
                activeSigilIndex = -1;
                try {
                    InputMethodManager imm = (InputMethodManager) getActivity().getSystemService(Context.INPUT_METHOD_SERVICE);
                    imm.hideSoftInputFromWindow(getActivity().getCurrentFocus().getWindowToken(), 0);
                } catch (Exception e) {}
            }
        }
      } else {
        sigils.get(activeSigilIndex).input += key;
      }
    }
  } else if (keyCode == BACKSPACE || keyCode == DELETE || keyCode == 67) {
    if (activeInput.length() > 0) {
      if (inputActive) {
        inputText = inputText.substring(0, inputText.length() - 1);
      } else {
        Sigil s = sigils.get(activeSigilIndex);
        s.input = s.input.substring(0, s.input.length() - 1);
      }
    }
  } else if (keyCode == 66 || key == ENTER || key == RETURN) {
    if (inputActive) {
      inputActive = false;
    } else {
      activeSigilIndex = -1;
    }
    try {
      InputMethodManager imm = (InputMethodManager) getActivity().getSystemService(Context.INPUT_METHOD_SERVICE);
      imm.hideSoftInputFromWindow(getActivity().getCurrentFocus().getWindowToken(), 0);
    } catch (Exception e) {}
  }
}




void touchStarted() {
  touchStartTime = millis(); // NEW
  // NEW: Store starting touch coordinates
  touchStartX = mouseX;
  touchStartY = mouseY;
  float inputWidth = width * 0.4;
  float inputHeight = height * 0.05;
  float inputX = width * 0.02;
  float inputY1 = height * 0.05;
  float topBuffer = height * 0.02;
  float bottomBuffer = height * 0.2;
  if (mouseY < topBuffer || mouseY > height - bottomBuffer) {
    return;
  }
  
  if (mouseX > inputX && mouseX < inputX + inputWidth && mouseY > inputY1 && mouseY < inputY1 + inputHeight) {
    inputActive = true;
    activeSigilIndex = -1;
    try {
      InputMethodManager imm = (InputMethodManager) getActivity().getSystemService(Context.INPUT_METHOD_SERVICE);
      imm.toggleSoftInput(InputMethodManager.SHOW_FORCED, 0);
    } catch (Exception e) {}
  } else {
    inputActive = false;
    activeSigilIndex = -1;
    float sigilInputY = height * 0.15;
    float boxSize = min(width, height) * 0.06;
    float startX = width - boxSize * colorPalette.length - ((colorPalette.length - 1) * 10) - width * 0.02;
    boolean touchedSomething = false;
    
    // Check sigil input fields and color palettes
    for (int i = 0; i < sigils.size(); i++) {
        float fieldY = sigilInputY + i * (inputHeight + 10);
        if (mouseX > inputX && mouseX < inputX + inputWidth && mouseY > fieldY && mouseY < fieldY + inputHeight) {
          activeSigilIndex = i;
          touchedSomething = true;
          try {
            InputMethodManager imm = (InputMethodManager) getActivity().getSystemService(Context.INPUT_METHOD_SERVICE);
            imm.toggleSoftInput(InputMethodManager.SHOW_FORCED, 0);
          } catch (Exception e) {}
          break;
        }
        
        // NEW: Check for touch on color palette only if not active
        if (!inputActive && activeSigilIndex == -1) {
          
            // Input palette
            
            //bg Palette
            if (mouseY > boxYbg && mouseY <boxYbg + boxSize) {
              if (mouseX > boxXbgBlack && mouseX < boxXbgBlack + boxSize) {
                bgColor=0;
                drawColor=200;
                touchedSomething = true;
                setup();
                break;
              }
               
              if (mouseX > boxXbgWhite && mouseX < boxXbgWhite + boxSize) {
                bgColor=255;
                drawColor=0;
                touchedSomething = true;
                setup();
                break;
              }
               
             }
          
            float paletteY = sigilInputY + i * (inputHeight + 10);
            if (mouseY > paletteY && mouseY < paletteY + boxSize) {
              for (int j = 0; j < colorPalette.length; j++) {
                float boxX = startX + (boxSize + 10) * j;
                if (mouseX > boxX && mouseX < boxX + boxSize) {
                  sigils.get(i).c = colorPalette[j];
                  touchedSomething = true;
                  break;
                }
              }
            }
        }
        if (touchedSomething) break;
    }

    // Check '+' and '-' buttons
    float buttonSize = min(width, height) * 0.05;
    float buttonX = inputX;
    float buttonY = sigilInputY + sigils.size() * (inputHeight + 10);
    float removeButtonX = buttonX + buttonSize + 10;

    if (mouseX > buttonX && mouseX < buttonX + buttonSize && mouseY > buttonY && mouseY < buttonY + buttonSize) {
        Sigil newSigil = new Sigil();
        newSigil.c = colorPalette[0];
        sigils.add(newSigil);
        touchedSomething = true;
    } else if (mouseX > removeButtonX && mouseX < removeButtonX + buttonSize && mouseY > buttonY && mouseY < buttonY + buttonSize) {
        if (sigils.size() > 1) {
            sigils.remove(sigils.size() - 1);
        }
        touchedSomething = true;
    }
    
    if (!touchedSomething) {
      try {
        InputMethodManager imm = (InputMethodManager) getActivity().getSystemService(Context.INPUT_METHOD_SERVICE);
        imm.hideSoftInputFromWindow(getActivity().getCurrentFocus().getWindowToken(), 0);
      } catch (Exception e) {}
    }
  }
}

// NEW: touchEnded function to handle long press
void touchEnded() {
    long pressDuration = millis() - touchStartTime;
    
    // Check if the touch ended without touching any UI element
    float inputWidth = width * 0.4;
    float inputHeight = height * 0.05;
    float inputX = width * 0.02;
    float inputY1 = height * 0.05;
    float sigilInputY = height * 0.15;
    float buttonSize = min(width, height) * 0.05;
    float buttonX = inputX;
    float buttonY = sigilInputY + sigils.size() * (inputHeight + 10);
    float removeButtonX = buttonX + buttonSize + 10;
    
    boolean touchedUI = (mouseX > inputX && mouseX < inputX + inputWidth && mouseY > inputY1 && mouseY < inputY1 + inputHeight) ||
                       (mouseX > buttonX && mouseX < buttonX + buttonSize && mouseY > buttonY && mouseY < buttonY + buttonSize) ||
                       (mouseX > removeButtonX && mouseX < removeButtonX + buttonSize && mouseY > buttonY && mouseY < buttonY + buttonSize);
    
    // Check if any sigil input field or color palette was touched
    for (int i = 0; i < sigils.size(); i++) {
        float fieldY = sigilInputY + i * (inputHeight + 10);
        float boxSize = min(width, height) * 0.06;
        float startX = width - boxSize * colorPalette.length - ((colorPalette.length - 1) * 10) - width * 0.02;

        if ((mouseX > inputX && mouseX < inputX + inputWidth && mouseY > fieldY && mouseY < fieldY + inputHeight) ||
            (mouseY > fieldY && mouseY < fieldY + boxSize && mouseX > startX)) {
            touchedUI = true;
            break;
        }
    }
    
    // NEW: Check if the finger has been moved too far (e.g., more than 10 pixels)
    float moveDistance = dist(touchStartX, touchStartY, mouseX, mouseY);

    if (!touchedUI && (displayMode==2 || displayMode==3 || displayMode==5 || displayMode==6)) {
        if (pressDuration > 500 && moveDistance < 10) { // Long press threshold of 500ms and minimal movement
            isDrawingBackground = !isDrawingBackground;
            
            if (isDrawingBackground == false){
              displayGraphics.fill(0, 255);
              displayGraphics.noStroke();
              displayGraphics.rect(0, 0, width, height);
        }
            
        }
    }
}

void mousePressed() {
  int currentTime = millis();
  if (currentTime - lastClickTime < doubleClickThreshold) {
    float inputWidth = width * 0.4;
    float inputHeight = height * 0.05;
    float inputX = width * 0.02;
    float inputY1 = height * 0.05;
    float sigilInputY = height * 0.15;
    
    boolean touchedInputFields = (mouseX > inputX && mouseX < inputX + inputWidth && mouseY > inputY1 && mouseY < inputY1 + inputHeight);
    boolean colorPaletteTouched = false;
    float boxSize = min(width, height) * 0.06;
    float startX = width - boxSize * colorPalette.length - ((colorPalette.length - 1) * 10) - width * 0.02;
    for (int i = 0; i < sigils.size(); i++) {
        float fieldY = sigilInputY + i * (inputHeight + 10);
        if (mouseX > inputX && mouseX < inputX + inputWidth && mouseY > fieldY && mouseY < fieldY + inputHeight) {
          touchedInputFields = true;
          break;
        }
        
        float paletteY = sigilInputY + i * (inputHeight + 10);
        if (mouseY > paletteY && mouseY < paletteY + boxSize) {
          colorPaletteTouched = true;
          break;
        }
    }
    
    // Check '+' and '-' buttons
    float buttonSize = min(width, height) * 0.05;
    float buttonX = inputX;
    float buttonY = sigilInputY + sigils.size() * (inputHeight + 10);
    float removeButtonX = buttonX + buttonSize + 10;

    boolean touchedButton = (mouseX > buttonX && mouseX < buttonX + buttonSize && mouseY > buttonY && mouseY < buttonY + buttonSize) ||
    (mouseX > removeButtonX && mouseX < removeButtonX + buttonSize && mouseY > buttonY && mouseY < buttonY + buttonSize);
    if (!touchedInputFields && !colorPaletteTouched && !touchedButton) {
      if (displayMode == 1) {
        displayMode = 2;
        uiActive = false;
        count=0;
        showInstructions = true;
        
      } else if (displayMode == 2) {
        displayMode = 3;
        uiActive = false;
        count=0;
        showInstructions = true;
        
        for (Sigil s : sigils) {
          s.firstDraw = true;
          s.progress = 0;
        }
        /*
        if (isDrawingBackground == false){
          displayGraphics.fill(0, 255);
          displayGraphics.noStroke();
          displayGraphics.rect(0, 0, width, height);
        }
        */
      } else if (displayMode == 3) {
        displayMode = 4;
        uiActive = true;
        showInstructions = true;
        isDrawingBackground=true;
        
      } else if (displayMode == 4) {
        displayMode = 5;
        uiActive = false;
        count=0;
        showInstructions = true;
        
      } else if (displayMode == 5) {
        displayMode = 6;
        uiActive = false;
        count=0;
        showInstructions = true;
        
        for (Sigil s : sigils) {
          s.firstDraw = true;
          s.progress = 0;
        }
        /*
        if (isDrawingBackground == false){
          displayGraphics.fill(0, 255);
          displayGraphics.noStroke();
          displayGraphics.rect(0, 0, width, height);
        }
        */
      } else if (displayMode == 6) {
        displayMode = 1;
        uiActive = true;
        showInstructions = true;
        isDrawingBackground=true;
      }
    }
  }
  lastClickTime = currentTime;
}

ArrayList<String> parseText(String text) {
  ArrayList<String> tokens = new ArrayList<String>();
  int i = 0;
  while (i < text.length()) {
    boolean foundMatch = false;
    String currentToken = null;
    int longestMatch = 0;
    for (String key : charImages.keySet()) {
      if (i + key.length() <= text.length()) {
        String potentialKey = text.substring(i, i + key.length());
        if (potentialKey.equals(key) && key.length() > longestMatch) {
          currentToken = key;
          longestMatch = key.length();
        }
      }
    }
    if (currentToken != null) {
      tokens.add(currentToken);
      i += longestMatch;
      foundMatch = true;
    }
    if (!foundMatch) {
      char c = text.charAt(i);
      if ((c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9')) {
        tokens.add("" + c);
        i++;
        foundMatch = true;
      }
    }
    if (!foundMatch) {
      String oneChar = ("" + text.charAt(i)).toLowerCase();
      if (charImages.containsKey(oneChar) || oneChar.equals(" ") || oneChar.equals(".")) {
        tokens.add(oneChar);
        i++;
      } else {
        i++;
      }
    }
  }
  return tokens;
}

boolean isDoubleCharKey(String key) {
  for (String doubleChar : doubleCharKeys) {
    if (key.equals(doubleChar)) {
      return true;
    }
  }
  return false;
}

float getScaledWidth(String token) {
  float currentCharSize = charSize;
  if (displayMode == 1 || displayMode == 2 || displayMode == 3) {
    currentCharSize = (manualCircularCharSize > 0) ?
    manualCircularCharSize : charSize;
  } else if (displayMode == 4 || displayMode == 5 || displayMode == 6) {
    currentCharSize = (manualSquareCharSize > 0) ?
    manualSquareCharSize : charSize;
  }
  
  PImage img = getImageForToken(token);
  if (img != null) {
    if (img.height > 0) {
      float scaleFactor = (float) currentCharSize / img.height;
      if (!token.equals("space") && !token.equals("dot") && !isSingleOrDoubleChar(token)) {
        scaleFactor *= specialCharScaleFactor;
      }
      
    
      
      return img.width * scaleFactor;
    }
    return currentCharSize;
  } else {
    textSize(currentCharSize * latinScaleFactor);
    float textWidth = textWidth(token);
    return textWidth;
  }
}

boolean isSingleOrDoubleChar(String token) {
  if (token.length() == 1) {
    char c = token.charAt(0);
    return (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9');
  } else if (token.length() == 2) {
    return token.equals("ch") || token.equals("t2") ||
      token.equals("sh") || token.equals("s2");
  } else if (token.length() == 3) {
    return token.equals("ts2") || token.equals ("sch");
  }
  return false;
}

// NEW: separate function to draw circular elements
ArrayList<float[]> drawCircular(String text, float centerX, float centerY, PGraphics pg) {
  
  
if (text==""){
    text ="__";
}
  
  String[] words = text.split(" ");
  ArrayList<String> filteredWords = new ArrayList<String>();
  for (String word : words) {
    if (!word.isEmpty()) {
      filteredWords.add(word);
    }
  }
  
  float currentRadius = manualRadius > 0 ?
  manualRadius : 200;

  float totalWordWidth = 0;
  for (String word : filteredWords) {
    totalWordWidth += getWordWidth(word);
  }
  float totalSpacing = filteredWords.size() > 1 ? (filteredWords.size() - 1) * (charSize * 0.5) : 0;
  float circumference = totalWordWidth + totalSpacing;
  
  float radius;
  if (manualRadius > 0) {
    radius = manualRadius;
  } else {
    radius = circumference / (2 * PI);
  }
  radius = constrain(radius, charSize*0.6 , min(width, height) / 2 - charSize*0.6);

  lineThickness = radius * 0.02;
  spriteSize = radius * 0.05;
  
  float innerRadius = radius + innerCircleRadiusOffset;
  if (innerRadius < 0) innerRadius = 0;
  ArrayList<float[]> sigilPositions = new ArrayList<float[]>();
  float totalNumWords = filteredWords.size();
  
  for (int i = 0; i < totalNumWords; i++) {
    String word = filteredWords.get(i);
    ArrayList<String> tokens = parseText(word);
    float wordWidth = getWordWidth(word);
    float wordArcAngle = wordWidth / radius;
    float wordCenterAngle = map(i, 0, totalNumWords, -PI/2, -PI/2 + TWO_PI) + startAngleOffset;
    float currentAngle = wordCenterAngle - (wordArcAngle / 2);
    float sigilX = centerX + cos(wordCenterAngle) * innerRadius;
    float sigilY = centerY + sin(wordCenterAngle) * innerRadius;
    sigilPositions.add(new float[]{sigilX, sigilY});
    for (int j = 0; j < tokens.size(); j++) {
      String token = tokens.get(j);
      float tokenWidth = getScaledWidth(token);
      float tokenArcAngle = tokenWidth / radius;
      
      currentAngle += tokenArcAngle / 2;
      float x = centerX + cos(currentAngle) * radius;
      float y = centerY + sin(currentAngle) * radius;
      
      PImage img = getImageForToken(token);
      float currentCharSize = (manualCircularCharSize > 0) ? manualCircularCharSize : charSize;
      if (img != null) {
        float scaleFactor = (float) currentCharSize / img.height;
        if (!isSingleOrDoubleChar(token)) {
          scaleFactor *= specialCharScaleFactor;
        }
        float scaledWidth = img.width * scaleFactor;
        float scaledHeight = img.height * scaleFactor;
        float yOffset = (!isSingleOrDoubleChar(token)) ? specialCharBaselineOffset : 0;
        
        pg.pushMatrix();
        pg.translate(x, y);
        pg.rotate(currentAngle + PI / 2);
        pg.image(img, -scaledWidth / 2, -scaledHeight / 2 + yOffset, scaledWidth, scaledHeight);
        pg.popMatrix();
      } else {
        pg.textSize(currentCharSize * latinScaleFactor);
        pg.pushMatrix();
        pg.translate(x, y);
        pg.rotate(currentAngle + PI / 2);
        pg.fill(drawColor);
        pg.textAlign(CENTER, CENTER);
        pg.text(token, 0, latinBaselineOffset);
        pg.popMatrix();
      }
      currentAngle += tokenArcAngle / 2;
    }
  }
  
  pg.noFill();
  pg.stroke(drawColor);
  pg.strokeWeight(outerCircleThickness);
  pg.ellipse(centerX, centerY, (radius + outerCircleRadiusOffset) * 2, (radius + outerCircleRadiusOffset) * 2);
  pg.strokeWeight(innerCircleThickness);
  pg.ellipse(centerX, centerY, innerRadius * 2, innerRadius * 2);
  
  return sigilPositions;
}


// NEW: new function to get positions without drawing
ArrayList<float[]> getCircularPositions(String text, float centerX, float centerY, PGraphics pg) {
  
  if (text==""){
    text ="__";
  }
  
  String[] words = text.split(" ");
  ArrayList<String> filteredWords = new ArrayList<String>();
  for (String word : words) {
    if (!word.isEmpty()) {
      filteredWords.add(word);
    }
  }
  
  float currentRadius = manualRadius > 0 ?
  manualRadius : 200;

  float totalWordWidth = 0;
  for (String word : filteredWords) {
    totalWordWidth += getWordWidth(word);
  }
  float totalSpacing = filteredWords.size() > 1 ? (filteredWords.size() - 1) * (charSize * 0.5) : 0;
  float circumference = totalWordWidth + totalSpacing;
  
  float radius;
  if (manualRadius > 0) {
    radius = manualRadius;
  } else {
    radius = circumference / (2 * PI);
  }
  radius = constrain(radius, charSize*0.6 , min(width, height) / 2 - charSize*0.6);

  lineThickness = radius * 0.02;
  spriteSize = radius * 0.05;
  
  float innerRadius = radius + innerCircleRadiusOffset;
  if (innerRadius < 0) innerRadius = 0;
  ArrayList<float[]> sigilPositions = new ArrayList<float[]>();
  float totalNumWords = filteredWords.size();
  
  for (int i = 0; i < totalNumWords; i++) {
    String word = filteredWords.get(i);
    float wordWidth = getWordWidth(word);
    float wordArcAngle = wordWidth / radius;
    float wordCenterAngle = map(i, 0, totalNumWords, -PI/2, -PI/2 + TWO_PI) + startAngleOffset;
    float sigilX = centerX + cos(wordCenterAngle) * innerRadius;
    float sigilY = centerY + sin(wordCenterAngle) * innerRadius;
    sigilPositions.add(new float[]{sigilX, sigilY});
  }
  return sigilPositions;
}


// touchMoved
void touchMoved() {
  float topBuffer = height * 0.05;
  float bottomBuffer = height * 0.2;
  if (mouseY < topBuffer || mouseY > height - bottomBuffer) {
    return;
  }
  
  if (!inputActive && activeSigilIndex == -1) {
    if (displayMode == 1) {
      if (mouseX < width / 2) {
        float dy = mouseY - pmouseY;
        manualRadius -= dy * 0.5;
        manualRadius = constrain(manualRadius, charSize*0.6 , min(width, height) / 2 - charSize*0.6);
      } else {
        float dy = mouseY - pmouseY;
        startAngleOffset += dy * 0.001;
        startAngleOffset = constrain(startAngleOffset, -180, 180);
      }
    } else if (displayMode == 2) {
        float dy = mouseY - pmouseY;
        manualCircularCharSize -= dy * 0.1;
        manualCircularCharSize = constrain(manualCircularCharSize, 50, 250);
    } else if (displayMode == 5) {
        float dy = mouseY - pmouseY;
        manualSquareCharSize -= dy * 0.1;
        manualSquareCharSize = constrain(manualSquareCharSize, 50, 500);
    } else if (displayMode == 3 || displayMode == 6) {
      float dy = mouseY - pmouseY;
      if (mouseX < width / 2) {
        animationSpeed -= dy * 0.00001;
        animationSpeed = constrain(animationSpeed, 0.001, 0.1);
      } else {
        trailHardness += dy * 0.01;
        trailHardness = constrain(trailHardness, 1, 255);
      }
    } else if (displayMode == 4) {
      float dy = mouseY - pmouseY;
      if (mouseX < width / 2) {
        manualSquareSize -= dy * 0.5;
        manualSquareSize = constrain(manualSquareSize, min(width, height) / 4, min(width, height) * 0.8);
      }
    }
  }
}

PImage getImageForToken(String token) {
  if (token.length() == 1 && token.charAt(0) >= 'A' && token.charAt(0) <= 'Z') {
    return null;
  }
  if (token.length() == 1 && token.charAt(0) >= '0' && token.charAt(0) <= '9') {
    return null;
  }
  return charImages.get(token);
}

float getWordWidth(String word) {
  ArrayList<String> tokens = parseText(word);
  float width = 0;
  for (String token : tokens) {
    width += getScaledWidth(token);
  }
  return width;
}

// NEW: separate function to draw square elements
ArrayList<float[]> drawSquare(String text, float centerX, float centerY, int mode, PGraphics pg) {
  String[] words = text.split(" ");
  ArrayList<String> filteredWords = new ArrayList<String>();
  for (String word : words) {
    if (!word.isEmpty()) {
      filteredWords.add(word);
    }
  }
  
  int numWords = filteredWords.size();
  int n = 2;
  while (n * n < numWords) {
    n++;
  }
  
  float totalSize;
  if (manualSquareSize > 0) {
    totalSize = manualSquareSize;
  } else {
    float maxWidth = 0;
    for (String word : filteredWords) {
      float wordWidth = getWordWidth(word);
      if (wordWidth > maxWidth) {
        maxWidth = wordWidth;
      }
    }
    
    float cellPadding = 20;
    float squareCellSize = maxWidth + cellPadding;
    float spacing = 30;
    totalSize = n * squareCellSize + (n - 1) * spacing;
  }

  lineThickness = totalSize * 0.011;
  spriteSize=totalSize * 0.03;

  float startGridX = centerX - totalSize / 2;
  float startGridY = centerY - totalSize / 2;

  pg.stroke(drawColor);
  pg.strokeWeight(outerCircleThickness);
  pg.noFill();
  pg.rect(startGridX, startGridY, totalSize, totalSize);
  
  for (int i = 1; i < n; i++) {
    pg.line(startGridX, startGridY + i * (totalSize/n), startGridX + totalSize, startGridY + i * (totalSize/n));
    pg.line(startGridX + i * (totalSize/n), startGridY, startGridX + i * (totalSize/n), startGridY + totalSize);
  }

  ArrayList<float[]> allWordPositions = new ArrayList<float[]>();
  ArrayList<String> allTokens = new ArrayList<String>();
  
  float squareCellSize = totalSize / n;
  int wordIndex = 0;
  for (int row = 0; row < n; row++) {
    for (int col = 0; col < n; col++) {
      if (wordIndex < filteredWords.size()) {
        String word = filteredWords.get(wordIndex);
        ArrayList<String> tokens = parseText(word);
        float wordWidth = getWordWidth(word);
        
        float cellX = startGridX + col * (squareCellSize);
        float cellY = startGridY + row * (squareCellSize);
        float x = cellX + squareCellSize / 2 - wordWidth / 2;
        float y = cellY + squareCellSize / 2;
        
        allWordPositions.add(new float[]{cellX + squareCellSize / 2, cellY + squareCellSize / 2});
        for (String token : tokens) {
          allTokens.add(token);
          PImage img = getImageForToken(token);
          float currentCharSize = (manualSquareCharSize > 0) ? manualSquareCharSize : charSize;
          if (img != null) {
            float scaleFactor = (float) currentCharSize / img.height;
            if (!isSingleOrDoubleChar(token)) {
              scaleFactor *= specialCharScaleFactor;
            }
            float scaledWidth = img.width * scaleFactor;
            float scaledHeight = img.height * scaleFactor;
            float yOffset = (!isSingleOrDoubleChar(token)) ? specialCharBaselineOffset : 0;
            pg.image(img, x, y - scaledHeight/2 + yOffset, scaledWidth, scaledHeight);
            x += scaledWidth;
          } else if ((token.length() == 1 && token.charAt(0) >= 'A' && token.charAt(0) <= 'Z') || (token.length() == 1 && token.charAt(0) >= '0' && token.charAt(0) <= '9')) {
              pg.textSize(currentCharSize * latinScaleFactor);
              pg.fill(drawColor);
              pg.textAlign(LEFT, CENTER);
              float textWidth = pg.textWidth(token);
              float yOffset = latinBaselineOffset;
              pg.text(token, x, y + yOffset);
              x += textWidth;
              x += latinCharSpacing;
          }
        }
        wordIndex++;
      }
    }
  }
  return allWordPositions;
}


// NEW: new function to get positions without drawing
ArrayList<float[]> getSquarePositions(String text, float centerX, float centerY, int mode, PGraphics pg) {
  String[] words = text.split(" ");
  ArrayList<String> filteredWords = new ArrayList<String>();
  for (String word : words) {
    if (!word.isEmpty()) {
      filteredWords.add(word);
    }
  }
  
  int numWords = filteredWords.size();
  int n = 2;
  while (n * n < numWords) {
    n++;
  }
  
  float totalSize;
  if (manualSquareSize > 0) {
    totalSize = manualSquareSize;
  } else {
    float maxWidth = 0;
    for (String word : filteredWords) {
      float wordWidth = getWordWidth(word);
      if (wordWidth > maxWidth) {
        maxWidth = wordWidth;
      }
    }
    
    float cellPadding = 20;
    float squareCellSize = maxWidth + cellPadding;
    float spacing = 30;
    totalSize = n * squareCellSize + (n - 1) * spacing;
  }

  lineThickness = totalSize * 0.011;
  spriteSize=totalSize * 0.03;

  float startGridX = centerX - totalSize / 2;
  float startGridY = centerY - totalSize / 2;

  ArrayList<float[]> allWordPositions = new ArrayList<float[]>();
  
  float squareCellSize = totalSize / n;
  int wordIndex = 0;
  for (int row = 0; row < n; row++) {
    for (int col = 0; col < n; col++) {
      if (wordIndex < filteredWords.size()) {
        float cellX = startGridX + col * (squareCellSize);
        float cellY = startGridY + row * (squareCellSize);
        allWordPositions.add(new float[]{cellX + squareCellSize / 2, cellY + squareCellSize / 2});
        wordIndex++;
      }
    }
  }
  return allWordPositions;
}

// drawSigilLines
void drawSigilLines(ArrayList<float[]> matchedWordPositions, int mode, Sigil sigil, PGraphics pg) {
  String[] sigilWords = sigil.input.split(" ");
  ArrayList<float[]> matchedSigilPositions = new ArrayList<float[]>();
  
  String[] mainWords = new String[0];
  if (mode == 1 || mode == 2 || mode == 3) {
      mainWords = inputText.split(" ");
  } else if (mode == 4 || mode == 5 || mode == 6) {
      mainWords = inputText.split(" ");
  }

  for (String sWord : sigilWords) {
    boolean found = false;
    for (int j = 0; j < mainWords.length; j++) {
      String mainWord = mainWords[j];
      if (mainWord.equals(sWord)) {
        if (j < matchedWordPositions.size()) {
           matchedSigilPositions.add(matchedWordPositions.get(j));
           found = true;
        }
        break;
      }
    }
  }

  if (matchedSigilPositions.size() > 1) {
    if (mode == 3 || mode == 6) {
      sigil.progress += animationSpeed;
      if (sigil.progress > 1.0) {
        sigil.progress = 0;
        sigil.firstDraw = true;
      }
      
      float totalDistance = 0;
      float[] distances = new float[matchedSigilPositions.size() - 1];
      for (int k = 0; k < matchedSigilPositions.size() - 1; k++) {
        float[] p1 = matchedSigilPositions.get(k);
        float[] p2 = matchedSigilPositions.get(k + 1);
        distances[k] = dist(p1[0], p1[1], p2[0], p2[1]);
        totalDistance += distances[k];
      }
      
      float currentDistance = sigil.progress * totalDistance;
      float progressOnSegment = 0;
      
      int currentSegment = 0;
      for (int k = 0; k < distances.length; k++) {
        if (currentDistance <= distances[k]) {
          currentSegment = k;
          progressOnSegment = currentDistance / distances[k];
          break;
        }
        currentDistance -= distances[k];
      }
      
      float[] startPoint = matchedSigilPositions.get(currentSegment);
      float[] endPoint = matchedSigilPositions.get(currentSegment + 1);
      
      float animatedX = lerp(startPoint[0], endPoint[0], progressOnSegment);
      float animatedY = lerp(startPoint[1], endPoint[1], progressOnSegment);
      if (sigil.firstDraw) {
        float[] firstPos = matchedSigilPositions.get(0);
        sigil.prevPointX = firstPos[0];
        sigil.prevPointY = firstPos[1];
        sigil.firstDraw = false;
      }
      
      pg.stroke(sigil.c);
      pg.strokeWeight(spriteSize);
      pg.line(sigil.prevPointX, sigil.prevPointY, animatedX, animatedY);
      
      sigil.prevPointX = animatedX;
      sigil.prevPointY = animatedY;
      
      pg.fill(sigil.c);
      pg.noStroke();
      pg.ellipse(animatedX, animatedY, spriteSize, spriteSize);
    } else {
      pg.stroke(sigil.c);
      pg.strokeWeight(lineThickness);
      for (int k = 0; k < matchedSigilPositions.size() - 1; k++) {
        float[] p1 = matchedSigilPositions.get(k);
        float[] p2 = matchedSigilPositions.get(k + 1);
        pg.line(p1[0], p1[1], p2[0], p2[1]);
      }
      
      if (matchedSigilPositions.size() > 0) {
        float[] startPoint = matchedSigilPositions.get(0);
        pg.noFill();
        pg.ellipse(startPoint[0], startPoint[1], lineThickness*3, lineThickness*3);
        
        float[] endPoint = matchedSigilPositions.get(matchedSigilPositions.size() - 1);
        if (matchedSigilPositions.size() > 1) {
            float[] prevPoint = matchedSigilPositions.get(matchedSigilPositions.size() - 2);
            float dx = endPoint[0] - prevPoint[0];
            float dy = endPoint[1] - prevPoint[1];
            float angleEnd = atan2(dy, dx) + PI/2;
            float barLength = lineThickness*3;
            pg.line(endPoint[0] - cos(angleEnd) * (barLength / 2), endPoint[1] - sin(angleEnd) * (barLength / 2),
                 endPoint[0] + cos(angleEnd) * (barLength / 2), endPoint[1] + sin(angleEnd) * (barLength / 2));
        }
      }
    }
  }
}
