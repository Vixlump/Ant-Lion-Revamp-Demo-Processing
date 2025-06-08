//Game states
final int MENU = 0;
final int PLAYING = 1;
final int GAME_OVER = 2;
final int VICTORY = 3;
int gameState = MENU;

//Difficulty levels
final int EASY = 0;
final int MEDIUM = 1;
final int HARD = 2;
int difficulty = EASY;

//Game settings
int gridWidth = 7;
int gridHeight;
int tileSize;
int antX, antY;
int antLionY;
float moveTimer;
float moveDelay = 0.5; //seconds per tile
boolean[][] traps;
boolean[][] revealedTraps;
boolean antStunned = false;
float stunTimer = 0;
float stunDuration = 0.5;
int score = 0;
int coinsCollected = 0;
int maxCoins = 15;
float gameTime;
float gameDuration = 120; //2 minutes in seconds
boolean invincible = false;
float invincibleTimer = 0;
float invincibleDuration = 5;
boolean trapsRevealed = false;
float revealTimer = 0;
float revealDuration = 5;
float avalancheTimer = 0;
float avalancheInterval = 5; //seconds between avalanches
int avalancheColumn = -1;
float avalancheProgress = 0;
boolean inAvalanche = false;
boolean qteActive = false;
float qteTimer = 0;
float qteDuration = 1;
boolean qteSuccess = false;
int antLionMoveCounter = 0;
int antLionMoveDelay = 50; //frames between ant lion moves (1 second at 60fps)

//Power-up positions
ArrayList<PVector> powerups = new ArrayList<PVector>();
final int POWERUP_TIME = 0;
final int POWERUP_INVINCIBLE = 1;
final int POWERUP_REVEAL = 2;
int[] powerupCounts = {2, 2, 2}; //Time, Invincible, Reveal (2 of each will display per levl)

//Coin positions
ArrayList<PVector> coins = new ArrayList<PVector>();

//Colors
color bgColor = color(240, 220, 180); //Sand color
color antColor = color(100, 80, 60);
color trapColor = color(200, 100, 100);
color revealedTrapColor = color(200, 150, 150);
color safeColor = color(220, 200, 160);
color antLionColor = color(150, 100, 50);
color powerupColors[] = {color(100, 200, 255), color(255, 255, 100), color(100, 255, 100)};
color coinColor = color(255, 215, 0);
color avalancheColor = color(200, 180, 160);
color stunColor = color(255, 255, 0, 150);

void setup() {
  size(800, 600);
  smooth();
  resetGame();
}

void resetGame() {
  //Set grid size based on difficulty
  switch(difficulty) {
    case EASY:
      gridHeight = 30;
      break;
    case MEDIUM:
      gridHeight = 40;
      break;
    case HARD:
      gridHeight = 50;
      break;
  }
  
  //Calculate tile size based on window size and grid dimensions
  tileSize = min(width/gridWidth, height/(gridHeight+2)); // +2 for UI space
  
  //Initialize ant position
  antX = gridWidth/2;
  antY = gridHeight-1;
  
  //Initialize ant lion position
  antLionY = gridHeight + 2;
  
  //Initialize game timer
  gameTime = gameDuration;
  
  //Initialize movement timer
  moveTimer = moveDelay;
  
  //Initialize traps
  traps = new boolean[gridWidth][gridHeight];
  revealedTraps = new boolean[gridWidth][gridHeight];
  generateTraps();
  
  //Initialize powerups and coins
  powerups.clear();
  coins.clear();
  placePowerupsAndCoins();
  
  //Reset game state
  antStunned = false;
  stunTimer = 0;
  score = 0;
  coinsCollected = 0;
  invincible = false;
  invincibleTimer = 0;
  trapsRevealed = false;
  revealTimer = 0;
  avalancheTimer = 0;
  avalancheColumn = -1;
  avalancheProgress = 0;
  inAvalanche = false;
  qteActive = false;
  qteTimer = 0;
  qteSuccess = false;
  antLionMoveCounter = 0;
}

