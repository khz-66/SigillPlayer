import java.util.HashMap;
import java.util.ArrayList;
import processing.core.PImage;
import processing.core.PFont;
import processing.core.PGraphics;
import android.content.Context;
import android.view.inputmethod.InputMethodManager;
import android.view.WindowManager;
import android.content.Intent;
import android.net.Uri;
import java.io.InputStream;

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
int maxTextLength = 60;
boolean inputActive = false;
int activeSigilIndex = -1;
boolean uiActive=true;
PFont font;

PGraphics displayGraphics;
PGraphics sigilTrail;

// --- Hintergrundbild Variablen ---
PImage bgImage = null;
float bgScale = 1.0;
boolean isSelectingImage = false;
float finalWidth=width;
float finalHeight=height;

int bgAlpha=255;
int bgBrightness=255;

// --- Exportgröße Variablen  ---
  int minX = 0;
  int maxX = width;
  int minY = 0;
  int maxY = height;

// --- Export Variablen  ---
String lastPath = "";
String exportMessage = "";
boolean showMessage = false;
int messageTimer = 0;
int lastExportTime = 0; // Merkt sich den Zeitpunkt des letzten Exports



// Class to hold sigil data
class Sigil {
  String input = "";
  color c;
  float progress = 0;
  float prevPointX = 0;
  float prevPointY = 0;
  boolean firstDraw = true;
  
  ArrayList<float[]> trailHistory = new ArrayList<float[]>();
}

ArrayList<Sigil> sigils = new ArrayList<Sigil>();
String[] doubleCharKeys = {"ch", "sh", "s2", "t2", "sch"};
float outerCircleRadiusOffset = 50;
float innerCircleRadiusOffset = -50;
float outerCircleThickness = 2;
float innerCircleThickness = 2;

float manualRadius = 250;
float manualSquareSize = 500;
float manualCircularCharSize = 150;
float manualSquareCharSize = 150;
color[] colorPalette;
float startAngleOffset = 0;
float animationSpeed = 0.01;
float trailHardness = 50;
float spriteSize=lineThickness*2;

void onPause() {
  super.onPause();
  saveSettings();
}

int bgColor=0;
int drawColor=200;
float boxXbgBlack;
float boxXbgWhite;
float boxYbg;

long touchStartTime = 0;
boolean isDrawingBackground = true;
float touchStartX, touchStartY;

//==================================
// instructions
//==================================

boolean showInstructions=true;
int count=0;

String[] explanation1 = {
      "+/- : Neues Sigill / Sigill löschen.",
      "Lange drücken: Bild laden/löschen.",
      "Wischen vertikal links: Größe.",
      "Wischen vertikal mitte: Bildgröße.",
      "Wischen vertikal rechts: Winkel.",
      "Doppeltipp: Nächste Seite."
};
 
String[] explanation25 = {
      "Lange drücken: Hintergrund ausblenden.",
      "Wischen vertikal links: Schriftgröße.",
      "Wischen vertikal rechts: Sigill exportieren.",
      "Doppeltipp: Nächste Seite."
};
 
String[] explanation36 = {
      "Lange drücken: Hintergrund Ausblenden.",
      "Wischen vertikal links: Geschwindigkeit.",
      "Wischen vertikal rechts: Spurlänge.",
      "Doppeltipp: Nächste Seite."
};
 
String[] explanation4 = {
      "Planetenquadrate:",
      "*saturn *jupiter *mars *sonne",
      "*venus *merkur *mond",
      " ",
      "+/- : Neues Sigill / Sigill löschen.",
      "Lange drücken: Bild laden/löschen.",
      "Wischen vertikal links: Größe.",
      "Doppeltipp: Nächste Seite."
};



