import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class FakeCallScreen extends StatefulWidget {
  const FakeCallScreen({super.key});

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen> {
  String _callerName = "Mom ❤️";
  int _delaySeconds = 5;
  bool _isScheduled = false;
  int _countdown = 0;
  Timer? _countdownTimer;

  String _callState = 'setup'; 

  Timer? _callTimer;
  int _callDuration = 0;
  final AudioPlayer _ringtonePlayer = AudioPlayer();
  Timer? _vibrationTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _callTimer?.cancel();
    _vibrationTimer?.cancel();
    _ringtonePlayer.dispose();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _isScheduled = true;
      _countdown = _delaySeconds;
      _callState = 'waiting';
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 1) {
        timer.cancel();
        _triggerRinging();
      } else {
        setState(() {
          _countdown--;
        });
      }
    });
  }

  void _cancelScheduledCall() {
    _countdownTimer?.cancel();
    setState(() {
      _isScheduled = false;
      _callState = 'setup';
    });
  }

  Future<void> _triggerRinging() async {
    setState(() {
      _callState = 'ringing';
    });

    try {
      await _ringtonePlayer.setReleaseMode(ReleaseMode.loop);
      await _ringtonePlayer.play(AssetSource('ringtone.ogg'));
    } catch (_) {}

    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      HapticFeedback.vibrate();
    });
  }

  void _acceptCall() {
    _ringtonePlayer.stop();
    _vibrationTimer?.cancel();
    setState(() {
      _callState = 'active';
      _callDuration = 0;
    });

    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDuration++;
      });
    });
  }

  void _declineCall() {
    _ringtonePlayer.stop();
    _vibrationTimer?.cancel();
    _callTimer?.cancel();
    setState(() {
      _callState = 'setup';
      _isScheduled = false;
    });
  }

  String _formatDuration(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_callState == 'waiting') {
      return _buildWaitingScreen();
    } else if (_callState == 'ringing') {
      return _buildRingingScreen();
    } else if (_callState == 'active') {
      return _buildActiveCallScreen();
    } else {
      return _buildSetupScreen();
    }
  }

  Widget _buildSetupScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D0B26), Color(0xFF151233)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 10),
                Text(
                  "Fake Call Simulator",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.pinkAccent.withOpacity(0.5),
                        blurRadius: 10,
                      )
                    ]
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Simulate a realistic call to safely excuse yourself from unsafe or awkward situations.",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 30),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "CALLER IDENTITY",
                        style: TextStyle(
                          color: Colors.pinkAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Enter Caller Name (e.g. Mom, Dad, Boss)",
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (val) {
                          if (val.trim().isNotEmpty) {
                            _callerName = val.trim();
                          }
                        },
                        controller: TextEditingController(text: _callerName)..selection = TextSelection.fromPosition(TextPosition(offset: _callerName.length)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  "TRIGGER DELAY",
                  style: TextStyle(
                    color: Colors.pinkAccent.shade100,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDelayOption(5, "5 Sec"),
                    _buildDelayOption(10, "10 Sec"),
                    _buildDelayOption(30, "30 Sec"),
                    _buildDelayOption(60, "1 Min"),
                  ],
                ),

                const Spacer(),

                Center(
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        colors: [Colors.pinkAccent, Colors.purpleAccent],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pinkAccent.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _startCountdown,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.phone_callback_rounded, color: Colors.white),
                          SizedBox(width: 12),
                          Text(
                            "Schedule Call",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDelayOption(int sec, String label) {
    final isSelected = _delaySeconds == sec;
    return GestureDetector(
      onTap: () {
        setState(() {
          _delaySeconds = sec;
        });
      },
      child: Container(
        width: 75,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.pinkAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.pinkAccent : Colors.white.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaitingScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D0B26), Color(0xFF151233)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.hourglass_empty_rounded,
                color: Colors.pinkAccent,
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                "Triggering call in $_countdown seconds...",
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Lock your phone or remain on this screen.\nThe simulation will launch automatically.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
              const SizedBox(height: 40),
              OutlinedButton(
                onPressed: _cancelScheduledCall,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRingingScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Text(
              _callerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Incoming Call...",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                letterSpacing: 1.1,
              ),
            ),
            const Spacer(),
            Container(
              height: 130,
              width: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade900,
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: const Center(
                child: Icon(
                  Icons.person,
                  color: Colors.white54,
                  size: 70,
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 48.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      GestureDetector(
                        onTap: _declineCall,
                        child: Container(
                          height: 70,
                          width: 70,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                          ),
                          child: const Icon(
                            Icons.call_end,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Decline",
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      GestureDetector(
                        onTap: _acceptCall,
                        child: Container(
                          height: 70,
                          width: 70,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                          ),
                          child: const Icon(
                            Icons.call,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Accept",
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActiveCallScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            Text(
              _callerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDuration(_callDuration),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 40),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.0),
              child: SizedBox(
                height: 80,
                child: _AnimatedWaveform(),
              ),
            ),

            const Spacer(),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Wrap(
                spacing: 40,
                runSpacing: 24,
                alignment: WrapAlignment.center,
                children: [
                  _buildCallActionBtn(Icons.mic_off, "mute"),
                  _buildCallActionBtn(Icons.dialpad, "keypad"),
                  _buildCallActionBtn(Icons.volume_up, "speaker"),
                  _buildCallActionBtn(Icons.add, "add call"),
                  _buildCallActionBtn(Icons.videocam_off, "video"),
                  _buildCallActionBtn(Icons.contacts, "contacts"),
                ],
              ),
            ),
            
            const Spacer(),
            
            GestureDetector(
              onTap: _declineCall,
              child: Container(
                margin: const EdgeInsets.only(bottom: 40),
                height: 76,
                width: 76,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                ),
                child: const Icon(
                  Icons.call_end,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallActionBtn(IconData icon, String label) {
    return SizedBox(
      width: 76,
      child: Column(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _AnimatedWaveform extends StatefulWidget {
  const _AnimatedWaveform();
  @override
  State<_AnimatedWaveform> createState() => _AnimatedWaveformState();
}

class _AnimatedWaveformState extends State<_AnimatedWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(15, (index) {
            final double factor = (index * 0.4 + _controller.value * 2 * 3.14159);
            final double height = 15.0 + 35.0 * (0.5 + 0.5 * (index % 2 == 0 ? sin(factor) : cos(factor)));
            return Container(
              width: 5,
              height: height,
              decoration: BoxDecoration(
                color: Colors.pinkAccent.shade200.withOpacity(0.7),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        );
      },
    );
  }
}
