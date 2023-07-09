import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;

Minim minim;
AudioPlayer musicPlayer;
AudioPlayer music2Player;

PShape heartSVG;
float scaleFactor = 0.2;
boolean animationActive = false;
boolean spacePressed = false;
boolean showSlider = false;
ArrayList<SmallHeart> smallHearts;
Slider slider;
float pulseFactor = 1.5;
float spacePressedTime;
float elapsedTime;
float transitionDuration = 1500;
float transitionStartTime;
float heartOpacity = 255;
float sliderOpacity = 0;
float previousMillis;
int heartInterval = 10; // Intervalo entre a criação de novos pequenos corações

void setup() {
  size(800, 600);
  smooth();
  
  minim = new Minim(this);
  musicPlayer = minim.loadFile("batida.mp3");
  music2Player = minim.loadFile("musica.mp3");
  

  heartSVG = loadShape("coracao.svg");

  smallHearts = new ArrayList<SmallHeart>();

  slider = new Slider();
  slider.addImage(loadImage("a.png"));
  slider.addImage(loadImage("b.jpg"));
  slider.addImage(loadImage("c.jpg"));

  previousMillis = millis();
}

void draw() {
  background(250, 210, 230);

  if (spacePressed) {
    elapsedTime = millis() - spacePressedTime;
    if (elapsedTime >= 8000 && !showSlider) {
      showSlider = true;
      animationActive = false;
      smallHearts.clear();
      transitionStartTime = millis();
    } else {
      animationActive = true;
    }
  } else {
    animationActive = false;
    showSlider = false;
    smallHearts.clear();
  }

  for (int i = smallHearts.size() - 1; i >= 0; i--) {
    SmallHeart smallHeart = smallHearts.get(i);
    smallHeart.update();
    smallHeart.display();
    if (smallHeart.isOffscreen() || smallHeart.isExpired()) {
      smallHearts.remove(i);
    }
  }

  if (animationActive && frameCount % heartInterval == 0) {
    createSmallHeart();
  }

  if (animationActive) {
    pulseFactor = map(sin(frameCount * 0.06), -1, 1, 0.5, 1.5);
  } else {
    pulseFactor = 1.0;
  }
 
  float x = width / 2;
  float y = height / 2;

  float scaledWidth = heartSVG.width * scaleFactor * pulseFactor;
  float scaledHeight = heartSVG.height * scaleFactor * pulseFactor;

  if (showSlider) {
    float transitionElapsedTime = millis() - transitionStartTime;
    if (transitionElapsedTime < transitionDuration) {
      float transitionProgress = transitionElapsedTime / transitionDuration;
      heartOpacity = 255 - (255 * transitionProgress);
      sliderOpacity = 255 * transitionProgress;
    } else {
      sliderOpacity = 255;
    }
  } else {
    heartOpacity = 255;
  }

  shapeMode(CENTER);
  tint(255, heartOpacity);
  shape(heartSVG, x, y, scaledWidth, scaledHeight);
  noTint();

  if (showSlider && millis() - spacePressedTime >= 8000) {
    slider.display(sliderOpacity);
  }
}

void createSmallHeart() {
  if (smallHearts.size() < 20) { //  Limita o número de pequenos corações
    float x = width + heartSVG.width * scaleFactor; //  Inicia o coração fora da tela à direita
    float y = random(height);
    float scaleVariation = random(0.1, 0.5); // Variação no tamanho dos corações pequenos
    float speed = random(1, 5); // Adjuste vecolidade
    SmallHeart smallHeart = new SmallHeart(x, y, scaleVariation, speed);
    smallHearts.add(smallHeart);
  }
}


void keyPressed() {
  if (keyCode == 32 && !spacePressed) {
    spacePressed = true;
    spacePressedTime = millis();
    pulseFactor = 1.0;
    elapsedTime = 0;
    
    musicPlayer.loop();
    music2Player.loop();
  }
}

void keyReleased() {
  if (keyCode == 32 && spacePressed) {
    spacePressed = false;
    pulseFactor = 1.0;
    elapsedTime = 0;
    
    musicPlayer.pause();
    music2Player.pause();
  }
}

class SmallHeart {
  float x, y;
  float speed;
  float scaleVariation;
  boolean fadingOut;
  int lifeTimer;
  int fadeOutDuration = 180; // Duração do desvanecimento em quadros (3 segundos)
  float pulseFactor; // Fator de pulsação para cada coração individual
  float pulseRate; // Taxa de pulsação para cada coração individual
  float pulseTimer; // Temporizador para a animação de pulsação
  float minPulseFactor = 0.5; // Fator de pulsação mínimo
  float maxPulseFactor = 1.5; // Fator de pulsação máximo
  float initialScale;
  float targetScale;
  float zoomDuration = 2000; // Duração do efeito de zoom em milissegundos
  float zoomStartTime;

