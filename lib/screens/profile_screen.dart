import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _phone = TextEditingController();
  final _aadhaar = TextEditingController();
  final _customMessage = TextEditingController();

  bool _editing = false;
  bool _shakeEnabled = true;
  String _shakeSensitivity = 'Medium';
  int _guardianCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _phone.dispose();
    _aadhaar.dispose();
    _customMessage.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF151233),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white12),
        ),
        title: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () async {
              await ApiService.clearSession();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name.text = prefs.getString('profile_name') ?? '';
      _age.text = prefs.getString('profile_age') ?? '';
      _phone.text = prefs.getString('profile_phone') ?? '';
      _aadhaar.text = prefs.getString('profile_aadhaar') ?? '';
      _customMessage.text = prefs.getString('profile_custom_message') ?? '🚨 Emergency! I need help immediately. My location:';
      _shakeEnabled = prefs.getBool('profile_shake_enabled') ?? true;
      _shakeSensitivity = prefs.getString('profile_shake_sensitivity') ?? 'Medium';

      final s = prefs.getString('contacts');
      if (s != null) {
        try {
          final parts = s.split('phone');
          _guardianCount = parts.length - 1;
        } catch (_) {
          _guardianCount = 0;
        }
      } else {
        _guardianCount = 2;
      }
    });

    final synced = await ApiService.syncWithServer();
    if (synced && mounted) {
      setState(() {
        _name.text = prefs.getString('profile_name') ?? '';
        _age.text = prefs.getString('profile_age') ?? '';
        _phone.text = prefs.getString('profile_phone') ?? '';
        _aadhaar.text = prefs.getString('profile_aadhaar') ?? '';
        _customMessage.text = prefs.getString('profile_custom_message') ?? '';
        _shakeEnabled = prefs.getBool('profile_shake_enabled') ?? true;
        _shakeSensitivity = prefs.getString('profile_shake_sensitivity') ?? 'Medium';

        final s = prefs.getString('contacts');
        if (s != null) {
          try {
            final parts = s.split('phone');
            _guardianCount = parts.length - 1;
          } catch (_) {
            _guardianCount = 0;
          }
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    final name = _name.text.trim();
    final age = _age.text.trim();
    final phone = _phone.text.trim();
    final aadhaar = _aadhaar.text.trim();
    final customMsg = _customMessage.text.trim();

    if (name.isEmpty || age.isEmpty || phone.isEmpty || aadhaar.isEmpty || customMsg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all profile fields and SOS message!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final success = await ApiService.saveProfile(
      name: name,
      age: age,
      phone: phone,
      aadhaar: aadhaar,
      customMessage: customMsg,
      shakeEnabled: _shakeEnabled,
      shakeSensitivity: _shakeSensitivity,
    );

    setState(() => _editing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success 
            ? 'Profile and settings updated successfully!' 
            : 'Saved locally. Sync with server failed.'),
        backgroundColor: success ? Colors.green : Colors.orangeAccent,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        enabled: _editing,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white60, fontWeight: FontWeight.w500),
          filled: true,
          fillColor: Colors.white.withOpacity(0.04),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.pinkAccent, width: 1.5),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'PROFILE & SETTINGS',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(_editing ? Icons.check_circle : Icons.edit, color: Colors.pinkAccent, size: 28),
            onPressed: () {
              if (_editing) {
                _saveProfile();
              } else {
                setState(() => _editing = true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent, size: 26),
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 12.0, bottom: 100.0),
          child: Column(
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pinkAccent.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      )
                    ],
                    gradient: const LinearGradient(
                      colors: [Colors.pinkAccent, Colors.purpleAccent],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 54,
                    backgroundImage: const AssetImage('assets/logo.jpg'),
                    backgroundColor: Colors.grey.shade900,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatCard("Shield Status", "ACTIVE", Colors.greenAccent),
                  _buildStatCard("Guardians", "$_guardianCount Saving", Colors.cyanAccent),
                ],
              ),
              const SizedBox(height: 20),

              _buildSectionHeader("PERSONAL PROFILE"),
              _buildTextField(label: 'Full Name', controller: _name),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Age',
                      controller: _age,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      label: 'Phone',
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              _buildTextField(
                label: 'Aadhaar Card Number',
                controller: _aadhaar,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 24),

              _buildSectionHeader("EMERGENCY CONFIGURATION"),
              _buildTextField(
                label: 'Custom SOS Message Prefix',
                controller: _customMessage,
                maxLines: 2,
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Shake to SOS Trigger",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Trigger emergency warning on shake",
                              style: TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                          ],
                        ),
                        Switch(
                          value: _shakeEnabled,
                          activeColor: Colors.pinkAccent,
                          onChanged: _editing
                              ? (val) {
                                  setState(() {
                                    _shakeEnabled = val;
                                  });
                                }
                              : null,
                        ),
                      ],
                    ),
                    if (_shakeEnabled) ...[
                      const Divider(color: Colors.white12, height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Shake Sensitivity",
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          _editing
                              ? DropdownButton<String>(
                                  dropdownColor: const Color(0xFF151233),
                                  value: _shakeSensitivity,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  underline: Container(),
                                  items: ['Low', 'Medium', 'High'].map((String val) {
                                    return DropdownMenuItem<String>(
                                      value: val,
                                      child: Text(val),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _shakeSensitivity = val;
                                      });
                                    }
                                  },
                                )
                              : Text(
                                  _shakeSensitivity,
                                  style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                                ),
                        ],
                      ),
                    ]
                  ],
                ),
              ),

              const SizedBox(height: 32),
              Text(
                'Stay safe, stay empowered 💖',
                style: TextStyle(
                  color: Colors.pinkAccent.shade100,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0, top: 16.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: Colors.pinkAccent.shade100,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
