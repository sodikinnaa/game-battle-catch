import 'dart:math';
import 'dart:ui';
import '../game_config.dart';

class GameEngine {
  // Arena State
  Size arenaSize = Size.zero;
  final Random _random = Random();

  // Players
  Offset pos1 = Offset.zero;
  Offset vel1 = const Offset(3, 3);
  int hp1 = GameConfig.initialHp;
  
  Offset pos2 = Offset.zero;
  Offset vel2 = const Offset(-3, 2);
  int hp2 = GameConfig.initialHp;

  // Effects
  double speedTime1 = 0.0;
  double swordTime1 = 0.0;
  double shieldTime1 = 0.0;
  
  double speedTime2 = 0.0;
  double swordTime2 = 0.0;
  double shieldTime2 = 0.0;

  // Items
  List<Map<String, dynamic>> spawnedItems = [];

  // Callbacks
  Function(int team, int type)? onPowerUpCollected;
  Function(int winner)? onGameOver;

  void initialize(Size size) {
    arenaSize = size;
    // Initial Positions
    pos1 = Offset(40, size.height / 2 - GameConfig.playerSize / 2);
    pos2 = Offset(size.width - 40 - GameConfig.playerSize, size.height / 2 - GameConfig.playerSize / 2);
    
    // Reset Stats
    hp2 = GameConfig.initialHp;
    speedTime1 = 0; swordTime1 = 0; shieldTime1 = 0;
    speedTime2 = 0; swordTime2 = 0; shieldTime2 = 0;
    spawnedItems.clear();
    
    // Initial Velocities
    double initialSpeed = 4.0;
    double angle1 = _random.nextDouble() * 2 * pi;
    vel1 = Offset(cos(angle1), sin(angle1)) * initialSpeed;

    double angle2 = _random.nextDouble() * 2 * pi;
    vel2 = Offset(cos(angle2), sin(angle2)) * initialSpeed;
  }

  void update(double dt) {
    if (arenaSize == Size.zero) return;
    if (hp1 <= 0 || hp2 <= 0) return;

    if (speedTime1 > 0) speedTime1 = max(0, speedTime1 - dt);
    if (swordTime1 > 0) swordTime1 = max(0, swordTime1 - dt);
    if (shieldTime1 > 0) shieldTime1 = max(0, shieldTime1 - dt);
    
    if (speedTime2 > 0) speedTime2 = max(0, speedTime2 - dt);
    if (swordTime2 > 0) swordTime2 = max(0, swordTime2 - dt);
    if (shieldTime2 > 0) shieldTime2 = max(0, shieldTime2 - dt);

    _updatePhysics();
  }

  void _updatePhysics() {
    // 1. Update Positions
    pos1 += vel1;
    pos2 += vel2;

    // 2. Boundary
    _checkWallCollision(1);
    _checkWallCollision(2);

    // 3. Player Collision
    _checkPlayerCollision();

    // 4. Item Collision
    _checkItemCollision();

    // 5. Clamp
    vel1 = _clampVelocity(vel1, speedTime1 > 0);
    vel2 = _clampVelocity(vel2, speedTime2 > 0);
  }

  void spawnPowerUp() {
    if (arenaSize == Size.zero) return;
    if (spawnedItems.isNotEmpty) return; // Wait for clear board

    double rand = _random.nextDouble();
    if (rand < GameConfig.dualSpawnChance) {
      _spawnItem(1);
      _spawnItem(2);
    } else {
      // 3-way split: 0-0.33 (Lightning), 0.33-0.66 (Sword), 0.66-1.0 (Shield)
      double r = _random.nextDouble();
      int type;
      if (r < 0.33) type = 1;
      else if (r < 0.66) type = 2;
      else type = 3;
      
      _spawnItem(type);
    }
  }

  void _spawnItem(int type) {
    double x = _random.nextDouble() * (arenaSize.width - 2 * GameConfig.powerUpSize) + GameConfig.powerUpSize/2;
    double y = _random.nextDouble() * (arenaSize.height - 2 * GameConfig.powerUpSize) + GameConfig.powerUpSize/2;
    // Constrain strictly
    x = max(0, min(x, arenaSize.width - GameConfig.powerUpSize));
    y = max(0, min(y, arenaSize.height - GameConfig.powerUpSize));
    
    spawnedItems.add({'pos': Offset(x, y), 'type': type});
  }

  void _checkWallCollision(int playerIdx) {
    Offset pos = playerIdx == 1 ? pos1 : pos2;
    Offset vel = playerIdx == 1 ? vel1 : vel2;

    if (pos.dx <= 0) {
      pos = Offset(0, pos.dy);
      vel = Offset(-vel.dx, vel.dy);
    } else if (pos.dx >= arenaSize.width - GameConfig.playerSize) {
      pos = Offset(arenaSize.width - GameConfig.playerSize, pos.dy);
      vel = Offset(-vel.dx, vel.dy);
    }

    if (pos.dy <= 0) {
      pos = Offset(pos.dx, 0);
      vel = Offset(vel.dx, -vel.dy);
    } else if (pos.dy >= arenaSize.height - GameConfig.playerSize) {
      pos = Offset(pos.dx, arenaSize.height - GameConfig.playerSize);
      vel = Offset(vel.dx, -vel.dy);
    }

    if (playerIdx == 1) { pos1 = pos; vel1 = vel; }
    else { pos2 = pos; vel2 = vel; }
  }