void generateTraps() {
  //Clear all traps
  for (int x = 0; x < gridWidth; x++) {
    for (int y = 0; y < gridHeight; y++) {
      traps[x][y] = false;
      revealedTraps[x][y] = false;
    }
  }
  
  //Determine trap density based on difficulty
  float rowFillProbability = 3.5; //Easy default
  float trapProbability = 4.0/7.0;
  
  switch(difficulty) {
    case MEDIUM:
      rowFillProbability = 0.45;
      break;
    case HARD:
      rowFillProbability = 0.55;
      trapProbability = 5.0/7.0;
      break;
  }
  
  //Generate traps
  for (int y = 1; y < gridHeight-1; y++) { //Skip bottom and top rows
    //Skip rows to ensure at least one safe row between hazards
    if (y % 2 == 0) continue;
    
    //Decide if this row will have traps
    if (random(1) < rowFillProbability) {
      //Place traps in this row
      for (int x = 0; x < gridWidth; x++) {
        if (random(1) < trapProbability) {
          traps[x][y] = true;
        }
      }
    }
  }
  
  //Ensure no complete barriers
  for (int y = 1; y < gridHeight-1; y++) {
    boolean allTrapped = true;
    for (int x = 0; x < gridWidth; x++) {
      if (!traps[x][y]) {
        allTrapped = false;
        break;
      }
    }
    
    if (allTrapped) {
      //Make one tile safe in this row
      int safeX = floor(random(gridWidth));
      traps[safeX][y] = false;
    }
  }
}

void placePowerupsAndCoins() {
  //Place powerups on safe tiles
  for (int type = 0; type < 3; type++) {
    for (int i = 0; i < powerupCounts[type]; i++) {
      boolean placed = false;
      while (!placed) {
        int x = floor(random(gridWidth));
        int y = floor(random(1, gridHeight-1)); //Not on bottom or top row
        
        //Check if tile is safe and not already has a powerup
        if (!traps[x][y] && !hasPowerupAt(x, y)) {
          powerups.add(new PVector(x, y, type));
          placed = true;
        }
      }
    }
  }
  
  //Place coins
  int coinsToPlace = min(maxCoins, floor(random(maxCoins*0.7, maxCoins)));
  for (int i = 0; i < coinsToPlace; i++) {
    boolean placed = false;
    while (!placed) {
      int x = floor(random(gridWidth));
      int y = floor(random(1, gridHeight-1)); //Not on bottom or top row
      
      //On easy, only place coins on safe tiles
      if (difficulty == EASY && traps[x][y]) continue;
      
      //Check if not already has a coin
      if (!hasCoinAt(x, y)) {
        coins.add(new PVector(x, y));
        placed = true;
      }
    }
  }
}

boolean hasPowerupAt(int x, int y) {
  for (PVector p : powerups) {
    if (p.x == x && p.y == y) {
      return true;
    }
  }
  return false;
}

boolean hasCoinAt(int x, int y) {
  for (PVector p : coins) {
    if (p.x == x && p.y == y) {
      return true;
    }
  }
  return false;
}

void draw() {
  background(bgColor);
  
  switch(gameState) {
    case MENU:
      drawMenu();
      break;
    case PLAYING:
      updateGame();
      drawGame();
      break;
    case GAME_OVER:
      drawGameOver();
      break;
    case VICTORY:
      drawVictory();
      break;
  }
}

void drawMenu() {
  //title
  fill(0);
  textSize(48);
  textAlign(CENTER, CENTER);
  text("ANT ESCAPE", width/2, height/4);
  
  //difficulty selection
  textSize(32);
  fill(difficulty == EASY ? color(0, 200, 0) : color(100));
  text("EASY", width/2, height/2 - 60);
  fill(difficulty == MEDIUM ? color(200, 200, 0) : color(100));
  text("MEDIUM", width/2, height/2);
  fill(difficulty == HARD ? color(200, 0, 0) : color(100));
  text("HARD", width/2, height/2 + 60);
  
  //Start button
  fill(0, 150, 0);
  rect(width/2 - 100, height*3/4, 200, 60);
  fill(255);
  textSize(28);
  text("START GAME", width/2, height*3/4 + 30);
  
  //Instructions
  textSize(16);
  fill(0);
  textAlign(LEFT, CENTER);
  text("Use arrow keys to move\nCollect coins and power-ups\nReach the top to win!\nAvoid traps and the ant lion", width/5, height*3/4 - 80);
}

