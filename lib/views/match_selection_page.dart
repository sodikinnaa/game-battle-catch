import 'package:flutter/material.dart';
import 'game_arena.dart';
import '../services/auth_service.dart';
import '../utils/game_config.dart';

class MatchSelectionPage extends StatefulWidget {
  const MatchSelectionPage({super.key});

  @override
  State<MatchSelectionPage> createState() => _MatchSelectionPageState();
}

class _MatchSelectionPageState extends State<MatchSelectionPage> {
  List<Map<String, dynamic>> teams = [];
  bool isLoading = true;
  final AuthService _authService = AuthService();

  String? selectedTeam1;
  String? selectedTeam2;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    try {
      final teamsData = await _authService.getTeams();
      
      if (mounted) {
        setState(() {
          // Cast the list of dynamic to list of maps
          teams = List<Map<String, dynamic>>.from(teamsData);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error loading teams: $e')),
        );
        setState(() {
          isLoading = false;
        });
      }
    }
  }

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

      // a. Find the full team objects
      final team1Obj = teams.firstWhere((t) => t['name'] == selectedTeam1, orElse: () => {});
      final team2Obj = teams.firstWhere((t) => t['name'] == selectedTeam2, orElse: () => {});

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
              team1IconUrl: team1Obj['icon_url'],
              team2IconUrl: team2Obj['icon_url'],
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. Icon / Logo
                const Icon(
                  Icons.sports_soccer,
                  size: 80,
                  color: Colors.cyanAccent,
                ),
                const SizedBox(height: 20),

                // 2. Headline
                const Text(
                  "Cuma Satu yang Bertahan:\nBiru atau Merah?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                
                // 3. Subheadline
                const Text(
                  "Pilih jagoanmu, duduk santai, dan biarkan nasib yang menentukan.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
                
                const SizedBox(height: 40),

                // 4. Team Selection Area
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                       _buildDropdown(
                        label: "Jagoan 1 (Kandang)",
                        value: selectedTeam1,
                        onChanged: (value) {
                          setState(() {
                            selectedTeam1 = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Divider(color: Colors.white.withOpacity(0.1), thickness: 2),
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A2E), // Match background
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.cyanAccent.withOpacity(0.5), 
                                width: 2
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                "VS",
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: 1.5,
                                  shadows: [
                                    Shadow(
                                      color: Colors.redAccent.withOpacity(0.5),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildDropdown(
                        label: "Jagoan 2 (Tandang)",
                        value: selectedTeam2,
                        onChanged: (value) {
                          setState(() {
                            selectedTeam2 = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),

                // 5. CTA Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _startGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 8,
                      shadowColor: Colors.cyanAccent.withOpacity(0.4),
                    ),
                    child: const Text(
                      "MULAI PERTARUNGAN ⚔️",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // 6. Value Propositions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildValueProp("Tonton Tanpa Ribet", "Gak perlu skill, cuma butuh insting milih pemenang."),
                    _buildValueProp("Cepat & Seru", "Match 2 menit yang penuh kejutan dan drama."),
                    _buildValueProp("Full Acak", "Skill cloning, petir, dan pedang bisa muncul kapan aja."),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildValueProp(String title, String desc) {
     return Padding(
       padding: const EdgeInsets.symmetric(vertical: 4),
       child: Row(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           const Icon(Icons.check_circle_outline, size: 18, color: Colors.cyanAccent),
           const SizedBox(width: 8),
           Expanded(
              child: RichText(text: TextSpan(
                  style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
                  children: [
                      TextSpan(text: "$title: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      TextSpan(text: desc),
                  ]
              ))
           )
         ]
       )
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
              items: teams.map((Map<String, dynamic> team) {
                return DropdownMenuItem<String>(
                  value: team['name'],
                  child: Row(
                    children: [
                      if (team['icon_url'] != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: CircleAvatar(
                            radius: 12,
                            backgroundImage: NetworkImage(team['icon_url']),
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                      Text(team['name']),
                    ],
                  ),
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
