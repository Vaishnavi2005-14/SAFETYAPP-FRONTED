import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _textGlowController;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _rotationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat();

    _pulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);

    _textGlowController =
        AnimationController(vsync: this, duration: const Duration(seconds: 15))
          ..repeat();

    final random = Random();
    _particles = List.generate(40, (index) {
      return _Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        speed: 0.02 + random.nextDouble() * 0.03,
        size: 1.5 + random.nextDouble() * 2.5,
        opacity: 0.1 + random.nextDouble() * 0.5,
      );
    });

    Timer(const Duration(seconds: 5), () async {
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('jwt_token');
        if (token != null && token.isNotEmpty) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _textGlowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF070517),
                    Color(0xFF0F0C2A),
                    Color(0xFF19133F)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _textGlowController,
              builder: (context, child) {
                for (var p in _particles) {
                  p.y -= p.speed * 0.01;
                  if (p.y < 0) {
                    p.y = 1.0;
                    p.x = Random().nextDouble();
                  }
                }
                return CustomPaint(
                  painter: _ParticlePainter(_particles),
                );
              },
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation:
                      Listenable.merge([_pulseController, _rotationController]),
                  builder: (context, child) {
                    final double pulse = _pulseController.value;
                    return Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pinkAccent.withOpacity(0.4 * pulse),
                            blurRadius: 20 + (25 * pulse),
                            spreadRadius: 2 + (5 * pulse),
                          ),
                          BoxShadow(
                            color: Colors.purpleAccent
                                .withOpacity(0.3 * (1 - pulse)),
                            blurRadius: 15 + (20 * (1 - pulse)),
                            spreadRadius: 1 + (3 * (1 - pulse)),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.rotate(
                            angle: _rotationController.value * 2 * pi,
                            child: Container(
                              width: 148,
                              height: 148,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.pinkAccent,
                                    Colors.purpleAccent,
                                    Colors.cyanAccent
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: Image.asset(
                              'assets/logo.jpg',
                              height: 140,
                              width: 140,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final double glowVal = _pulseController.value;
                    return Column(
                      children: [
                        Text(
                          "SHTREE KAVACH",
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.pinkAccent.withOpacity(0.8),
                                blurRadius: 10 + 10 * glowVal,
                                offset: const Offset(0, 0),
                              ),
                              Shadow(
                                color: Colors.cyanAccent.withOpacity(0.6),
                                blurRadius: 20 + 5 * glowVal,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "YOUR RADAR SHIELD OF SAFETY",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color:
                                Colors.white.withOpacity(0.6 + 0.3 * glowVal),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 50),
                SizedBox(
                  width: 45,
                  height: 45,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.pinkAccent.shade200),
                    backgroundColor: Colors.white10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Particle {
  double x;
  double y;
  final double speed;
  final double size;
  final double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var p in particles) {
      paint.color = Colors.white.withOpacity(p.opacity);
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