void saveSettings() {
  // Der sicherste gemeinsame Ordner für Scoped Storage unter Android:
  // /sdcard/Android/media/dein.paket.name/
  // APDE nutzt standardmäßig den Paketnamen der Skizze.
  // "this.getPackageName()" holt diesen dynamisch!
  File dir = new File(
    android.os.Environment.getExternalStorageDirectory(),
    "Android/media/" + getActivity().getPackageName() + "/Sigill"
  );
  
  if (!dir.exists()) dir.mkdirs();

  // Array-Größe angepasst: 21 Standardelemente + dynamische Sigillen
  String[] settings = new String[21 + sigils.size() * 2]; 
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
  settings[18] = str(isDrawingBackground);
  settings[19] = str(bgColor); 
  
  // Bild-Manipulations-Werte an festen Indizes sichern
  settings[20] = str(bgScale);
  

  // Sigillen-Schleife startet bei Index 21
  int index = 21;
  for (Sigil s : sigils) {
    settings[index++] = s.input;
    settings[index++] = str(s.c);
  }
  
  // In den sicheren gemeinsamen Ordner speichern
  File settingsFile = new File(dir, "settings.dat");
  saveStrings(settingsFile.getAbsolutePath(), settings);
  println("Datei gespeichert unter: " + settingsFile.getAbsolutePath());
  
  // ANDROID-SPECIFIC: Bild nativ im gemeinsamen Ordner speichern
  File imageFile = new File(dir, "background.png");
  
  if (bgImage != null && bgImage.width > 0) {
    java.io.FileOutputStream fos = null;
    try {
      fos = new java.io.FileOutputStream(imageFile);
      android.graphics.Bitmap bmp = (android.graphics.Bitmap) bgImage.getNative();
      if (bmp != null) {
        bmp.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, fos);
        println("Hintergrundbild erfolgreich gespeichert.");
      }
    } catch (Exception e) {
      println("Fehler beim nativen Speichern des Bildes: " + e.getMessage());
    } finally {
      if (fos != null) {
        try { fos.close(); } catch (Exception ex) {}
      }
    }
  } else {
    if (imageFile.exists()) {
      imageFile.delete();
    }
  }
}




void loadSettings() {
  File dir = new File(
    android.os.Environment.getExternalStorageDirectory(),
    "Android/media/" + getActivity().getPackageName() + "/Sigill"
  );
  
  File settingsFile = new File(dir, "settings.dat");
  if (!settingsFile.exists()) {
    println("Keine Einstellungsdatei gefunden, nutze Defaults.");
    sigils.clear();
    Sigil defaultSigil = new Sigil();
    defaultSigil.c = (bgColor == 255) ? color(0) : color(255); 
    sigils.add(defaultSigil);
    return;
  }

  String[] settings = loadStrings(settingsFile.getAbsolutePath());
  if (settings != null) {
    try {
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
      isDrawingBackground = boolean(settings[18]);
      
      if (settings.length > 19) {
        bgColor = int(settings[19]);
        drawColor = (bgColor == 255) ? 0 : 200;
      }
      
      // Bild-Manipulations-Werte laden (mit Sicherheits-Fallback)
      if (settings.length > 22) {
        bgScale = float(settings[20]);
        
      } else {
        bgScale = 1.0;
        bgAlpha = 255;
        bgBrightness = 255;
      }

      // Sigillen-Schleife liest ab Index 21
      int index = 21;
      for (int i = 0; i < numSigils; i++) {
        Sigil s = new Sigil();
        s.input = settings[index++];
        s.c = color(int(settings[index++]));
        sigils.add(s);
      }
      
      // ANDROID-SPECIFIC: Bild nativ laden
      File imageFile = new File(dir, "background.png");
      if (imageFile.exists()) {
        android.graphics.Bitmap bmp = android.graphics.BitmapFactory.decodeFile(imageFile.getAbsolutePath());
        if (bmp != null) {
          bgImage = new PImage(bmp);
          println("Hintergrundbild erfolgreich geladen.");
        }
      }
      
      println("Settings geladen.");
    } catch (Exception e) {
      println("Fehler beim Parsen der Einstellungsdatei: " + e.getMessage());
      if (sigils.size() == 0) {
        Sigil defaultSigil = new Sigil();
        defaultSigil.c = (bgColor == 255) ? color(0) : color(255);
        sigils.add(defaultSigil);
      }
    }
  }
}


//==================================
// setup
//==================================

void setup() {
  fullScreen();
  background(bgColor);
  font = createFont("Droid Serif", charSize);
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
  loadSettings();
  displayGraphics = createGraphics(width, height);
sigilTrail = createGraphics(width, height); // NEU
  sigilTrail.beginDraw();
  sigilTrail.background(0, 0); // Startet vollkommen transparent
  sigilTrail.endDraw();

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
      
      if (bgColor == 0) {
        filename = filename.replace(".png", "_inverted.png");
      }
      
      PImage img = loadImage(filename);
      if (img != null) {
        charImages.put(key, img);
        if (description != null) {
          charDescriptions.put(key, description);
        }
      }
    }
  }
}



void reloadCharImages() {
  String[] lines = loadStrings("malachim.txt");
  if (lines == null || lines.length == 0) return;

  for (int i = 0; i < lines.length; i++) {
    String line = lines[i].trim();
    if (line.isEmpty() || line.startsWith("//") || line.startsWith("*")) continue;

    String[] parts = split(line, ' ');
    if (parts.length >= 2) {
      String key = parts[0];
      String filename = parts[1];
      if (bgColor == 0) {
        filename = filename.replace(".png", "_inverted.png");
      }

      PImage img = loadImage(filename);
      if (img != null) {
        charImages.put(key, img);
      }
    }
  }
}

