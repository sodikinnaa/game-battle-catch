import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class TeamSetupPage extends StatefulWidget {
  const TeamSetupPage({super.key});

  @override
  State<TeamSetupPage> createState() => _TeamSetupPageState();
}

class _TeamSetupPageState extends State<TeamSetupPage> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  List<dynamic> _teams = [];
  List<dynamic> _avatars = [];
  bool _isLoading = true;
  bool _isSaving = false;

  bool _isEditing = false;

  String? _selectedTeamId;
  String? _selectedAvatarId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Run requests in parallel
      final results = await Future.wait([
        _authService.getTeams(),
        _authService.getAvatars(),
        _authService.getUserTeam(),
      ]);

      final teams = results[0] as List<dynamic>;
      final avatars = results[1] as List<dynamic>;
      final userTeam = results[2] as Map<String, dynamic>?;
      
      setState(() {
        _teams = teams;
        _avatars = avatars;
        
        // Pre-fill if editing
        if (userTeam != null) {
          _isEditing = true;
          _nameController.text = userTeam['custom_name'] ?? '';
          _selectedTeamId = userTeam['team_id'];
          _selectedAvatarId = userTeam['avatar_id'];
        }
        
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading data: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveTeam() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTeamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a base team"), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_selectedAvatarId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a manager avatar"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _authService.saveUserTeam(
        _selectedTeamId!,
        _selectedAvatarId!,
        _nameController.text,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Team created successfully!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving team: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(_isEditing ? "Manage Your Team" : "Create Your Team", style: const TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Team Name
                    const Text("1. Name Your Team", style: TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "e.g. The Invincibles",
                        hintStyle: const TextStyle(color: Colors.white24),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Please enter a team name";
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    // 2. Select Base Team
                    const Text("2. Choose Badge (Base Team)", style: TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _teams.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final team = _teams[index];
                          final isSelected = _selectedTeamId == team['id'];
                          return GestureDetector(
                            onTap: () => setState(() => _selectedTeamId = team['id']),
                            child: Container(
                              width: 80,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.cyanAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? Colors.cyanAccent : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Image.network(team['icon_url'], fit: BoxFit.contain),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    team['name'],
                                    style: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontSize: 10),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 30),

                    // 3. Select Avatar
                    const Text("3. Choose Manager Avatar", style: TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _avatars.length,
                      itemBuilder: (context, index) {
                        final avatar = _avatars[index];
                        final isSelected = _selectedAvatarId == avatar['id'];
                        return GestureDetector(
                          onTap: () => setState(() => _selectedAvatarId = avatar['id']),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.purpleAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? Colors.purpleAccent : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                Expanded(
                                  child: CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.transparent,
                                    backgroundImage: NetworkImage(avatar['image_url'].toString().replaceAll('.svg', '.png')),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  avatar['name'],
                                  style: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontSize: 10),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),
                    
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveTeam,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.black)
                            : Text(_isEditing ? "Update Team" : "Create Team", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
