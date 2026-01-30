import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authService = AuthService();
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Form fields
  final _nameController = TextEditingController();
  final _avatarController = TextEditingController();
  String? _email;
  // ignore: unused_field
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final data = await _authService.getProfile();
      setState(() {
        _nameController.text = data['name'] ?? '';
        _avatarController.text = data['avatar_url'] ?? '';
        _email = data['email'];
        _userId = data['id'];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading profile: $e"), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await _authService.updateProfile(
        _nameController.text,
        _avatarController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Go back after saving
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating profile: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _avatarController.dispose();
    super.dispose();
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                   // Avatar Preview
                   Center(
                     child: Stack(
                       children: [
                         Container(
                           width: 120,
                           height: 120,
                           decoration: BoxDecoration(
                             color: Colors.white10,
                             shape: BoxShape.circle,
                             border: Border.all(color: Colors.cyanAccent, width: 2),
                             image: _avatarController.text.isNotEmpty
                                 ? DecorationImage(
                                     image: NetworkImage(_avatarController.text),
                                     fit: BoxFit.cover,
                                     onError: (_, __) {}, // Handle error silently
                                   )
                                 : null,
                           ),
                           child: _avatarController.text.isEmpty
                               ? const Icon(Icons.person, size: 60, color: Colors.white54)
                               : null,
                         ),
                       ],
                     ),
                   ),
                   const SizedBox(height: 30),
                   
                   // Email (Read Only)
                   _buildTextField("Email", _email ?? "Loading...", enabled: false),
                   const SizedBox(height: 20),
                   
                   // Name
                   _buildTextField("Full Name", "Enter your name", controller: _nameController),
                   const SizedBox(height: 20),
                   
                   // Avatar URL
                   _buildTextField("Avatar URL", "https://example.com/image.jpg", controller: _avatarController),
                   
                   const SizedBox(height: 40),
                   
                   // Save Button
                   SizedBox(
                     width: double.infinity,
                     height: 50,
                     child: ElevatedButton(
                       onPressed: _isSaving ? null : _saveProfile,
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.cyanAccent,
                         foregroundColor: Colors.black,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                       ),
                       child: _isSaving
                           ? const SizedBox(
                               width: 24, 
                               height: 24, 
                               child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)
                             )
                           : const Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                     ),
                   )
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(String label, String placeholder, {TextEditingController? controller, bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFF252540) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: const TextStyle(color: Colors.white24),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: (value) {
              if (controller == _avatarController) {
                setState(() {}); // Rebuild to update avatar preview
              }
            },
          ),
        ),
      ],
    );
  }
}