void updateGame() {
  //uupdate timers
  float deltaTime = 1.0/60.0; // 60fps
  
  if (!antStunned && !inAvalanche && !qteActive) {
    moveTimer -= deltaTime;
  }
  
  //update game time
  gameTime -= deltaTime;
  if (gameTime <= 0) {
    gameState = GAME_OVER;
    return;
  }
  
  //update stun timer
  if (antStunned) {
    stunTimer -= deltaTime;
    if (stunTimer <= 0) {
      antStunned = false;
    }
  }
  
  //update power-up timers
  if (invincible) {
    invincibleTimer -= deltaTime;
    if (invincibleTimer <= 0) {
      invincible = false;
    }
  }
  
  if (trapsRevealed) {
    revealTimer -= deltaTime;
    if (revealTimer <= 0) {
      trapsRevealed = false;
    }
  }
  
  //update avalanche timer
  avalancheTimer += deltaTime;
  if (avalancheTimer >= avalancheInterval && avalancheColumn == -1) {
    startAvalanche();
    avalancheTimer = 0;
  }
  
  //update avalanche progress
  if (avalancheColumn != -1) {
    avalancheProgress += deltaTime * 2; //Speed of avalanche fall
    
    //Check if avalanche hits ant
    if (!invincible && !qteActive && int(avalancheProgress) == antY && avalancheColumn == antX) {
      startQTE();
    }
    
    if (avalancheProgress >= gridHeight) {
      avalancheColumn = -1;
      avalancheProgress = 0;
    }
  }
  
  //update QTE
  if (qteActive) {
    qteTimer -= deltaTime;
    if (qteTimer <= 0) {
      qteActive = false;
      if (!qteSuccess) {
        //Ant hit by avalanche
        antY = min(antY + 2, gridHeight-1);
        antStunned = true;
        stunTimer = 1.0; //1 second stun
      }
    }
  }
  
  //Move ant lion periodically
  antLionMoveCounter++;
  if (antLionMoveCounter >= antLionMoveDelay) {
    antLionMoveCounter = 0;
    
    //Only start moving when ant has moved up somewhat
    if (antY < gridHeight - 5 || gameTime < gameDuration - 10) {
      if (antLionY > antY) {
        antLionY--;
      } else if (antLionY < antY) {
        antLionY++;
      }
      
      //check if ant lion caught the ant (only if at same level)
      if (antLionY == antY) {
        gameState = GAME_OVER;
      }
    } else {
      //Slowly bring ant lion into the grid at start
      if (antLionY > gridHeight) {
        antLionY--;
      }
    }
  }
  
  //Check victory condition
  if (antY <= 0) {
    gameState = VICTORY;
    //calculate score: coins + 1 point per 3 seconds remaining
    score = coinsCollected + int(gameTime / 3);
  }
}

void startAvalanche() {
  avalancheColumn = floor(random(gridWidth));
  avalancheProgress = 0;
}

void startQTE() {
  qteActive = true;
  qteTimer = qteDuration;
  qteSuccess = false;
}

