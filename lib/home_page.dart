import 'package:flutter/material.dart';
import 'game_arena.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // List of European football clubs
  final List<String> clubs = [
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

  String? selectedTeam1;
  String? selectedTeam2;

  void _startGame() {
    if (selectedTeam1 != null && selectedTeam2 != null) {
      if (selectedTeam1 == selectedTeam2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select different teams!"),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text("Match Day"),
              backgroundColor: Colors.transparent, 
              foregroundColor: Colors.white,
            ),
            backgroundColor: const Color(0xFF1A1A2E),
            body: GameArena(
              team1: selectedTeam1!,
              team2: selectedTeam2!,
            ),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select both teams!"),
          backgroundColor: Colors.orangeAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.sports_soccer,
                size: 100,
                color: Colors.cyanAccent,
              ),
              const SizedBox(height: 30),
              const Text(
                "SELECT TEAMS",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 50),
              // Team 1 Dropdown
              _buildDropdown(
                label: "Team 1 (Home)",
                value: selectedTeam1,
                onChanged: (value) {
                  setState(() {
                    selectedTeam1 = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              const Text(
                "VS",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),
              // Team 2 Dropdown
              _buildDropdown(
                label: "Team 2 (Away)",
                value: selectedTeam2,
                onChanged: (value) {
                  setState(() {
                    selectedTeam2 = value;
                  });
                },
              ),
              const SizedBox(height: 60),
              // Start Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                    shadowColor: Colors.cyanAccent.withOpacity(0.5),
                  ),
                  child: const Text(
                    "START GAME",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF252540),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.cyanAccent),
              hint: const Text(
                "Select a club",
                style: TextStyle(color: Colors.white38),
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              items: clubs.map((String club) {
                return DropdownMenuItem<String>(
                  value: club,
                  child: Text(club),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
