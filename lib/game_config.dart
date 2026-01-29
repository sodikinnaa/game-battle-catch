class GameConfig {
  // Game Physics & Loop Constants
  static const double playerSize = 50.0;
  static const double minSpeed = 2.0;
  static const double baseMaxSpeed = 8.0;
  static const double boostedMaxSpeed = 16.0;
  static const double powerUpSize = 40.0;
  static const double totalEffectDuration = 5.0; // Seconds
  static const int initialHp = 100;
  static const int damage = 10;

  // Power Up Types
  static const int powerUpNone = 0;
  static const int powerUpSpeed = 1;
  static const int powerUpSword = 2;
  static const int powerUpShield = 3;

  // Spawning Probability
  static const double dualSpawnChance = 0.20;
  static const double lightningSpawnChance = 0.45; // Increase lightning chance
  
  // Spawning Intervals (Seconds)
  static const int minSpawnTime = 5; 
  static const int maxSpawnTime = 12;

  // List of European football clubs
  static const List<String> clubs = [
    "Real Madrid",
    "Barcelona",
    "Manchester United",
    "Liverpool",
    "Manchester City",
    "Arsenal",
    "Chelsea",
    "Bayern Munich",
    "Borussia Dortmund",
    "Paris Saint-Germain",
    "Juventus",
    "AC Milan",
    "Inter Milan",
    "Ajax",
    "Atletico Madrid",
  ];
}