 SmallHeart(float x, float y, float scaleVariation, float speed) {
  this.x = x;
  this.y = y;
  this.speed = speed;
  this.scaleVariation = scaleVariation;
  this.fadingOut = false;
  this.lifeTimer = frameCount;
  this.pulseFactor = random(minPulseFactor, maxPulseFactor); // Fator de pulsação inicial aleatório entre minPulseFactor e maxPulseFactor
  this.pulseRate = random(0.5, 2.0); // Taxa de pulsação inicial aleatória entre 0.5 e 2.0
  this.pulseTimer = 0.0; // Inicializa o temporizador de pulsação
  this.initialScale = scaleVariation;
  this.targetScale = scaleVariation * 1.5; // Ajusta a escala alvo para o efeito de zoom
  this.zoomStartTime = millis();
}

void update() {
  // Move o pequeno coração da direita para a esquerda
  x -= speed;

  // Calcula o tempo decorrido desde o início do efeito de zoom
  float zoomElapsedTime = millis() - zoomStartTime;

  // Verifica se o efeito de zoom ainda está ativo
  if (zoomElapsedTime < zoomDuration) {
    // Atualiza a variação de escala com base no progresso do zoom
    float zoomProgress = zoomElapsedTime / zoomDuration;
    scaleVariation = map(zoomProgress, 0, 1, initialScale, targetScale);
  }

  // Calcula o tempo decorrido desde o último quadro
  float elapsedTime = (millis() - previousMillis) / 1000.0;
  previousMillis = millis();

  // Atualiza o temporizador de pulsação
  pulseTimer += elapsedTime;

  // Verifica se o temporizador de pulsação excedeu a taxa de pulsação
  if (pulseTimer >= pulseRate) {
    // Atualiza o fator de pulsação e reinicia o temporizador de pulsação
    updatePulse();
    pulseTimer = 0.0;

    // Aleatoriza a taxa de pulsação para o próximo ciclo
    pulseRate = random(0.5, 2.0); // Taxa de pulsação aleatória entre 0.5 e 2.0
  }
}


void updatePulse() {
    // Atualiza o fator de pulso ao longo do tempo
    pulseFactor = random(minPulseFactor, maxPulseFactor);
}

void display() {
    // Desenha o pequeno coração com tamanho variado
    float scaledWidth = heartSVG.width * scaleFactor * scaleVariation;
    float scaledHeight = heartSVG.height * scaleFactor * scaleVariation;

    // Verifica se o coração está desaparecendo
    if (fadingOut) {
        int alpha = 255 - (frameCount - lifeTimer) * 255 / fadeOutDuration; // Gradiente de transparência
        alpha = max(0, alpha); // Garante que o valor mínimo seja 0 (sem transparência)
        tint(255, alpha); // Aplica a transparência
    }

    shape(heartSVG, x - scaledWidth / 2, y - scaledHeight / 2, scaledWidth, scaledHeight);

    // Restaura as configurações de cor e transparência
    noTint();
}

boolean isOffscreen() {
    // Verifica se o pequeno coração saiu da tela
    return x + heartSVG.width * scaleFactor * scaleVariation < 0;
}

boolean isExpired() {
    // Verifica se o pequeno coração expirou (para ser removido)
    return fadingOut && frameCount - lifeTimer > fadeOutDuration;
}

void startFadingOut() {
    fadingOut = true;
    lifeTimer = frameCount;
}
}



class Slider {
  ArrayList<PImage> images;
  int currentIndex;
  int interval;
  int previousMillis;
  float transitionDuration = 1000; // Duração do efeito de transição em milissegundos
  float transitionProgress = 0.0; // Progresso de transição atual
  int previousFrameMillis; // Timestamp do frame anterior
  float zoom = 1.0; // Fator de escala inicial
  float targetZoom = 2.0; // Fator de escala alvo

  Slider() {
    images = new ArrayList<PImage>();
    currentIndex = 0;
    interval = 10000; // Ajuste o intervalo (milissegundos)
    previousMillis = millis();
    previousFrameMillis = millis();
  }

  void addImage(PImage image) {
    images.add(image);
  }

  void display(float opacity) {
    PImage currentImage = images.get(currentIndex);
    PImage nextImage = images.get((currentIndex + 1) % images.size()); // Próxima imagem no ciclo

    imageMode(CENTER);

    // Calcula a opacidade com base no progresso da transição
    float currentOpacity = lerp(opacity, 0, transitionProgress);
    float nextOpacity = lerp(0, opacity, transitionProgress);

    // Aplica a opacidade na imagem atual
    tint(255, currentOpacity);
    image(currentImage, width / 2, height / 2, width * zoom, height * zoom);

    // Aplica a opacidade na próxima imagem
    tint(255, nextOpacity);
    image(nextImage, width / 2, height / 2, width * zoom, height * zoom);

    // Restaura as configurações de cor e transparência
    noTint();

    // Atualiza o progresso da transição
    int currentMillis = millis();
    int elapsedMillis = currentMillis - previousFrameMillis;
    transitionProgress += elapsedMillis / transitionDuration; // Incrementa o progresso da transição com base no tempo decorrido

    // Limita o progresso da transição entre 0 e 1
    transitionProgress = constrain(transitionProgress, 0.0, 1.0);

    // Atualiza o timestamp do frame anterior
    previousFrameMillis = currentMillis;

    // Verifica se o intervalo passou desde a transição anterior
    if (currentMillis - previousMillis >= interval) {
      previousMillis = currentMillis;
      
      // Verifica se a próxima imagem será exibida (não é a imagem atual)
      if ((currentIndex + 1) % images.size() != currentIndex) {
        // Redefine o zoom para o valor inicial para a próxima imagem
        zoom = 1.0;
      }
      
      currentIndex = (currentIndex + 1) % images.size(); // Avança para a próxima imagem
      transitionProgress = 0.0; // Reinicia o progresso da transição
    }
    
    // Atualiza o zoom usando interpolação linear
    zoom = lerp(zoom, targetZoom, 0.005);
  }
}