//==================================
// draw
//==================================

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

      displayGraphics.beginDraw();
  
  // 1. HINTERGRUND REFRESH (Bleibt exakt wie zuvor – löscht alte Spuren)
  if (displayMode == 3 || displayMode == 6) {
    if (bgImage != null) {
      displayGraphics.fill(bgColor, trailHardness);
      displayGraphics.noStroke();
      displayGraphics.rect(0, 0, width, height);
    } else {
      displayGraphics.fill(bgColor, trailHardness);
      displayGraphics.noStroke();
      displayGraphics.rect(0, 0, width, height);
    }
  } else {
    // In allen statischen Modi leeren wir den Hintergrund komplett mit der Farbe
    displayGraphics.background(bgColor);
  }
  
  // 2. HINTERGRUNDBILD ZEICHNEN (Jetzt komplett unabhängig vom Ausblenden)
  if (bgImage != null) {
    
    // Wendet deine Einstellungen (Skalierung, Helligkeit, Alpha) in jedem Modus an
    
    // Die Bedingung "if (isDrawingBackground)" wurde hier entfernt.
    // Das Bild wird nun immer gezeichnet, wenn es geladen ist.
    displayGraphics.pushMatrix();
    displayGraphics.translate(width / 2, height / 2);
    displayGraphics.imageMode(CENTER);
    
    float imgRatio = (float)bgImage.width / bgImage.height;
    float screenRatio = (float)width / height;
    float baseScale = 1.0;
    
    if (imgRatio > screenRatio) {
      baseScale = (float)width / bgImage.width;
    } else {
      baseScale = (float)height / bgImage.height;
    }
    
    float finalWidth = bgImage.width * baseScale * bgScale;
    float finalHeight = bgImage.height * baseScale * bgScale;
   
    displayGraphics.image(bgImage, 0, 0, finalWidth, finalHeight);
    displayGraphics.popMatrix();
    displayGraphics.imageMode(CORNER);
    
  }


  
  // 3. SCHRIFTZEICHEN ZEICHNEN
  String cleanedText = inputText;
  ArrayList<float[]> sigilPositions = null;
  if (isDrawingBackground) {
      if (displayMode == 1 || displayMode == 2 || displayMode == 3) {
          sigilPositions = drawCircular(cleanedText, width/2, height/2, displayGraphics);
      } else if (displayMode == 4 || displayMode == 5 || displayMode == 6) {
          sigilPositions = drawSquare(cleanedText, width/2, height/2, displayMode, displayGraphics);
      }
  } else {
      if (displayMode == 1 || displayMode == 2 || displayMode == 3) {
          sigilPositions = getCircularPositions(cleanedText, width/2, height/2, displayGraphics);
      } else if (displayMode == 4 || displayMode == 5 || displayMode == 6) {
          sigilPositions = getSquarePositions(cleanedText, width/2, height/2, displayMode, displayGraphics);
      }
  }
  
  // 4. ANIMIERTE ODER STATISCHE SIGILLEN-LINIEN ZEICHNEN
  if (sigilPositions != null) {
      for (Sigil s : sigils) {
          if (!s.input.isEmpty()) {
              drawSigilLines(sigilPositions, displayMode, s, displayGraphics);
          }
      }
  }
 
  // 5. INTERFACE & TEXTE
  if (uiActive) {
    drawUI(displayGraphics);
  }
  
  if (showInstructions) {
    drawInstructions(displayGraphics);
  }
  
    
  // ==========================================
  // EXPORT MESSAGE OVERLAY (Einfache Zentrierung)
  // ==========================================
  if (showMessage) {
    displayGraphics.pushStyle();
    
    // Hintergrund-Rechteck zeichnen
    displayGraphics.fill(0, 180);
    displayGraphics.rectMode(CENTER);
    displayGraphics.noStroke();
    displayGraphics.rect(width/2, height/2, width * 0.8, height * 0.18);

    // Text-Einstellungen
    displayGraphics.fill(255);
    displayGraphics.textSize(min(width, height) * 0.035);
    
    // WICHTIG: Wenn wir nur einen X/Y-Punkt angeben, sorgt diese Zeile 
    // für eine absolut fehlerfreie vertikale und horizontale Zentrierung!
    displayGraphics.textAlign(CENTER, CENTER);
    
    // Wir zeichnen den Text genau auf den Mittelpunkt des Bildschirms.
    // Processing kümmert sich von alleine um den Zeilenumbruch an dem "\n".
    displayGraphics.text(exportMessage, width/2, height/2);
    
    displayGraphics.popStyle();
  }

  


  displayGraphics.endDraw();
  image(displayGraphics, 0, 0);
} // <--- Hier fehlte die schließende Klammer für void draw()


void resetImageSettings() {
  bgScale = 1.0;
  bgAlpha = 255;
  bgBrightness = 255;
}



