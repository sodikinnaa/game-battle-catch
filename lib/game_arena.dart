import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class GameArena extends StatefulWidget {
  final String team1;
  final String team2;

  const GameArena({super.key, required this.team1, required this.team2});

  @override
  State<GameArena> createState() => _GameArenaState();
}

class _GameArenaState extends State<GameArena> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Size _arenaSize = Size.zero;
  final double _playerSize = 50.0;
  final double _minSpeed = 2.0;
  final double _baseMaxSpeed = 8.0;
  final double _boostedMaxSpeed = 16.0;
  
  // PowerUp State
  Offset? _powerUpPos;
  final double _powerUpSize = 40.0;
  Timer? _powerUpSpawnTimer;
  
  // State for Player 1 (Team 1 - Cyan)
  Offset _pos1 = Offset.zero;
  Offset _vel1 = const Offset(3, 3);
  int _hp1 = 100;

  // State for Player 2 (Team 2 - Red)
  Offset _pos2 = Offset.zero;
  Offset _vel2 = const Offset(-3, 2);
  int _hp2 = 100;

  // PowerUp/Effect State
  // Type: 0 = None, 1 = Speed (Bolt), 2 = Sword (Attack)
  int _itemOnGroundType = 0; 
  int _activeEffectType = 0;
  int _effectOwner = 0; // 1 or 2
  
  double _currentEffectTime = 0.0;
  final double _totalEffectDuration = 5.0; // Seconds

  bool _initialized = false;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
    _scheduleNextPowerUp();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _powerUpSpawnTimer?.cancel();
    super.dispose();
  }
  
  void _scheduleNextPowerUp() {
    // Random interval between 5 and 10 seconds
    int duration = 5 + _random.nextInt(6); 
    _powerUpSpawnTimer = Timer(Duration(seconds: duration), _spawnPowerUp);
  }
  
  void _spawnPowerUp() {
    if (_arenaSize == Size.zero) {
        _scheduleNextPowerUp();
        return;
    }

    // Only spawn if NO effect is currently active
    if (_currentEffectTime > 0) {
      _scheduleNextPowerUp();
      return;
    }
    
    setState(() {
      double x = _random.nextDouble() * (_arenaSize.width - _powerUpSize);
      double y = _random.nextDouble() * (_arenaSize.height - _powerUpSize);
      _powerUpPos = Offset(x, y);
      
      // Randomize Item Type (1: Speed, 2: Sword)
      // "Sword 2x more often than Bolt" => 1/3 Chance for Bolt, 2/3 Chance for Sword
      _itemOnGroundType = _random.nextDouble() < 0.33 ? 1 : 2; 
    });
  }

  void _tick(Duration elapsed) {
    if (!_initialized || _arenaSize == Size.zero) return;
    
    // Check Game Over
    if (_hp1 <= 0 || _hp2 <= 0) return;

    setState(() {
      // Update Effect Timer
      if (_currentEffectTime > 0) {
        _currentEffectTime -= 0.016; // Approx 60fps frame time
        if (_currentEffectTime <= 0) {
          _currentEffectTime = 0;
          
          // Reset Effects
          if (_activeEffectType == 1 && _activeEffectType == 1) { // Was Speed
             if (_effectOwner == 1) _vel1 *= 0.5; // Revert speed
             if (_effectOwner == 2) _vel2 *= 0.5;
          }
           // Sword effect just ends (no physics revert needed)
          
          _activeEffectType = 0;
          _effectOwner = 0;
          
          _scheduleNextPowerUp(); // Schedule next item
        }
      }
      
      _updatePhysics();
    });
  }

  void _updatePhysics() {
    // 1. Update Positions
    _pos1 += _vel1;
    _pos2 += _vel2;

    // 2. Boundary Checks (Bounce with walls)
    _checkWallCollision(1);
    _checkWallCollision(2);

    // 3. Player-to-Player Collision
    _checkPlayerCollision();

    // 4. PowerUp Collision
    _checkPowerUpCollision();

    // 5. Clamp Velocities 
    // Speed boost active if Type == 1
    bool speedBoost1 = (_activeEffectType == 1 && _effectOwner == 1);
    bool speedBoost2 = (_activeEffectType == 1 && _effectOwner == 2);
    
    _vel1 = _clampVelocity(_vel1, speedBoost1);
    _vel2 = _clampVelocity(_vel2, speedBoost2);
  }

  Offset _clampVelocity(Offset vel, bool isBoosted) {
    double speed = vel.distance;
    double currentMax = isBoosted ? _boostedMaxSpeed : _baseMaxSpeed;
    
    if (speed < _minSpeed) {
      if (speed == 0) return Offset(_minSpeed, 0); // Safety for 0
      return vel * (_minSpeed / speed);
    } else if (speed > currentMax) {
      return vel * (currentMax / speed);
    }
    return vel;
  }
  
  void _checkPowerUpCollision() {
    if (_powerUpPos == null) return;
    
    // Check Team 1
    if (_checkCollision(_pos1, _playerSize, _powerUpPos!, _powerUpSize)) {
        _activatePowerUp(1);
    }
    // Check Team 2
    else if (_checkCollision(_pos2, _playerSize, _powerUpPos!, _powerUpSize)) {
        _activatePowerUp(2);
    }
  }
  
  bool _checkCollision(Offset p1, double s1, Offset p2, double s2) {
    // Simple AABB or Circle collision
    // Let's use Circle collision approximation for smoother feel
    Offset c1 = p1 + Offset(s1/2, s1/2);
    Offset c2 = p2 + Offset(s2/2, s2/2);
    double distance = (c1 - c2).distance;
    return distance < (s1/2 + s2/2);
  }
  
  void _activatePowerUp(int playerIdx) {
     setState(() {
       _powerUpPos = null; // Remove item
       _currentEffectTime = _totalEffectDuration;
       _activeEffectType = _itemOnGroundType;
       _effectOwner = playerIdx;
       _itemOnGroundType = 0;
       
       String typeName = _activeEffectType == 1 ? "Speed" : "Sword";
       Color color = playerIdx == 1 ? Colors.cyanAccent : Colors.redAccent;

       if (_activeEffectType == 1) {
          // Double speed immediately for physics kick
          if (playerIdx == 1) _vel1 *= 2.0;
          else _vel2 *= 2.0;
       }
       
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
            content: Text("Team $playerIdx Got $typeName!"), 
            duration: const Duration(seconds: 1), 
            backgroundColor: color
         ),
       );
     });
  }

  void _checkWallCollision(int playerIdx) {
    Offset pos = playerIdx == 1 ? _pos1 : _pos2;
    Offset vel = playerIdx == 1 ? _vel1 : _vel2;
    
    // Check Left/Right
    if (pos.dx <= 0) {
      pos = Offset(0, pos.dy);
      vel = Offset(-vel.dx, vel.dy);
    } else if (pos.dx >= _arenaSize.width - _playerSize) {
      pos = Offset(_arenaSize.width - _playerSize, pos.dy);
      vel = Offset(-vel.dx, vel.dy);
    }

    // Check Top/Bottom
    if (pos.dy <= 0) {
      pos = Offset(pos.dx, 0);
      vel = Offset(vel.dx, -vel.dy);
    } else if (pos.dy >= _arenaSize.height - _playerSize) {
      pos = Offset(pos.dx, _arenaSize.height - _playerSize);
      vel = Offset(vel.dx, -vel.dy);
    }

    // Apply back
    if (playerIdx == 1) {
      _pos1 = pos;
      _vel1 = vel;
    } else {
      _pos2 = pos;
      _vel2 = vel;
    }
  }

  void _checkPlayerCollision() {
    // Center points
    Offset c1 = _pos1 + Offset(_playerSize / 2, _playerSize / 2);
    Offset c2 = _pos2 + Offset(_playerSize / 2, _playerSize / 2);

    double dx = c2.dx - c1.dx;
    double dy = c2.dy - c1.dy;
    double distance = sqrt(dx * dx + dy * dy);

    // If collision (distance < sum of radii)
    if (distance < _playerSize) {
      // Calculate collision normal
      double nx = dx / distance;
      double ny = dy / distance;

      // Separation (prevent sticking)
      double overlap = _playerSize - distance;
      Offset separation = Offset(nx, ny) * (overlap / 2);
      
      _pos1 -= separation;
      _pos2 += separation;

      // Reflect velocities (Simple elastic collision assumption)
      // v1' = v1 - 2 * (v1 . n) * n
      // But simpler for equal mass: just swap momentum along normal or reflect?
      // Let's use standard reflection logic
      
      // Relative velocity
      Offset rv = _vel2 - _vel1;
      
      // Velocity along normal
      double velAlongNormal = rv.dx * nx + rv.dy * ny;

      // Do not resolve if velocities are separating
      if (velAlongNormal > 0) return;

      // Damage Logic (Sword)
      if (_activeEffectType == 2) { // Sword Active
         if (_effectOwner == 1) {
            _hp2 = max(0, _hp2 - 10); // Player 1 hits Player 2
         } else if (_effectOwner == 2) {
            _hp1 = max(0, _hp1 - 10); // Player 2 hits Player 1
         }
      }

      // Restitution (bounciness)
      double e = 1.0; 

      // Impulse scalar
      double j = -(1 + e) * velAlongNormal;
      j /= 2; // 1/mass1 + 1/mass2, assuming mass = 1

      // Apply impulse
      Offset impulse = Offset(nx * j, ny * j);
      
      _vel1 -= impulse;
      _vel2 += impulse;
      
      // Add a bit of randomness to avoid infinite loops in same trajectory
      _vel1 += Offset((_random.nextDouble() - 0.5) * 0.5, (_random.nextDouble() - 0.5) * 0.5);
      _vel2 += Offset((_random.nextDouble() - 0.5) * 0.5, (_random.nextDouble() - 0.5) * 0.5);
    }
  }

  void _initializePositions(Size size) {
    _arenaSize = size;
    // Initial Positions
    _pos1 = Offset(40, size.height / 2 - _playerSize / 2);
    _pos2 = Offset(size.width - 40 - _playerSize, size.height / 2 - _playerSize / 2);
    
    // Initial Velocities with Equal Speed
    const double initialSpeed = 4.0;
    
    // Random angle for player 1
    double angle1 = _random.nextDouble() * 2 * pi;
    _vel1 = Offset(cos(angle1), sin(angle1)) * initialSpeed;

    // Random angle for player 2
    double angle2 = _random.nextDouble() * 2 * pi;
    _vel2 = Offset(cos(angle2), sin(angle2)) * initialSpeed;
    
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate square size (1:1 ratio)
        // We use a smaller factor of height to ensure plenty of room for the stats below
        final double sideLength = min(constraints.maxWidth * 0.9, constraints.maxHeight * 0.55);
        
        final arenaWidth = sideLength;
        final arenaHeight = sideLength;
        final currentSize = Size(arenaWidth, arenaHeight);

        // Initialize or Update size
        if (!_initialized || _arenaSize != currentSize) {
           // If resizing, we might want to re-clamp positions but strictly strictly resetting 
           // might be jarring during resize. For this simple app, we can just init if not set,
           // or update boundaries if set.
           if (!_initialized) {
             _initializePositions(currentSize);
           } else {
             _arenaSize = currentSize;
             // Ensure they are inside
             _pos1 = Offset(min(_pos1.dx, arenaWidth - _playerSize), min(_pos1.dy, arenaHeight - _playerSize));
             _pos2 = Offset(min(_pos2.dx, arenaWidth - _playerSize), min(_pos2.dy, arenaHeight - _playerSize));
           }
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. The Arena (Blank Black with Neon Border)
              Container(
                width: arenaWidth,
                height: arenaHeight,
                decoration: BoxDecoration(
                  color: Colors.black, // Blank black
                  border: Border.all(
                    color: Colors.cyanAccent, // Neon border
                    width: 4.0,
                  ),
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Power Up Item
                    if (_powerUpPos != null)
                        Positioned(
                            left: _powerUpPos!.dx,
                            top: _powerUpPos!.dy,
                            child: Icon(
                                _itemOnGroundType == 2 ? Icons.catching_pokemon : Icons.bolt, // Use sword-like icon
                                color: _itemOnGroundType == 2 ? Colors.orangeAccent : Colors.yellow,
                                size: _powerUpSize,
                                shadows: [
                                    BoxShadow(
                                        color: (_itemOnGroundType == 2 ? Colors.orange : Colors.yellowAccent).withOpacity(0.8),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                    )
                                ],
                            ),
                        ),
                        
                    // Team 1 Player (Left - Cyan)
                    Positioned(
                      left: _pos1.dx,
                      top: _pos1.dy,
                      child: Container(
                        width: _playerSize,
                        height: _playerSize,
                        decoration: BoxDecoration(
                          // Flash white if ANY effect (Speed or Sword) is active for this player
                          color: (_activeEffectType != 0 && _effectOwner == 1) ? Colors.white : Colors.cyanAccent, 
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: ((_activeEffectType != 0 && _effectOwner == 1) ? Colors.white : Colors.cyanAccent).withOpacity(0.6),
                              blurRadius: 15,
                              spreadRadius: (_activeEffectType != 0 && _effectOwner == 1) ? 6 : 2, 
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    // Team 2 Player (Right - Red)
                    Positioned(
                      left: _pos2.dx,
                      top: _pos2.dy,
                      child: Container(
                        width: _playerSize,
                        height: _playerSize,
                        decoration: BoxDecoration(
                          color: (_activeEffectType != 0 && _effectOwner == 2) ? Colors.white : Colors.redAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: ((_activeEffectType != 0 && _effectOwner == 2) ? Colors.white : Colors.redAccent).withOpacity(0.6),
                              blurRadius: 15,
                              spreadRadius: (_activeEffectType != 0 && _effectOwner == 2) ? 6 : 2,
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),

              // 2. Team Stats (Name + HP Bar)
              SizedBox(
                width: arenaWidth, // Match arena width
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Team 1 Stats (Left)
                    Expanded(
                      child: _buildTeamStat(
                        context, 
                        widget.team1, 
                        Colors.cyanAccent, 
                        Alignment.centerLeft,
                        1, // Owner ID
                      ),
                    ),
                    const SizedBox(width: 20), // Spacer
                    // Team 2 Stats (Right)
                    Expanded(
                      child: _buildTeamStat(
                        context, 
                        widget.team2, 
                        Colors.redAccent, 
                        Alignment.centerRight,
                        2, // Owner ID
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTeamStat(
    BuildContext context, 
    String teamName, 
    Color color, 
    Alignment alignment,
    int ownerId,
  ) {
    // Check Statuses
    bool hasSpeed = (_activeEffectType == 1 && _effectOwner == ownerId);
    bool hasSword = (_activeEffectType == 2 && _effectOwner == ownerId);
    
    // Progress for bars
    double progress = (_currentEffectTime / _totalEffectDuration);
    int hp = ownerId == 1 ? _hp1 : _hp2;
    return Column(
      crossAxisAlignment: alignment == Alignment.centerLeft 
          ? CrossAxisAlignment.start 
          : CrossAxisAlignment.end,
      children: [
        // Team Name
        Text(
          teamName,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        
        // 1. Speed Info Row
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
             mainAxisSize: MainAxisSize.min,
             mainAxisAlignment: alignment == Alignment.centerLeft 
                ? MainAxisAlignment.start 
                : MainAxisAlignment.end,
             children: [
               if (alignment == Alignment.centerLeft) ...[
                 Icon(Icons.bolt, color: hasSpeed ? Colors.yellowAccent : Colors.white24, size: 16),
                 const SizedBox(width: 4),
                 SizedBox(
                   width: 120,
                   child: LinearProgressIndicator(
                     value: hasSpeed ? progress : 0.0,
                     backgroundColor: Colors.white10,
                     color: hasSpeed ? Colors.yellowAccent : Colors.grey, 
                     minHeight: 4, borderRadius: BorderRadius.circular(2),
                   ),
                 ),
               ] else ...[
                 SizedBox(
                   width: 120,
                   child: LinearProgressIndicator(
                     value: hasSpeed ? progress : 0.0,
                     backgroundColor: Colors.white10,
                     color: hasSpeed ? Colors.yellowAccent : Colors.grey, 
                     minHeight: 4, borderRadius: BorderRadius.circular(2),
                   ),
                 ),
                 const SizedBox(width: 4),
                 Icon(Icons.bolt, color: hasSpeed ? Colors.yellowAccent : Colors.white24, size: 16),
               ],
             ],
          ),
        ),

        // 2. Sword Info Row
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
             mainAxisSize: MainAxisSize.min,
             mainAxisAlignment: alignment == Alignment.centerLeft 
                ? MainAxisAlignment.start 
                : MainAxisAlignment.end,
             children: [
               if (alignment == Alignment.centerLeft) ...[
                 Icon(Icons.catching_pokemon, color: hasSword ? Colors.orangeAccent : Colors.white24, size: 16),
                 const SizedBox(width: 4),
                 SizedBox(
                   width: 120,
                   child: LinearProgressIndicator(
                     value: hasSword ? progress : 0.0,
                     backgroundColor: Colors.white10,
                     color: hasSword ? Colors.orangeAccent : Colors.grey, 
                     minHeight: 4, borderRadius: BorderRadius.circular(2),
                   ),
                 ),
               ] else ...[
                 SizedBox(
                   width: 120,
                   child: LinearProgressIndicator(
                     value: hasSword ? progress : 0.0,
                     backgroundColor: Colors.white10,
                     color: hasSword ? Colors.orangeAccent : Colors.grey, 
                     minHeight: 4, borderRadius: BorderRadius.circular(2),
                   ),
                 ),
                 const SizedBox(width: 4),
                 Icon(Icons.catching_pokemon, color: hasSword ? Colors.orangeAccent : Colors.white24, size: 16),
               ],
             ],
          ),
        ),

        const SizedBox(height: 8),
        // HP Bar Container
        Container(
          height: 12,
          width: 150, // Fixed width for bar, or could be relative
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: FractionallySizedBox(
            alignment: alignment == Alignment.centerLeft 
              ? Alignment.centerLeft 
              : Alignment.centerRight,
          widthFactor: hp / 100.0, // Dynamic HP
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.6),
                    blurRadius: 6,
                  )
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        // HP Text
        Text(
          "HP $hp/100",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
