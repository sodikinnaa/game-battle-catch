import 'dart:math';
import 'dart:ui';
import '../game_config.dart';
import 'effect_manager.dart';
import 'clone_manager.dart';

class GameEngine {
  // Sub-Managers
  final EffectManager _effects = EffectManager();
  final CloneManager _clones = CloneManager();

  // Arena State
  Size arenaSize = Size.zero;
  final Random _random = Random();
  double matchTime = 0.0;

  // Players
  Offset pos1 = Offset.zero;
  Offset vel1 = const Offset(3, 3);
  int hp1 = GameConfig.initialHp;
  
  Offset pos2 = Offset.zero;
  Offset vel2 = const Offset(-3, 2);
  int hp2 = GameConfig.initialHp;

  // Effects (Proxied to EffectManager for compatibility)
  double get speedTime1 => _effects.speedTime1; set speedTime1(double v) => _effects.speedTime1 = v;
  double get swordTime1 => _effects.swordTime1; set swordTime1(double v) => _effects.swordTime1 = v;
  double get shieldTime1 => _effects.shieldTime1; set shieldTime1(double v) => _effects.shieldTime1 = v;
  double get multiTime1 => _effects.multiTime1; set multiTime1(double v) => _effects.multiTime1 = v;
  
  double get speedTime2 => _effects.speedTime2; set speedTime2(double v) => _effects.speedTime2 = v;
  double get swordTime2 => _effects.swordTime2; set swordTime2(double v) => _effects.swordTime2 = v;
  double get shieldTime2 => _effects.shieldTime2; set shieldTime2(double v) => _effects.shieldTime2 = v;
  double get multiTime2 => _effects.multiTime2; set multiTime2(double v) => _effects.multiTime2 = v;

  // Items
  List<Map<String, dynamic>> spawnedItems = [];
  
  // Clones (Proxied)
  List<Map<String, dynamic>> get clones => _clones.clones;

  // Callbacks
  Function(int team, int type)? onPowerUpCollected;
  Function(int winner)? onGameOver;

  void initialize(Size size) {
    arenaSize = size;
    // Initial Positions
    pos1 = Offset(40, size.height / 2 - GameConfig.playerSize / 2);
    pos2 = Offset(size.width - 40 - GameConfig.playerSize, size.height / 2 - GameConfig.playerSize / 2);
    
    // Reset Stats
    hp1 = GameConfig.initialHp;
    hp2 = GameConfig.initialHp;
    matchTime = GameConfig.matchDuration.toDouble();
    speedTime1 = 0; swordTime1 = 0; shieldTime1 = 0; multiTime1 = 0;
    speedTime2 = 0; swordTime2 = 0; shieldTime2 = 0; multiTime2 = 0;
    spawnedItems.clear();
    _clones.reset();
    
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
    if (matchTime <= 0) return; // Game Over
    
    matchTime -= dt;
    if (matchTime <= 0) {
        matchTime = 0;
        // Time Up! Check Winner
        int winner = 0;
        if (hp1 > hp2) winner = 1;
        else if (hp2 > hp1) winner = 2;
        else winner = 0; // Draw
        
        onGameOver?.call(winner);
        return;
    }

    if (speedTime1 > 0) speedTime1 = max(0, speedTime1 - dt);
    if (swordTime1 > 0) swordTime1 = max(0, swordTime1 - dt);
    if (shieldTime1 > 0) shieldTime1 = max(0, shieldTime1 - dt);
    if (multiTime1 > 0) multiTime1 = max(0, multiTime1 - dt);
    
    if (speedTime2 > 0) speedTime2 = max(0, speedTime2 - dt);
    if (swordTime2 > 0) swordTime2 = max(0, swordTime2 - dt);
    if (shieldTime2 > 0) shieldTime2 = max(0, shieldTime2 - dt);
    if (multiTime2 > 0) multiTime2 = max(0, multiTime2 - dt);

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
    
    // 6. Update Clones
    _updateClones();
  }
  
  void _updateClones() {
    for (int i = clones.length - 1; i >= 0; i--) {
       var clone = clones[i];
       clone['life'] -= 0.016; // approx dt
       if (clone['life'] <= 0) {
           clones.removeAt(i);
           continue;
       }
       
       // Move
       Offset pos = clone['pos'];
       Offset vel = clone['vel'];
       pos += vel;
       
       // Wall
       if (pos.dx <= 0) { pos = Offset(0, pos.dy); vel = Offset(-vel.dx, vel.dy); }
       else if (pos.dx >= arenaSize.width - 40) { pos = Offset(arenaSize.width - 40, pos.dy); vel = Offset(-vel.dx, vel.dy); }
       
       if (pos.dy <= 0) { pos = Offset(pos.dx, 0); vel = Offset(vel.dx, -vel.dy); }
       else if (pos.dy >= arenaSize.height - 40) { pos = Offset(pos.dx, arenaSize.height - 40); vel = Offset(vel.dx, -vel.dy); }
       
       clone['pos'] = pos;
       clone['vel'] = vel;
       
       // Check Collision with ENEMY
       int team = clone['team'];
       Offset targetPos = team == 1 ? pos2 : pos1;
       
       // Distance
       Offset c1 = pos + Offset(GameConfig.playerSize/2, GameConfig.playerSize/2);
       Offset c2 = targetPos + Offset(GameConfig.playerSize/2, GameConfig.playerSize/2);
       double dist = (c1 - c2).distance;
       
       if (dist < GameConfig.playerSize) { // Full size collision
           // Hit!
           /* 
           // Clones do NOT deal damage (per user request)
           bool ownerHasSword = team == 1 ? swordTime1 > 0 : swordTime2 > 0;
           bool targetHasShield = team == 1 ? shieldTime2 > 0 : shieldTime1 > 0;
           
           if (ownerHasSword && !targetHasShield) {
               if (team == 1) hp2 = max(0, hp2 - GameConfig.damage);
               else hp1 = max(0, hp1 - GameConfig.damage);
           }
           */
           
           // Bounce clone away strongly
           clone['vel'] = -vel; 
       }
    }
  }

  void spawnPowerUp() {
    if (arenaSize == Size.zero) return;
    if (spawnedItems.isNotEmpty) return; // Wait for clear board

    double rand = _random.nextDouble();
    if (rand < GameConfig.dualSpawnChance) {
      _spawnItem(1);
      _spawnItem(2);
    } else {
      // 4-way split: 0-0.25 (Lightning), 0.25-0.5 (Sword), 0.5-0.75 (Shield), 0.75-1.0 (Multi)
      double r = _random.nextDouble();
      int type;
      if (r < 0.25) type = 1;
      else if (r < 0.50) type = 2;
      else if (r < 0.75) type = 3;
      else type = 4;
      
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
    } else if (type == 4) { // Multi (Clone)
        if (playerIdx == 1) multiTime1 = GameConfig.totalEffectDuration;
        else multiTime2 = GameConfig.totalEffectDuration;

        // Spawn 1 clone via Manager
        for (int k=0; k<1; k++) {
           Offset p = playerIdx == 1 ? pos1 : pos2;
           Offset v = playerIdx == 1 ? vel1 : vel2;
           // Random spread
           v = Offset(v.dx * (0.5 + _random.nextDouble()), v.dy * (0.5 + _random.nextDouble()));
           if (_random.nextBool()) v = -v; // Chaos
           
           _clones.spawnClone(playerIdx, p, v);
        }
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
