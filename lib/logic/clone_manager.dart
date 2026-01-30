import 'dart:ui';
import '../utils/game_config.dart';

class CloneManager {
  List<Map<String, dynamic>> clones = [];

  void reset() {
    clones.clear();
  }

  void spawnClone(int team, Offset pos, Offset vel) {
     clones.add({
         'pos': pos,
         'vel': vel,
         'team': team,
         'life': GameConfig.totalEffectDuration
     });
  }

  Function(int targetTeam, int damage)? onDamage;

  void update(double dt, Size arenaSize, Offset pos1, Offset pos2, 
      double swordTime1, double swordTime2, double shieldTime1, double shieldTime2) {
    for (int i = clones.length - 1; i >= 0; i--) {
       var clone = clones[i];
       clone['life'] -= dt;
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
       else if (pos.dx >= arenaSize.width - GameConfig.playerSize) { pos = Offset(arenaSize.width - GameConfig.playerSize, pos.dy); vel = Offset(-vel.dx, vel.dy); }
       
       if (pos.dy <= 0) { pos = Offset(pos.dx, 0); vel = Offset(vel.dx, -vel.dy); }
       else if (pos.dy >= arenaSize.height - GameConfig.playerSize) { pos = Offset(pos.dx, arenaSize.height - GameConfig.playerSize); vel = Offset(vel.dx, -vel.dy); }
       
       clone['pos'] = pos;
       clone['vel'] = vel;
       
       // Check Collision with ENEMY
       int team = clone['team'];
       Offset targetPos = team == 1 ? pos2 : pos1;
       
       // Distance
       Offset c1 = pos + Offset(GameConfig.playerSize/2, GameConfig.playerSize/2);
       Offset c2 = targetPos + Offset(GameConfig.playerSize/2, GameConfig.playerSize/2);
       
       double dx = c1.dx - c2.dx;
       double dy = c1.dy - c2.dy;
       double distance = (c1 - c2).distance;

       if (distance < GameConfig.playerSize && distance > 0) { 
           // 1. Calculate Normal (Direction from Enemy to Clone)
           double nx = dx / distance;
           double ny = dy / distance;
           
           // 2. Separate (Push clone out)
           double overlap = GameConfig.playerSize - distance;
           pos += Offset(nx * overlap, ny * overlap);
           clone['pos'] = pos;
           
           // 3. Reflect Velocity
           // v' = v - 2 * (v . n) * n
           double dotProduct = vel.dx * nx + vel.dy * ny;
           
           // Only reflect if moving towards each other
           if (dotProduct < 0) {
               Offset reflection = Offset(nx, ny) * (2 * dotProduct);
               vel -= reflection;
               clone['vel'] = vel; 
           }
           
           // 4. Apply Damage
           // Logic: Clone (Team X) hits Enemy (Team Y).
           // If Team X has Sword AND Team Y NO Shield -> Damage Y.
           bool ownerHasSword = team == 1 ? swordTime1 > 0 : swordTime2 > 0;
           bool targetHasShield = team == 1 ? shieldTime2 > 0 : shieldTime1 > 0;
           
           if (ownerHasSword && !targetHasShield) {
               // Prevent multi-damage per frame? Maybe add cooldown?
               // For now, raw collision damage.
               int targetTeam = team == 1 ? 2 : 1;
               onDamage?.call(targetTeam, GameConfig.damage);
           }
       }
    }
  }
}
