import 'dart:math';

class EffectManager {
  double speedTime1 = 0.0;
  double swordTime1 = 0.0;
  double shieldTime1 = 0.0;
  double multiTime1 = 0.0;
  
  double speedTime2 = 0.0;
  double swordTime2 = 0.0;
  double shieldTime2 = 0.0;
  double multiTime2 = 0.0;

  void reset() {
    speedTime1 = 0; swordTime1 = 0; shieldTime1 = 0; multiTime1 = 0;
    speedTime2 = 0; swordTime2 = 0; shieldTime2 = 0; multiTime2 = 0;
  }

  void update(double dt) {
    if (speedTime1 > 0) speedTime1 = max(0, speedTime1 - dt);
    if (swordTime1 > 0) swordTime1 = max(0, swordTime1 - dt);
    if (shieldTime1 > 0) shieldTime1 = max(0, shieldTime1 - dt);
    if (multiTime1 > 0) multiTime1 = max(0, multiTime1 - dt);
    
    if (speedTime2 > 0) speedTime2 = max(0, speedTime2 - dt);
    if (swordTime2 > 0) swordTime2 = max(0, swordTime2 - dt);
    if (shieldTime2 > 0) shieldTime2 = max(0, shieldTime2 - dt);
    if (multiTime2 > 0) multiTime2 = max(0, multiTime2 - dt);
  }
}
