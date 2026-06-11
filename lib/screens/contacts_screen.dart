import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});
  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> with SingleTickerProviderStateMixin {
  List<Map<String, String>> contacts = [];
  late TabController _tabController;

  final List<Map<String, String>> helplineDirectory = [
    {'name': 'National Emergency', 'phone': '112', 'desc': 'All-in-one emergency response'},
    {'name': 'Women Helpline', 'phone': '1091', 'desc': 'Direct women safety helpline'},
    {'name': 'Police Control Room', 'phone': '100', 'desc': 'Immediate police assistance'},
    {'name': 'Cyber Crime Helpline', 'phone': '1930', 'desc': 'Report online harassment & fraud'},
    {'name': 'Ambulance Helpline', 'phone': '102', 'desc': 'Medical emergency assistance'},
    {'name': 'Fire Service', 'phone': '101', 'desc': 'Fire emergency services'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadContacts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString('contacts');
    if (s != null) {
      final List decoded = jsonDecode(s);
      contacts = decoded.map((e) => Map<String, String>.from(e)).toList();
    } else {
      contacts = [
        {'name': 'Police Helpline', 'phone': '100'},
        {'name': 'Women Helpline', 'phone': '1091'},
      ];
      await ApiService.saveContacts(contacts);
    }
    setState(() {});
    final synced = await ApiService.syncWithServer();
    if (synced) {
      final updatedS = prefs.getString('contacts');
      if (updatedS != null) {
        final List decoded = jsonDecode(updatedS);
        setState(() {
          contacts = decoded.map((e) => Map<String, String>.from(e)).toList();
        });
      }
    }
  }

  Future<void> _saveContacts() async {
    await ApiService.saveContacts(contacts);
  }

  Future<void> _makeCall(String phone) async {
    final Uri telUri = Uri(scheme: 'tel', path: phone);
    try {
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open phone dialer')),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error triggering phone dialer')),
      );
    }
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (context, setState) {
        bool showError = false;
        return AlertDialog(
          backgroundColor: const Color(0xFF151233),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.white12),
          ),
          title: const Text(
            'Add Guardian',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: const TextStyle(color: Colors.white60),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  errorText: showError && nameCtrl.text.trim().isEmpty ? 'Name required' : null,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: const TextStyle(color: Colors.white60),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  errorText: showError && phoneCtrl.text.trim().isEmpty ? 'Phone required' : null,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                  setState(() => showError = true);
                  return;
                }
                this.setState(() {
                  contacts.add({
                    'name': nameCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                  });
                });
                _saveContacts();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }),
    );
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF151233),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white12),
        ),
        title: const Text('Delete Contact', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to remove this guardian?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => contacts.removeAt(index));
              _saveContacts();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(Map<String, String> c, int idx) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.pinkAccent.withOpacity(0.12),
          child: Text(
            c['name']?.isNotEmpty == true ? c['name']![0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          c['name'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            c['phone'] ?? '',
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.phone, color: Colors.greenAccent),
              onPressed: () => _makeCall(c['phone'] ?? ''),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _confirmDelete(idx),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelplineCard(Map<String, String> h) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.blueAccent.withOpacity(0.12),
          child: const Icon(Icons.local_police, color: Colors.blueAccent),
        ),
        title: Text(
          h['name'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                h['phone'] ?? '',
                style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                h['desc'] ?? '',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.phone_in_talk, color: Colors.greenAccent),
          onPressed: () => _makeCall(h['phone'] ?? ''),
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
          'EMERGENCY DIRECTORY',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.pinkAccent,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: "My Guardians"),
            Tab(text: "Helplines"),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            Stack(
              children: [
                contacts.isEmpty
                    ? const Center(
                        child: Text(
                          'No custom contacts. Tap + to add guardians.',
                          style: TextStyle(fontSize: 14, color: Colors.white38),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 12, bottom: 90),
                        itemCount: contacts.length,
                        itemBuilder: (_, idx) => _buildContactCard(contacts[idx], idx),
                      ),
                Positioned(
                  bottom: 100,
                  right: 24,
                  child: FloatingActionButton(
                    onPressed: _showAddDialog,
                    backgroundColor: Colors.pinkAccent,
                    child: const Icon(Icons.add, size: 28, color: Colors.white),
                  ),
                ),
              ],
            ),
            ListView.builder(
              padding: const EdgeInsets.only(top: 12, bottom: 90),
              itemCount: helplineDirectory.length,
              itemBuilder: (_, idx) => _buildHelplineCard(helplineDirectory[idx]),
            ),
          ],
        ),
      ),
    );
  }
}