//==================================
// draw ui
//==================================
void drawUI(PGraphics pg) {
// ... ab hier geht es normal weiter mit deinem Code

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
    
    pg.fill(200); 
    pg.textAlign(LEFT, CENTER);
    pg.text(inputText, inputX + 5, inputY1 + inputHeight/2);
    
    float sigilInputY = height * 0.15;
    float boxSize = min(width, height) * 0.06;
    
    if (!inputActive && activeSigilIndex == -1) {
        float startXbg = width - boxSize * colorPalette.length - ((colorPalette.length - 1) * 10) - width * 0.02;
        float startYbg = inputY1;
        boxXbgBlack = startXbg + (boxSize + 10) * 1;
        boxXbgWhite = startXbg + (boxSize + 10) * 0;
        boxYbg = startYbg;
            
        pg.fill(0);
        pg.stroke(200);
        pg.rect(boxXbgBlack, boxYbg, boxSize, boxSize);
         
        pg.fill(255);
        pg.rect(boxXbgWhite, boxYbg, boxSize, boxSize);
    }

    for (int i = 0; i < sigils.size(); i++) {
        Sigil s = sigils.get(i);
        pg.fill(i == activeSigilIndex ? 100 : 50);
        pg.stroke(drawColor);
        pg.rect(inputX, sigilInputY + i * (inputHeight + 10), inputWidth, inputHeight);
        
        pg.fill(200);
        pg.textAlign(LEFT, CENTER);
        pg.text(s.input, inputX + 5, sigilInputY + i * (inputHeight + 10) + inputHeight/2);
        if (!inputActive && activeSigilIndex == -1) {
            float startX = width - boxSize * colorPalette.length - ((colorPalette.length - 1) * 10) - width * 0.02;
            float startY = sigilInputY + i * (inputHeight + 10);
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

//==================================
// draw instructions
//==================================

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
        if (count <= 30) {
            count++;
            showInstructions = true;
        } 
        for (int i = 0; i < explanation25.length; i++) {
            pg.text(explanation25[i], width / 2, textY - (explanation25.length - 1 - i) * lineHeight);
        }
        if (count == 31) {
          deleteInstructions();
        }
    } else if (displayMode == 3 || displayMode == 6) {
        showInstructions = false;
        if (count <= 150) {
            count++;
            showInstructions = true;
        }
        for (int i = 0; i < explanation36.length; i++) {
            pg.text(explanation36[i], width / 2, textY - (explanation36.length - 1 - i) * lineHeight);
        }
        if (count == 151) {
          deleteInstructions();
        }
    } else if (displayMode == 4) {
        for (int i = 0; i < explanation4.length; i++) {
            pg.text(explanation4[i], width / 2, textY - (explanation4.length - 1 - i) * lineHeight);
        }
    }
    
    pg.popStyle();
}

void deleteInstructions(){
        displayGraphics.fill(bgColor, 255);
        displayGraphics.noStroke();
        displayGraphics.rect(0, height, width, -height/4);
}


//==================================
// key pressed
//==================================

void keyPressed() {
  boolean active = inputActive || activeSigilIndex != -1;
  if (!active) return;
  
  String activeInput = "";
  if (inputActive) {
    activeInput = inputText;
  } else {
    activeInput = sigils.get(activeSigilIndex).input;
  }
  
  if ((key >= 'a' && key <= 'z') || (key >= 'A' && key <= 'Z') || (key >= '0' && key <= '9') || key == '_' || key == ' ' || key == '.' || key == '*' || key == '/') {
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

//==================================
// touch started
//==================================

void touchStarted() {
  
   // NEU: Wenn die Export-Meldung offen ist, schließe sie und tu sonst nichts
  if (showMessage) {
    showMessage = false;
    return; // Beendet touchStarted() sofort, damit kein UI-Element darunter getriggert wird
  }

  
  touchStartTime = millis();
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
    boolean openedKeyboard = false;
    
    for (int i = 0; i < sigils.size(); i++) {
        float fieldY = sigilInputY + i * (inputHeight + 10);
        if (mouseX > inputX && mouseX < inputX + inputWidth && mouseY > fieldY && mouseY < fieldY + inputHeight) {
          activeSigilIndex = i;
          touchedSomething = true;
          openedKeyboard = true;
          try {
            InputMethodManager imm = (InputMethodManager) getActivity().getSystemService(Context.INPUT_METHOD_SERVICE);
            imm.toggleSoftInput(InputMethodManager.SHOW_FORCED, 0);
          } catch (Exception e) {}
          break;
        }
        
        if (!inputActive && activeSigilIndex == -1) {
            if (mouseY > boxYbg && mouseY < boxYbg + boxSize) {
              if (mouseX > boxXbgBlack && mouseX < boxXbgBlack + boxSize) {
                if (bgColor != 0) {
                  bgColor = 0;
                  drawColor = 200;
                  touchedSomething = true;
                  for (Sigil s : sigils) {
                    if (s.c == color(0)) {
                      s.c = color(255);
                    }
                  }
                  reloadCharImages();
                }  
                break;
              }
              else if (mouseX > boxXbgWhite && mouseX < boxXbgWhite + boxSize) {
                if (bgColor != 255) {
                  bgColor = 255;
                  drawColor = 0;
                  touchedSomething = true;
                  
                  for (Sigil s : sigils) {
                    if (s.c == color(255)) {
                      s.c = color(0);
                    }
                  }
                  reloadCharImages();
                }
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

    float buttonSize = min(width, height) * 0.05;
    float buttonX = inputX;
    float buttonY = sigilInputY + sigils.size() * (inputHeight + 10);
    float removeButtonX = buttonX + buttonSize + 10;
    if (mouseX > buttonX && mouseX < buttonX + buttonSize && mouseY > buttonY && mouseY < buttonY + buttonSize) {
        Sigil newSigil = new Sigil();
        newSigil.c = (bgColor == 255) ? color(0) : color(255); 
        sigils.add(newSigil);
        touchedSomething = true;
    } else if (mouseX > removeButtonX && mouseX < removeButtonX + buttonSize && mouseY > buttonY && mouseY < buttonY + buttonSize) {
        if (sigils.size() > 1) {
            sigils.remove(sigils.size() - 1);
            if (activeSigilIndex >= sigils.size()) {
                activeSigilIndex = -1;
            }
        }
        touchedSomething = true;
    }
    
    if (touchedSomething && !openedKeyboard) {
      try {
        InputMethodManager imm = (InputMethodManager) getActivity().getSystemService(Context.INPUT_METHOD_SERVICE);
        if (getActivity().getCurrentFocus() != null) {
            imm.hideSoftInputFromWindow(getActivity().getCurrentFocus().getWindowToken(), 0);
        }
      } catch (Exception e) {}
    }
  }
}


//==================================
// mouseDragged, touch moved: streichen
//==================================

void mouseDragged() {
  // Wir prüfen zuerst, ob überhaupt ein Bild geladen ist
  if (bgImage == null) return;

  // Der vertikale Streich-Wert (Delta)
  float dy = pmouseY - mouseY; 

  switch (displayMode) {
    case 1:
    case 4:
      // Modus 1 & 4: Bildskalierung in der Mitte (40% - 60% Breite)
      if (mouseX > 0.4 * width && mouseX < 0.6 * width) {
        bgScale += dy * 0.005; // Etwas feinfühliger als 0.001, je nach Bedarf anpassen
        bgScale = constrain(bgScale, 0.1, 5.0);
      }
      break;

    case 2:
    case 5:
      // speichern bzw. export
      if (mouseX > 0.4 * width && mouseX < 0.6 * width) {
        // speichern bzw. export
      }
      break;

    case 3:
    case 6:
      // speichern bzw. export
      if (mouseX > 0.4 * width && mouseX < 0.6 * width) {
        // speichern bzw. export
      }
      break;
  }
}


void touchMoved() {
  float topBuffer = height * 0.05;
  float bottomBuffer = height * 0.2;
  if (mouseY < topBuffer || mouseY > height - bottomBuffer) {
    return;
  }
  
  if (!inputActive && activeSigilIndex == -1) {
    if (displayMode == 1) {
      if (mouseX < 0.3*width) {
        float dy = mouseY - pmouseY;
        manualRadius -= dy * 0.5;
        manualRadius = constrain(manualRadius, charSize*0.6 , min(width, height) / 2 - charSize*0.6);
      } else if (mouseX > 0.7*width) {
        float dy = mouseY - pmouseY;
        startAngleOffset += dy * 0.001;
        startAngleOffset = constrain(startAngleOffset, -180, 180);
      }
    } else if (displayMode == 2) {
        if (mouseX <= 0.3*width) {
          float dy = mouseY - pmouseY;
          manualCircularCharSize -= dy * 0.1;
          manualCircularCharSize = constrain(manualCircularCharSize, 50, 250);
        } else if (mouseX >= 0.7*width){
          if (millis() - lastExportTime > 2000) { 
            lastExportTime = millis(); // Zeitstempel aktualisieren
            exportClean();
          }
        }
    } else if (displayMode == 5) {
        if (mouseX <= 0.3*width) {
          float dy = mouseY - pmouseY;
          manualSquareCharSize -= dy * 0.1;
          manualSquareCharSize = constrain(manualSquareCharSize, 50, 500);
        } else if (mouseX >= 0.7*width){
          if (millis() - lastExportTime > 2000) { 
            lastExportTime = millis(); // Zeitstempel aktualisieren
            exportClean();
          }
        }
    } else if (displayMode == 3 || displayMode == 6) {
      float dy = mouseY - pmouseY;
      if (mouseX < 0.3*width) {
        animationSpeed -= dy * 0.00001;
        animationSpeed = constrain(animationSpeed, 0.001, 0.1);
      } else if (mouseX > 0.7*width) {
        trailHardness += dy * 0.01;
        trailHardness = constrain(trailHardness, 1, 255);
      }
    } else if (displayMode == 4) {
      float dy = mouseY - pmouseY;
      if (mouseX < 0.3*width) {
        manualSquareSize -= dy * 0.5;
        manualSquareSize = constrain(manualSquareSize, min(width, height) / 4, min(width, height) * 0.8);
      }
    }
  }
}


//==================================
// lang drücken: touchEnded
//==================================

void touchEnded() {
  
 
  
    long pressDuration = millis() - touchStartTime;
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
    
    float moveDistance = dist(touchStartX, touchStartY, mouseX, mouseY);
    if (!touchedUI) {
        if (pressDuration > 500 && moveDistance < 10) {
            if (displayMode == 1 || displayMode == 4) {
                if (bgImage == null) {
                    if (!isSelectingImage) {
                        openFilePicker();
                    }
                } else {
                    bgImage = null;
                    println("Bild gelöscht.");
                }
            } else {
                isDrawingBackground = !isDrawingBackground;
                if (isDrawingBackground == false){
                  displayGraphics.fill(0, 255);
                  displayGraphics.noStroke();
                  displayGraphics.rect(0, 0, width, height);
                }
            }
        }
    }
    
    
}

//==================================
// bild laden
//==================================

// --- Android File Picker Methoden ---
void openFilePicker() {
  if (getActivity() == null) return;
  isSelectingImage = true;
  getActivity().runOnUiThread(new Runnable() {
    @Override
    public void run() {
      Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
      intent.setType("image/*");
      getActivity().startActivityForResult(Intent.createChooser(intent, "Hintergrundbild wählen"), 999);
    }
  });
}

@Override
void onActivityResult(int requestCode, int resultCode, Intent data) {
  super.onActivityResult(requestCode, resultCode, data);
  isSelectingImage = false;
  if (requestCode == 999 && resultCode == android.app.Activity.RESULT_OK && data != null) {
    Uri uri = data.getData();
    if (uri != null && getActivity() != null) {
      try {
        InputStream inputStream = getActivity().getContentResolver().openInputStream(uri);
        byte[] bytes = loadBytes(inputStream);
        
        // 1. Dekodiere das Bild zuerst als natives Android-Bitmap
        android.graphics.Bitmap loadedBitmap = android.graphics.BitmapFactory.decodeByteArray(bytes, 0, bytes.length);
        
        if (loadedBitmap != null && loadedBitmap.getWidth() > 0) {
          // 2. Weise es deiner Processing PImage-Variable zu
          bgImage = new PImage(loadedBitmap);
          resetImageSettings();
          
          // 3. 
           saveSettings(); 
          
          // 4. BILD DIREKT UND SICHER SPEICHERN
          File internalDir = getActivity().getFilesDir();
          File imageFile = new File(internalDir, "background.png");
          java.io.FileOutputStream fos = new java.io.FileOutputStream(imageFile);
          try {
            loadedBitmap.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, fos);
            println("Bild nach Auswahl sofort sicher gespeichert.");
          } finally {
            fos.close();
          }
          
          println("Bild erfolgreich geladen und angezeigt: " + bgImage.width + "x" + bgImage.height);
        }
      } catch (Exception e) {
        println("Fehler beim Laden oder sofortigen Speichern des Bildes: " + e.getMessage());
      }
    }
  }
}

//==================================
// doppeltipp: mousePressed
//==================================

void mousePressed() {
  
  // NEU: Verhindert Modus-Wechsel, wenn die Meldung gerade geschlossen wurde
  if (!showMessage && millis() - messageTimer < 100) { 
    // Ein kleiner Puffer, da touchStarted die Variable showMessage kurz vor mousePressed auf false setzt
    return;
  }
  if (showMessage) {
    showMessage = false;
    return;
  }
  
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
    
    float buttonSize = min(width, height) * 0.05;
    float buttonX = inputX;
    float buttonY = sigilInputY + sigils.size() * (inputHeight + 10);
    float removeButtonX = buttonX + buttonSize + 10;

    boolean touchedButton = (mouseX > buttonX && mouseX < buttonX + buttonSize && mouseY > buttonY && mouseY < buttonY + buttonSize) ||
                            (mouseX > removeButtonX && mouseX < removeButtonX + buttonSize && mouseY > buttonY && mouseY < buttonY + buttonSize);
      
// moduswechsel      
                            
    if (!touchedInputFields && !colorPaletteTouched && !touchedButton) {
      
     clearAllSigilBuffers();
     deleteInstructions();
      
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
    currentCharSize = (manualCircularCharSize > 0) ? manualCircularCharSize : charSize;
  } else if (displayMode == 4 || displayMode == 5 || displayMode == 6) {
    currentCharSize = (manualSquareCharSize > 0) ? manualSquareCharSize : charSize;
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
    return token.equals("ch") || token.equals("t2") || token.equals("sh") || token.equals("s2");
  } else if (token.length() == 3) {
    return token.equals("ts2") || token.equals("sch");
  }
  return false;
}

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
    float wordCenterAngle = map(i, 0, totalNumWords, -PI/2, -PI/2 + TWO_PI) + startAngleOffset;
    float sigilX = centerX + cos(wordCenterAngle) * innerRadius;
    float sigilY = centerY + sin(wordCenterAngle) * innerRadius;
    sigilPositions.add(new float[]{sigilX, sigilY});
  }
  return sigilPositions;
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

//-----------
// Hilfsfunktion Spur löschen bei Moduswechsel
//-----

void clearAllSigilBuffers() {
  // 1. Hauptgrafik sofort leeren, damit im nächsten Frame nichts Altes durchscheint
  displayGraphics.beginDraw();
  displayGraphics.background(bgColor);
  displayGraphics.endDraw();
  
  // 2. Den Animations-Trail-Buffer ebenfalls komplett leeren (wichtig für Mode 3 & 6)
  if (sigilTrail != null) {
    sigilTrail.beginDraw();
    sigilTrail.clear(); // Setzt alle Pixel auf transparent (0, 0)
    sigilTrail.endDraw();
  }
  
  // 3. Den Zustand und die gezeichnete Historie JEDES Sigills zurücksetzen
  for (Sigil s : sigils) {
    s.progress = 0;
    s.firstDraw = true;
    s.prevPointX = 0;
    s.prevPointY = 0;
    s.trailHistory.clear(); // Löscht die alten Linien-Punkte restlos
  }
}


//==================================
// drawSigillLines
//==================================

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
      pg.blendMode(REPLACE); 
      sigil.progress += animationSpeed;
      if (sigil.progress > 1.0) {
        sigil.progress = 0;
        sigil.firstDraw = true;
        // sigil.trailHistory.clear();
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
        // sigil.trailHistory.clear();
        sigil.trailHistory.add(new float[]{firstPos[0], firstPos[1]});
        sigil.firstDraw = false;
      }
      
      
      
      
      
      sigil.prevPointX = animatedX;
      sigil.prevPointY = animatedY;
      if (sigil.trailHistory.isEmpty() || dist(animatedX, animatedY, sigil.trailHistory.get(sigil.trailHistory.size()-1)[0], sigil.trailHistory.get(sigil.trailHistory.size()-1)[1]) > 2) {
        sigil.trailHistory.add(new float[]{animatedX, animatedY});
      }
      while (sigil.trailHistory.size() > map(trailHardness, 1, 255, 255, 1)) sigil.trailHistory.remove(0);
      drawTrail(sigil, pg);
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

//==================================
// abmessungen grafik berechnen
//==================================

void berechneGrafikGroesse() {
  // WICHTIG: Setze die Werte vor jeder Berechnung auf die Extrempunkte zurück!
  minX = width;
  maxX = 0;
  minY = height;
  maxY = 0;

  // 1. KOMPONENTE: HINTERGRUNDBILD
  if (bgImage != null && (isDrawingBackground || (displayMode != 3 && displayMode != 6))) {
    // Hier nutzen wir die gleichen Variablen wie beim Zeichnen in draw()
    float imgRatio = (float)bgImage.width / bgImage.height;
    float screenRatio = (float)width / height;
    float baseScale = (imgRatio > screenRatio) ? (float)width / bgImage.width : (float)height / bgImage.height;
    
    float fWidth = bgImage.width * baseScale * bgScale;
    float fHeight = bgImage.height * baseScale * bgScale;

    int bgMinX = (int)((width  / 2) - (fWidth  / 2));
    int bgMaxX = (int)((width  / 2) + (fWidth  / 2));
    int bgMinY = (int)((height / 2) - (fHeight / 2));
    int bgMaxY = (int)((height / 2) + (fHeight / 2));

    minX = min(minX, bgMinX);
    maxX = max(maxX, bgMaxX);
    minY = min(minY, bgMinY);
    maxY = max(maxY, bgMaxY);
  }

  // 2. KOMPONENTE: GEOMETRISCHER HINTERGRUND (Kreis / Quadrat)
  if (displayMode == 1 || displayMode == 2 || displayMode == 3) {
    // Berücksichtige bei Kreisen auch den Versatz des äußeren Kreis-Rings (+ outerCircleRadiusOffset)
    float vollerRadius = manualRadius + outerCircleRadiusOffset;
    int geoMinX = (int)((width  / 2) - vollerRadius);
    int geoMaxX = (int)((width  / 2) + vollerRadius);
    int geoMinY = (int)((height / 2) - vollerRadius);
    int geoMaxY = (int)((height / 2) + vollerRadius);

    minX = min(minX, geoMinX);
    maxX = max(maxX, geoMaxX);
    minY = min(minY, geoMinY);
    maxY = max(maxY, geoMaxY);
  } else if (displayMode == 4 || displayMode == 5 || displayMode == 6) {
    int sqMinX = (int)((width  / 2) - (manualSquareSize / 2));
    int sqMaxX = (int)((width  / 2) + (manualSquareSize / 2));
    int sqMinY = (int)((height / 2) - (manualSquareSize / 2));
    int sqMaxY = (int)((height / 2) + (manualSquareSize / 2));

    minX = min(minX, sqMinX);
    maxX = max(maxX, sqMaxX);
    minY = min(minY, sqMinY);
    maxY = max(maxY, sqMaxY);
  }

  // 3. KOMPONENTE: DIE AKTUELLEN SIGILLEN-PUNKTE BERECHNEN
  // Dadurch wird verhindert, dass Linienenden abgeschnitten werden
  ArrayList<float[]> punkte = null;
  if (displayMode <= 3) {
    punkte = getCircularPositions(inputText, width/2, height/2, displayGraphics);
  } else {
    punkte = getSquarePositions(inputText, width/2, height/2, displayMode, displayGraphics);
  }

  if (punkte != null && punkte.size() > 0) {
    for (float[] p : punkte) {
      minX = min(minX, (int)p[0]);
      maxX = max(maxX, (int)p[0]);
      minY = min(minY, (int)p[1]);
      maxY = max(maxY, (int)p[1]);
    }
  }

  // Sicherheits-Fallback: Falls aus irgendeinem Grund nichts berechnet wurde
  if (maxX <= minX || maxY <= minY) {
    minX = 0;
    maxX = width;
    minY = 0;
    maxY = height;
  }
}


//==================================
// export bild
//==================================


void drawTrail(Sigil sigil, PGraphics pg) {
  if (sigil.trailHistory.size()<2) return;
  pg.strokeWeight(spriteSize);
  for(int i=1;i<sigil.trailHistory.size();i++){
    float[] p1=sigil.trailHistory.get(i-1);
    float[] p2=sigil.trailHistory.get(i);
    float a=map(i,1,sigil.trailHistory.size()-1,0,255);
    pg.stroke(red(sigil.c),green(sigil.c),blue(sigil.c),a);
    pg.line(p1[0],p1[1],p2[0],p2[1]);
  }
  float[] h=sigil.trailHistory.get(sigil.trailHistory.size()-1);
  pg.noStroke(); pg.fill(sigil.c); pg.ellipse(h[0],h[1],spriteSize,spriteSize);
}
void exportClean() {

  // =========================
  // 1) SCREENSHOT (ohne UI wenn möglich)
  // =========================
  PImage img = get();

  

  berechneGrafikGroesse();
  

  // =========================
  // 3) RAHMEN
  // =========================
  int pad = 20;

  minX = max(0, minX - pad);
  minY = max(0, minY - pad);
  maxX = min(width-1, maxX + pad);
  maxY = min(height-1, maxY + pad);

  // =========================
  // 4) CROP
  // =========================
  PImage cropped = img.get(
    minX,
    minY,
    maxX - minX,
    maxY - minY
  );



  // =========================
  // 6) SPEICHERN
  // =========================
  File dir = new File(
    android.os.Environment.getExternalStoragePublicDirectory(
      android.os.Environment.DIRECTORY_PICTURES),
    "Sigill");

  if (!dir.exists()) dir.mkdirs();

  String filename =
    "sigill_" +
    year() +
    nf(month(),2) +
    nf(day(),2) + "_" +
    nf(hour(),2) +
    nf(minute(),2) +
    nf(second(),2) +
    ".png";

  File out = new File(dir, filename);

  cropped.save(out.getAbsolutePath());

  lastPath = out.getAbsolutePath();

  println("Gespeichert: " + lastPath);
  
  
  // EINFACHER TRICK: Wir trennen den Pfad manuell nach "Sigill/", 
  // damit er in zwei perfekt zentrierten Zeilen dargestellt wird:
  exportMessage = "Gespeichert in /Pictures/Sigill/:\n" + filename;
  
  showMessage = true;
  messageTimer = millis();
}
