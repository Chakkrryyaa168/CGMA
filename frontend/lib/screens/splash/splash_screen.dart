import 'dart:async';
import 'package:flutter/material.dart';
import '../../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  double _progressValue = 0.0;
  Timer? _progressTimer;
  Timer? _navigationTimer;
  String _statusMessage = 'Initializing Garage Engine...';

  final List<String> _loadingMessages = [
    'Initializing Garage Engine...',
    'Loading Diagnostics & Inventory...',
    'Connecting Security Gateways...',
    'Fetching Active Work Orders...',
    'Preparing Premium Service Portal...',
    'Ready to Roll!',
  ];

  @override
  void initState() {
    super.initState();

    // Pulse / Scale Logo Animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // 7-second progress bar timer (updates every 70ms = 100 steps over 7000ms)
    _progressTimer = Timer.periodic(const Duration(milliseconds: 70), (timer) {
      if (mounted) {
        setState(() {
          _progressValue += 0.01;
          if (_progressValue > 1.0) _progressValue = 1.0;

          // Update status message based on progress percentage
          int msgIndex = ((_progressValue * (_loadingMessages.length - 1))).floor();
          if (msgIndex >= 0 && msgIndex < _loadingMessages.length) {
            _statusMessage = _loadingMessages[msgIndex];
          }
        });
      }
    });

    // 7-second navigation timer
    _navigationTimer = Timer(const Duration(seconds: 7), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const AppLandingGate(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressTimer?.cancel();
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121214),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Animated Pulsing Vroom Logo Icon
              ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC700),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFC700).withValues(alpha: 0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.directions_car_rounded,
                      color: Color(0xFF121214),
                      size: 64,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Title Branding
              const Text(
                'VROOM GARAGE',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'PREMIUM CAR CARE & MANAGEMENT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: Color(0xFFFFC700),
                ),
              ),

              const Spacer(),

              // Progress Bar & Status Text
              Column(
                children: [
                  // Smooth Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      height: 8,
                      child: LinearProgressIndicator(
                        value: _progressValue,
                        backgroundColor: const Color(0xFF27272A),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFC700)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _statusMessage,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${(_progressValue * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFFFC700),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