void drawGame() {
  int cameraOffsetY = 0;
  int maxVisibleTiles = height / tileSize - 2; //Allow a small margin
  int bufferRows = 4;
  
  if (antY < gridHeight - maxVisibleTiles) {
    cameraOffsetY = max(0, (antY - bufferRows) * tileSize);
  }
  //Draw grid
  for (int x = 0; x < gridWidth; x++) {
    for (int y = 0; y < gridHeight; y++) {
      //Calculate screen position
      int screenX = x * tileSize;
      int screenY = y * tileSize + 50 - cameraOffsetY; //Offset for UI
      
      //Draw tile
      if (traps[x][y] && (trapsRevealed || revealedTraps[x][y])) {
        fill(revealedTraps[x][y] ? revealedTrapColor : trapColor);
      } else {
        fill(safeColor);
      }
      noStroke();
      rect(screenX, screenY, tileSize, tileSize);
      
      // Draw grid lines
      stroke(180);
      noFill();
      rect(screenX, screenY, tileSize, tileSize);
    }
  }
  
  //Draw powerups
  for (PVector p : powerups) {
    int x = int(p.x);
    int y = int(p.y);
    int type = int(p.z);
    
    int screenX = x * tileSize + tileSize/2;
    int screenY = y * tileSize + tileSize/2 + 50 - cameraOffsetY;
    
    fill(powerupColors[type]);
    noStroke();
    ellipse(screenX, screenY, tileSize/2, tileSize/2);
    
    //Draw icon based on type
    fill(0);
    textAlign(CENTER, CENTER);
    textSize(12);
    switch(type) {
      case POWERUP_TIME:
        text("T", screenX, screenY);
        break;
      case POWERUP_INVINCIBLE:
        text("I", screenX, screenY);
        break;
      case POWERUP_REVEAL:
        text("R", screenX, screenY);
        break;
    }
  }
  
  //Draw coins
  for (PVector p : coins) {
    int x = int(p.x);
    int y = int(p.y);
    
    int screenX = x * tileSize + tileSize/2;
    int screenY = y * tileSize + tileSize/2 + 50 - cameraOffsetY;
    
    fill(coinColor);
    noStroke();
    ellipse(screenX, screenY, tileSize/3, tileSize/3);
  }
  
  //Draw ant
  int antScreenX = antX * tileSize + tileSize/2;
  int antScreenY = antY * tileSize + tileSize/2 + 50 - cameraOffsetY;
  
  fill(antColor);
  noStroke();
  ellipse(antScreenX, antScreenY, tileSize/2, tileSize/2);
  
  //Draw stun effect if stunned, its very fancy oooo
  if (antStunned) {
    fill(stunColor);
    ellipse(antScreenX, antScreenY, tileSize, tileSize);
    
    //Draw stars spinning around ant
    fill(255, 255, 0);
    float angle = frameCount * 0.2;
    for (int i = 0; i < 4; i++) {
      float x = antScreenX + cos(angle + i*HALF_PI) * tileSize/2;
      float y = antScreenY + sin(angle + i*HALF_PI) * tileSize/2;
      star(x, y, 5, 10, 5);
    }
  }
  
  //Draw ant lion if it's in the grid
  if (antLionY < gridHeight) {
    int antLionScreenX = antX * tileSize + tileSize/2;
    int antLionScreenY = antLionY * tileSize + tileSize/2 + 50 - cameraOffsetY;
    
    fill(antLionColor);
    ellipse(antLionScreenX, antLionScreenY, tileSize, tileSize/2);
    
    //Draw mandibles
    float mandibleAngle = sin(frameCount * 0.2) * 0.3;
    pushMatrix();
    translate(antLionScreenX, antLionScreenY);
    rotate(mandibleAngle);
    line(0, 0, tileSize/3, -tileSize/4);
    rotate(-mandibleAngle * 2);
    line(0, 0, tileSize/3, -tileSize/4);
    popMatrix();
  }
  
  //Draw avalanche if active
  if (avalancheColumn != -1) {
    int avalancheScreenX = avalancheColumn * tileSize;
    int avalancheScreenY = int(avalancheProgress) * tileSize + 50 - cameraOffsetY;
    
    fill(avalancheColor);
    noStroke();
    rect(avalancheScreenX, avalancheScreenY, tileSize, tileSize);
    
    //Draw warning at top
    if (avalancheProgress < 1) {
      fill(255, 0, 0, 150);
      rect(avalancheScreenX, 50, tileSize, tileSize/2);
    }
  }
  
  //Draw QTE if active
  if (qteActive) {
    fill(0, 0, 0, 150);
    rect(0, 0, width, height);
    
    fill(255);
    textSize(32);
    textAlign(CENTER, CENTER);
    text("PRESS SPACE TO DODGE!", width/2, height/2);
    
    // Draw timer bar
    float qteWidth = map(qteTimer, qteDuration, 0, 200, 0);
    fill(255, 0, 0);
    rect(width/2 - 100, height/2 + 50, 200 - qteWidth, 20);
    noFill();
    stroke(255);
    rect(width/2 - 100, height/2 + 50, 200, 20);
  }
  
  //Draw UI
  fill(0);
  textSize(24);
  textAlign(LEFT, TOP);
  text("Time: " + nf(gameTime, 0, 1), 20, 10);
  text("Coins: " + coinsCollected, 200, 10);
  text("Score: " + score, 400, 10);
  
  //Draw power-up indicators
  if (invincible) {
    fill(powerupColors[POWERUP_INVINCIBLE]);
    text("INVINCIBLE", width - 150, 10);
  }
  if (trapsRevealed) {
    fill(powerupColors[POWERUP_REVEAL]);
    text("TRAPS REVEALED", width - 150, 40);
  }
  
  //draw instructions during gameplay
  textSize(14);
  text("Arrow Keys: Move\nSpace: Dodge", width - 150, height - 60);
}

void star(float x, float y, float radius1, float radius2, int npoints) {
  float angle = TWO_PI / npoints;
  float halfAngle = angle/2.0;
  beginShape();
  for (float a = 0; a < TWO_PI; a += angle) {
    float sx = x + cos(a) * radius2;
    float sy = y + sin(a) * radius2;
    vertex(sx, sy);
    sx = x + cos(a+halfAngle) * radius1;
    sy = y + sin(a+halfAngle) * radius1;
    vertex(sx, sy);
  }
  endShape(CLOSE);
}