  void _checkPlayerCollision() {
    Offset c1 = pos1 + Offset(GameConfig.playerSize / 2, GameConfig.playerSize / 2);
    Offset c2 = pos2 + Offset(GameConfig.playerSize / 2, GameConfig.playerSize / 2);

    double dx = c2.dx - c1.dx;
    double dy = c2.dy - c1.dy;
    double distance = sqrt(dx * dx + dy * dy);

    if (distance < GameConfig.playerSize) {
      double nx = dx / distance;
      double ny = dy / distance;
      
      double overlap = GameConfig.playerSize - distance;
      Offset separation = Offset(nx, ny) * (overlap / 2);
      
      pos1 -= separation;
      pos2 += separation;

      Offset rv = vel2 - vel1;
      double velAlongNormal = rv.dx * nx + rv.dy * ny;

      if (velAlongNormal > 0) return;

      // Damage (Check Shield!)
      // Damage (Check Shield!)
      // P1 attacks P2
      if (swordTime1 > 0 && shieldTime2 <= 0) {
         hp2 = max(0, hp2 - GameConfig.damage);
      }
      
      // P2 attacks P1
      if (swordTime2 > 0 && shieldTime1 <= 0) {
         hp1 = max(0, hp1 - GameConfig.damage);
      }

      // Check Game Over
      if (hp1 <= 0 && hp2 <= 0) {
          // Draw / Mutual Destruction - Extend Game slightly
          hp1 = 10;
          hp2 = 10;
      } else if (hp2 <= 0) {
          onGameOver?.call(1);
          return;
      } else if (hp1 <= 0) {
          onGameOver?.call(2);
          return;
      }

      double j = -(1 + 1.0) * velAlongNormal; // e=1.0
      j /= 2;
      Offset impulse = Offset(nx * j, ny * j);
      
      vel1 -= impulse;
      vel2 += impulse;

      // Random perturbation
      vel1 += Offset((_random.nextDouble() - 0.5) * 0.5, (_random.nextDouble() - 0.5) * 0.5);
      vel2 += Offset((_random.nextDouble() - 0.5) * 0.5, (_random.nextDouble() - 0.5) * 0.5);
    }
  }

  void _checkItemCollision() {
    if (spawnedItems.isEmpty) return;
    
    for (int i = spawnedItems.length - 1; i >= 0; i--) {
        Map<String, dynamic> item = spawnedItems[i];
        Offset itemPos = item['pos'];
        int itemType = item['type'];
        
        bool picked = false;
        int picker = 0;
        
        bool collides1 = _checkCollision(pos1, GameConfig.playerSize, itemPos, GameConfig.powerUpSize);
        bool collides2 = _checkCollision(pos2, GameConfig.playerSize, itemPos, GameConfig.powerUpSize);
        
        if (collides1 && collides2) {
            // Give to closer player
            double d1 = (pos1 - itemPos).distanceSquared;
            double d2 = (pos2 - itemPos).distanceSquared;
            picker = d1 < d2 ? 1 : 2;
            picked = true;
        } else if (collides1) {
            picker = 1;
            picked = true;
        } else if (collides2) {
            picker = 2;
            picked = true;
        }
        
        if (picked) {
             spawnedItems.removeAt(i);
             _activateEffect(picker, itemType);
        }
    }
  }

  bool _checkCollision(Offset p1, double s1, Offset p2, double s2) {
    Offset c1 = p1 + Offset(s1/2, s1/2);
    Offset c2 = p2 + Offset(s2/2, s2/2);
    double distance = (c1 - c2).distance;
    return distance < (s1/2 + s2/2) * 1.2;
  }

  void _activateEffect(int playerIdx, int type) {
    if (type == 1) { // Speed
        if (playerIdx == 1) {
            if (speedTime1 <= 0) vel1 *= 2.0; 
            speedTime1 = GameConfig.totalEffectDuration;
        } else {
            if (speedTime2 <= 0) vel2 *= 2.0; 
            speedTime2 = GameConfig.totalEffectDuration;
        }
    } else if (type == 2) { // Sword
        if (playerIdx == 1) swordTime1 = GameConfig.totalEffectDuration;
        else swordTime2 = GameConfig.totalEffectDuration;
    } else if (type == 3) { // Shield
        if (playerIdx == 1) shieldTime1 = GameConfig.totalEffectDuration;
        else shieldTime2 = GameConfig.totalEffectDuration;
    }
    
    onPowerUpCollected?.call(playerIdx, type);
  }

  Offset _clampVelocity(Offset vel, bool isBoosted) {
    double speed = vel.distance;
    double currentMax = isBoosted ? GameConfig.boostedMaxSpeed : GameConfig.baseMaxSpeed;
    
    if (speed < GameConfig.minSpeed) {
      if (speed == 0) return Offset(GameConfig.minSpeed, 0); 
      return vel * (GameConfig.minSpeed / speed);
    } else if (speed > currentMax) {
      return vel * (currentMax / speed);
    }
    return vel;
  }
}
