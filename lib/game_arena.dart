import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'game_config.dart';
import 'logic/game_engine.dart';

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
  final GameEngine _engine = GameEngine();
  
  Timer? _powerUpSpawnTimer;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
    
    // Setup Callbacks
    _engine.onGameOver = _handleGameOver;
    _engine.onPowerUpCollected = (team, type) {
       String typeName = type == 1 ? "Speed" : type == 2 ? "Sword" : "Shield";
       Color color = team == 1 ? Colors.cyanAccent : Colors.redAccent;
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
            content: Text("Team $team Got $typeName!"), 
            duration: const Duration(seconds: 1), 
            backgroundColor: color
         ),
       );
    };

    _scheduleNextPowerUp();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _powerUpSpawnTimer?.cancel();
    super.dispose();
  }
  
  void _scheduleNextPowerUp() {
    // Random interval between Min and Max
    int range = GameConfig.maxSpawnTime - GameConfig.minSpawnTime;
    int duration = GameConfig.minSpawnTime + Random().nextInt(range + 1); 
    _powerUpSpawnTimer = Timer(Duration(seconds: duration), _spawnPowerUp);
  }
  
  void _spawnPowerUp() {
    setState(() {
       _engine.spawnPowerUp();
    });
    _scheduleNextPowerUp();
  }

  void _tick(Duration elapsed) {
    if (!_initialized || _arenaSize == Size.zero) return;
    
    setState(() {
        // Approximate dt (16ms)
        _engine.update(0.016);
    });
  }

  void _handleGameOver(int winnerIdx) {
    String winnerName = winnerIdx == 1 ? widget.team1 : widget.team2;
    Color winnerColor = winnerIdx == 1 ? Colors.cyanAccent : Colors.redAccent;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
            side: BorderSide(color: winnerColor, width: 3),
            borderRadius: BorderRadius.circular(20)
        ),
        title: const Center(child: Text("GAME OVER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                Icon(Icons.emoji_events, color: winnerColor, size: 60),
                const SizedBox(height: 20),
                Text("$winnerName WINS!", style: TextStyle(color: winnerColor, fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ]
        ),
        actions: [
            TextButton(
                onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back to home
                },
                child: const Text("BACK TO HOME", style: TextStyle(color: Colors.white))
            ),
             TextButton(
                onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    _resetGame();
                },
                child: Text("RESTART", style: TextStyle(color: winnerColor))
            )
        ]
      ),
    );
  }

  void _resetGame() {
    setState(() {
        _engine.initialize(_arenaSize);
        _scheduleNextPowerUp();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate arena size - make it taller (rectangular)
        // Width is based on screen constraints
        final double arenaWidth = min(constraints.maxWidth * 0.9, constraints.maxHeight * 0.45);
        // Height is 1.3x the width for a taller arena
        final double arenaHeight = arenaWidth * 1.3;
        final currentSize = Size(arenaWidth, arenaHeight);

        // Initialize or Update size
        if (!_initialized || _arenaSize != currentSize) {
           // If resizing, we might want to re-clamp positions but strictly strictly resetting 
           // might be jarring during resize. For this simple app, we can just init if not set,
           // or update boundaries if set.
           if (!_initialized) {
             _engine.initialize(currentSize);
             _arenaSize = currentSize;
             _initialized = true;
           } else {
             _arenaSize = currentSize;
             _engine.arenaSize = currentSize;
             // _engine.initialize(currentSize); // Or a resize method if we want to smooth transition
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
                    // Power Up Items
                    ..._engine.spawnedItems.map((item) {
                       int type = item['type'];
                       Offset pos = item['pos'];
                       return Positioned(
                            left: pos.dx,
                            top: pos.dy,
                            child: Icon(
                                type == 1 ? Icons.bolt 
                                : type == 2 ? Icons.catching_pokemon 
                                : Icons.shield,
                                
                                color: type == 1 ? Colors.yellow 
                                : type == 2 ? Colors.orangeAccent 
                                : Colors.greenAccent,
                                
                                size: GameConfig.powerUpSize,
                                shadows: [
                                    BoxShadow(
                                        color: (type == 1 ? Colors.yellowAccent 
                                              : type == 2 ? Colors.orange 
                                              : Colors.green).withOpacity(0.8),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                    )
                                ],
                            ),
                        );
                    }),
                        
                    // Team 1 Player (Left - Cyan)
                    Positioned(
                      left: _engine.pos1.dx,
                      top: _engine.pos1.dy,
                      child: Container(
                        width: GameConfig.playerSize,
                        height: GameConfig.playerSize,
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent, // Always team color
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_engine.shieldTime1 > 0) ? Colors.greenAccent // Shield Priority
                                   : (_engine.swordTime1 > 0 && _engine.speedTime1 > 0) ? Colors.white 
                                   : (_engine.swordTime1 > 0) ? Colors.orangeAccent 
                                   : (_engine.speedTime1 > 0) ? Colors.yellowAccent 
                                   : Colors.cyanAccent.withOpacity(0.6), 
                              blurRadius: (_engine.speedTime1 > 0 || _engine.swordTime1 > 0 || _engine.shieldTime1 > 0) ? 20 : 15,
                              spreadRadius: (_engine.speedTime1 > 0 || _engine.swordTime1 > 0 || _engine.shieldTime1 > 0) ? 4 : 2, 
                            ),
                          ],
                          border: Border.all(
                            color: (_engine.shieldTime1 > 0) ? Colors.greenAccent
                                 : (_engine.swordTime1 > 0 && _engine.speedTime1 > 0) ? Colors.white
                                 : (_engine.swordTime1 > 0) ? Colors.orangeAccent
                                 : (_engine.speedTime1 > 0) ? Colors.yellowAccent
                                 : Colors.white,
                            width: (_engine.speedTime1 > 0 || _engine.swordTime1 > 0 || _engine.shieldTime1 > 0) ? 4 : 2,
                          ),
                        ),
                      ),
                    ),
                    // Team 2 Player (Right - Red)
                    Positioned(
                      left: _engine.pos2.dx,
                      top: _engine.pos2.dy,
                      child: Container(
                        width: GameConfig.playerSize,
                        height: GameConfig.playerSize,
                        decoration: BoxDecoration(
                          color: Colors.redAccent, // Always team color
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_engine.shieldTime2 > 0) ? Colors.greenAccent 
                                   : (_engine.swordTime2 > 0 && _engine.speedTime2 > 0) ? Colors.white 
                                   : (_engine.swordTime2 > 0) ? Colors.orangeAccent 
                                   : (_engine.speedTime2 > 0) ? Colors.yellowAccent 
                                   : Colors.redAccent.withOpacity(0.6), 
                              blurRadius: (_engine.speedTime2 > 0 || _engine.swordTime2 > 0 || _engine.shieldTime2 > 0) ? 20 : 15,
                              spreadRadius: (_engine.speedTime2 > 0 || _engine.swordTime2 > 0 || _engine.shieldTime2 > 0) ? 4 : 2,
                            ),
                          ],
                          border: Border.all(
                            color: (_engine.shieldTime2 > 0) ? Colors.greenAccent
                                 : (_engine.swordTime2 > 0 && _engine.speedTime2 > 0) ? Colors.white
                                 : (_engine.swordTime2 > 0) ? Colors.orangeAccent
                                 : (_engine.speedTime2 > 0) ? Colors.yellowAccent
                                 : Colors.white,
                            width: (_engine.speedTime2 > 0 || _engine.swordTime2 > 0 || _engine.shieldTime2 > 0) ? 4 : 2,
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
    bool hasSpeed = ownerId == 1 ? _engine.speedTime1 > 0 : _engine.speedTime2 > 0;
    bool hasSword = ownerId == 1 ? _engine.swordTime1 > 0 : _engine.swordTime2 > 0;
    bool hasShield = ownerId == 1 ? _engine.shieldTime1 > 0 : _engine.shieldTime2 > 0;
    
    // Progress for bars (Use specific timer)
    double speedProgress = (ownerId == 1 ? _engine.speedTime1 : _engine.speedTime2) / GameConfig.totalEffectDuration;
    double swordProgress = (ownerId == 1 ? _engine.swordTime1 : _engine.swordTime2) / GameConfig.totalEffectDuration;
    double shieldProgress = (ownerId == 1 ? _engine.shieldTime1 : _engine.shieldTime2) / GameConfig.totalEffectDuration;
    
    int hp = ownerId == 1 ? _engine.hp1 : _engine.hp2;
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
                     value: hasSpeed ? speedProgress : 0.0,
                     backgroundColor: Colors.white10,
                     color: hasSpeed ? Colors.yellowAccent : Colors.grey, 
                     minHeight: 4, borderRadius: BorderRadius.circular(2),
                   ),
                 ),
               ] else ...[
                 SizedBox(
                   width: 120,
                   child: LinearProgressIndicator(
                     value: hasSpeed ? speedProgress : 0.0,
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
                     value: hasSword ? swordProgress : 0.0,
                     backgroundColor: Colors.white10,
                     color: hasSword ? Colors.orangeAccent : Colors.grey, 
                     minHeight: 4, borderRadius: BorderRadius.circular(2),
                   ),
                 ),
               ] else ...[
                 SizedBox(
                   width: 120,
                   child: LinearProgressIndicator(
                     value: hasSword ? swordProgress : 0.0,
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

        // 3. Shield Info Row
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
             mainAxisSize: MainAxisSize.min,
             mainAxisAlignment: alignment == Alignment.centerLeft 
                ? MainAxisAlignment.start 
                : MainAxisAlignment.end,
             children: [
               if (alignment == Alignment.centerLeft) ...[
                 Icon(Icons.shield, color: hasShield ? Colors.greenAccent : Colors.white24, size: 16),
                 const SizedBox(width: 4),
                 SizedBox(
                   width: 120,
                   child: LinearProgressIndicator(
                     value: hasShield ? shieldProgress : 0.0,
                     backgroundColor: Colors.white10,
                     color: hasShield ? Colors.greenAccent : Colors.grey, 
                     minHeight: 4, borderRadius: BorderRadius.circular(2),
                   ),
                 ),
               ] else ...[
                 SizedBox(
                   width: 120,
                   child: LinearProgressIndicator(
                     value: hasShield ? shieldProgress : 0.0,
                     backgroundColor: Colors.white10,
                     color: hasShield ? Colors.greenAccent : Colors.grey, 
                     minHeight: 4, borderRadius: BorderRadius.circular(2),
                   ),
                 ),
                 const SizedBox(width: 4),
                 Icon(Icons.shield, color: hasShield ? Colors.greenAccent : Colors.white24, size: 16),
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