void drawGameOver() {
  fill(0, 0, 0, 200);
  rect(0, 0, width, height);
  
  fill(255, 0, 0);
  textSize(48);
  textAlign(CENTER, CENTER);
  text("GAME OVER", width/2, height/2 - 60);
  
  fill(255);
  textSize(32);
  text("Score: " + score, width/2, height/2);
  
  fill(200);
  rect(width/2 - 100, height/2 + 60, 200, 60);
  fill(0);
  textSize(28);
  text("RETRY", width/2, height/2 + 90);
  
  fill(200);
  rect(width/2 - 100, height/2 + 140, 200, 60);
  fill(0);
  textSize(28);
  text("MENU", width/2, height/2 + 170);
}

void drawVictory() {
  fill(0, 0, 0, 150);
  rect(0, 0, width, height);
  
  fill(0, 255, 0);
  textSize(48);
  textAlign(CENTER, CENTER);
  text("VICTORY!", width/2, height/2 - 60);
  
  fill(255);
  textSize(32);
  text("Score: " + score, width/2, height/2);
  
  fill(200);
  rect(width/2 - 100, height/2 + 60, 200, 60);
  fill(0);
  textSize(28);
  text("NEXT LEVEL", width/2, height/2 + 90);
  
  fill(200);
  rect(width/2 - 100, height/2 + 140, 200, 60);
  fill(0);
  textSize(28);
  text("MENU", width/2, height/2 + 170);
}

void keyPressed() {
  if (gameState == PLAYING) {
    if (qteActive && key == ' ') {
      qteSuccess = true;
      qteActive = false;
      return;
    }
    
    if (!antStunned && !inAvalanche && !qteActive && moveTimer <= 0) {
      //Handle movement
      if (keyCode == LEFT && antX > 0) {
        antX--;
        moveTimer = moveDelay;
        checkTile();
      } else if (keyCode == RIGHT && antX < gridWidth-1) {
        antX++;
        moveTimer = moveDelay;
        checkTile();
      } else if (keyCode == UP && antY > 0) {
        antY--;
        moveTimer = moveDelay;
        checkTile();
      } else if (keyCode == DOWN && antY < gridHeight-1) {
        antY++;
        moveTimer = moveDelay;
        checkTile();
      }
    }
  }
}

void checkTile() {
  //Check for traps
  if (traps[antX][antY] && !invincible) {
    if (!revealedTraps[antX][antY]) {
      //First time hitting this trap
      revealedTraps[antX][antY] = true;
      antY = min(antY + 1, gridHeight-1); // Fall down 1 tile
      antStunned = true;
      stunTimer = stunDuration;
    }
  }
  
  //Check for powerups
  for (int i = powerups.size()-1; i >= 0; i--) {
    PVector p = powerups.get(i);
    if (int(p.x) == antX && int(p.y) == antY) {
      activatePowerup(int(p.z));
      powerups.remove(i);
    }
  }
  
  //Check for coins
  for (int i = coins.size()-1; i >= 0; i--) {
    PVector p = coins.get(i);
    if (int(p.x) == antX && int(p.y) == antY) {
      coinsCollected++;
      score++;
      coins.remove(i);
    }
  }
}

void activatePowerup(int type) {
  switch(type) {
    case POWERUP_TIME:
      gameTime += 10; //Add 10 seconds
      break;
    case POWERUP_INVINCIBLE:
      invincible = true;
      invincibleTimer = invincibleDuration;
      break;
    case POWERUP_REVEAL:
      trapsRevealed = true;
      revealTimer = revealDuration;
      break;
  }
}

void mousePressed() {
  if (gameState == MENU) {
    //Check difficulty selection
    if (mouseX > width/2 - 100 && mouseX < width/2 + 100) {
      if (mouseY > height/2 - 80 && mouseY < height/2 - 40) {
        difficulty = EASY;
      } else if (mouseY > height/2 - 20 && mouseY < height/2 + 20) {
        difficulty = MEDIUM;
      } else if (mouseY > height/2 + 40 && mouseY < height/2 + 80) {
        difficulty = HARD;
      } else if (mouseY > height*3/4 && mouseY < height*3/4 + 60) {
        gameState = PLAYING;
        resetGame();
      }
    }
  } else if (gameState == GAME_OVER || gameState == VICTORY) {
    //Check buttons
    if (mouseX > width/2 - 100 && mouseX < width/2 + 100) {
      if (mouseY > height/2 + 60 && mouseY < height/2 + 120) {
        // Retry/Next level
        gameState = PLAYING;
        resetGame();
      } else if (mouseY > height/2 + 140 && mouseY < height/2 + 200) {
        //Menu
        gameState = MENU;
      }
    }
  }
}
