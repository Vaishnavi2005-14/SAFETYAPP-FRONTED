import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

import 'contacts_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _tabs;
  final GlobalKey<_HomeTabState> _homeTabKey = GlobalKey<_HomeTabState>();

  @override
  void initState() {
    super.initState();
    _tabs = [
      HomeTab(key: _homeTabKey),
      const ContactsScreen(),
      const ProfileScreen(),
    ];
  }

  Widget _buildFloatingBottomNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF151233).withOpacity(0.85),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.shield_outlined, Icons.shield, 'Home'),
            _buildNavItem(1, Icons.people_outline, Icons.people, 'Contacts'),
            _buildNavItem(2, Icons.person_outline, Icons.person, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData solidIcon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        if (index == 0) {
          _homeTabKey.currentState?._initShakeDetector();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: SizedBox(
          height: 60,
          width: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isSelected ? Colors.pinkAccent.withOpacity(0.15) : Colors.transparent,
                ),
                child: Icon(
                  isSelected ? solidIcon : outlineIcon,
                  color: isSelected ? Colors.pinkAccent : Colors.white60,
                  size: 26,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white38,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D0B26), Color(0xFF151233)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IndexedStack(
              index: _selectedIndex,
              children: _tabs,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildFloatingBottomNavBar(),
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();
  late AnimationController _radarController;
  
  StreamSubscription? _shakeSubscription;
  bool _shakeEnabled = true;
  double _shakeThreshold = 25.0;
  DateTime? _lastShakeTime;

  String _gpsCoordinates = "Scanning location...";
  bool _gpsSignalActive = false;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _initGPS();
    _initShakeDetector();
  }

  @override
  void dispose() {
    _player.dispose();
    _radarController.dispose();
    _shakeSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initGPS() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        setState(() {
          _gpsCoordinates = "LAT: ${pos.latitude.toStringAsFixed(5)}  •  LNG: ${pos.longitude.toStringAsFixed(5)}";
          _gpsSignalActive = true;
        });
      } else {
        setState(() {
          _gpsCoordinates = "Location Permission Denied";
          _gpsSignalActive = false;
        });
      }
    } catch (_) {
      setState(() {
        _gpsCoordinates = "GPS connection unavailable";
        _gpsSignalActive = false;
      });
    }
  }

  Future<void> _initShakeDetector() async {
    final prefs = await SharedPreferences.getInstance();
    _shakeEnabled = prefs.getBool('profile_shake_enabled') ?? true;
    final sensitivity = prefs.getString('profile_shake_sensitivity') ?? 'Medium';
    
    if (sensitivity == 'Low') {
      _shakeThreshold = 35.0;
    } else if (sensitivity == 'High') {
      _shakeThreshold = 18.0;
    } else {
      _shakeThreshold = 25.0;
    }

    _shakeSubscription?.cancel();
    _shakeSubscription = accelerometerEvents.listen((event) {
      if (!_shakeEnabled) return;
      
      final force = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (force > _shakeThreshold) {
        final now = DateTime.now();
        if (_lastShakeTime == null || now.difference(_lastShakeTime!) > const Duration(seconds: 10)) {
          _lastShakeTime = now;
          HapticFeedback.vibrate();
          _sendSOS();
        }
      }
    });
  }

  Future<void> _playAlertSound() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/alert.mp3');
      if (!await tempFile.exists()) {
        final byteData = await rootBundle.load('assets/alert.mp3');
        await tempFile.writeAsBytes(byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ));
      }

      await _player.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.alarm,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {
              AVAudioSessionOptions.defaultToSpeaker,
            },
          ),
        ),
      );
      await _player.setVolume(1.0);
      await _player.play(DeviceFileSource(tempFile.path));
    } catch (_) {}
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw 'Location services disabled';
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw 'Location permission denied';
    }
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<List<String>> _loadPhones() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString('contacts');
    if (s == null) return [];
    final List decoded = jsonDecode(s);
    return decoded.map((e) => (e as Map)['phone'].toString()).toList();
  }

  Future<void> _sendSOS() async {
    try {
      await Permission.location.request();
      await Permission.sms.request();
      await _playAlertSound();

      final pos = await _determinePosition();
      final mapLink = 'https://www.google.com/maps?q=${pos.latitude},${pos.longitude}';
      
      final prefs = await SharedPreferences.getInstance();
      final customMsg = prefs.getString('profile_custom_message') ?? '';
      final message = customMsg.isNotEmpty
          ? '$customMsg\nMy location: $mapLink'
          : '🚨 Emergency! I need help. My location: $mapLink';

      final phones = await _loadPhones();
      if (phones.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No emergency contacts found. Add contacts first.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final allNumbers = phones.join(',');
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: allNumbers,
        queryParameters: {'body': message},
      );

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri, mode: LaunchMode.externalApplication);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SMS client launched. Tap send to dispatch alert!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not trigger SMS application')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('SOS Dispatch Error: $e')),
      );
    }
  }

  void _triggerStrobeSiren() {
    _player.setReleaseMode(ReleaseMode.loop);
    _playAlertSound();

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return _StrobeAlarmWidget(player: _player);
      },
    );
  }

  Future<void> _openPoliceHelp() async {
    try {
      final pos = await _determinePosition();
      final Uri uri = Uri.parse(
          'https://www.google.com/maps/search/police+station+near+me/@${pos.latitude},${pos.longitude},15z');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps application')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'SHTREE KAVACH',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              _buildGPSBar(),

              const SizedBox(height: 40),

              _buildRadarSOSButton(),

              const SizedBox(height: 45),

              Row(
                children: [
                  const Icon(Icons.flash_on, color: Colors.cyanAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "EMERGENCY QUICK PANEL",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.35,
                children: [
                  _buildQuickActionCard(
                    icon: Icons.volume_up,
                    glowColor: Colors.redAccent,
                    title: "Siren & Strobe",
                    subtitle: "Flashing distress alarm",
                    onTap: _triggerStrobeSiren,
                  ),
                  _buildQuickActionCard(
                    icon: Icons.phone_callback,
                    glowColor: Colors.amberAccent,
                    title: "Fake Call",
                    subtitle: "Excuse self to safety",
                    onTap: () => Navigator.pushNamed(context, '/fake_call').then((_) => _initShakeDetector()),
                  ),
                  _buildQuickActionCard(
                    icon: Icons.local_police,
                    glowColor: Colors.blueAccent,
                    title: "Police Maps",
                    subtitle: "Route near police stations",
                    onTap: _openPoliceHelp,
                  ),
                  _buildQuickActionCard(
                    icon: Icons.bolt,
                    glowColor: Colors.tealAccent,
                    title: "Instant SOS",
                    subtitle: "Immediate SMS alert",
                    onTap: _sendSOS,
                  ),
                ],
              ),
              const SizedBox(height: 110),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGPSBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            height: 10,
            width: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _gpsSignalActive ? Colors.greenAccent : Colors.amberAccent,
              boxShadow: [
                BoxShadow(
                  color: (_gpsSignalActive ? Colors.greenAccent : Colors.amberAccent).withOpacity(0.6),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _gpsCoordinates,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          IconButton(
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.refresh, color: Colors.white60, size: 18),
            onPressed: () {
              setState(() => _gpsCoordinates = "Locating GPS...");
              _initGPS();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRadarSOSButton() {
    final double radarSize = MediaQuery.of(context).size.width * 0.55;
    return GestureDetector(
      onTap: _sendSOS,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: SizedBox(
          width: radarSize,
          height: radarSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _radarController,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(radarSize, radarSize),
                    painter: RadarRipplePainter(_radarController.value),
                  );
                },
              ),
              Container(
                width: radarSize * 0.65,
                height: radarSize * 0.65,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF3366), Color(0xFFFF0033)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(0.5),
                      blurRadius: 25,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: Colors.white,
                      size: 44,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "SOS",
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required Color glowColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: glowColor.withOpacity(0.12),
              ),
              child: Icon(
                icon,
                color: glowColor,
                size: 22,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class RadarRipplePainter extends CustomPainter {
  final double animationValue;
  RadarRipplePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 3; i >= 1; i--) {
      final progress = (animationValue + i / 3.0) % 1.0;
      final radius = maxRadius * progress;
      final opacity = (1.0 - progress) * 0.35;
      final paint = Paint()
        ..color = const Color(0xFFFF0055).withOpacity(opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant RadarRipplePainter oldDelegate) => true;
}

class _StrobeAlarmWidget extends StatefulWidget {
  final AudioPlayer player;
  const _StrobeAlarmWidget({required this.player});
  @override
  State<_StrobeAlarmWidget> createState() => _StrobeAlarmWidgetState();
}

class _StrobeAlarmWidgetState extends State<_StrobeAlarmWidget> {
  bool _isRed = true;
  Timer? _strobeTimer;

  @override
  void initState() {
    super.initState();
    _strobeTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      setState(() {
        _isRed = !_isRed;
      });
    });
  }

  @override
  void dispose() {
    _strobeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isRed ? Colors.redAccent.shade700 : Colors.blue.shade900,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 100,
              ),
              const SizedBox(height: 20),
              const Text(
                "SIREN ACTIVE",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Strobe flashing active to deter threat.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 60),
              GestureDetector(
                onTap: () {
                  widget.player.stop();
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      )
                    ],
                  ),
                  child: const Text(
                    "STOP SIREN",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
