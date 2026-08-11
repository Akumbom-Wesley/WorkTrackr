import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulse1;
  late Animation<double> _pulse2;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<String> _statuses = [
    'INITIALIZING SYSTEMS...',
    'VERIFYING BIOMETRICS...',
    'ESTABLISHING SECURE CONNECTION...',
    'SYNCING DATA...',
    'SYSTEM READY',
  ];
  int _statusIndex = 0;
  int _percent = 0;
  Timer? _statusTimer;
  Timer? _percentTimer;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startLoadingSequence();
    // checkStoredSession called in navigation block
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _pulse1 = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOut,
    );
    _pulse2 = CurvedAnimation(
      parent: _pulseController,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOut,
      ),
    );
    _progressController.forward();
  }

  void _startLoadingSequence() {
    _statusTimer = Timer.periodic(
      const Duration(milliseconds: 800),
      (timer) {
        if (!mounted) return;
        if (_statusIndex < _statuses.length - 1) {
          setState(() => _statusIndex++);
        } else {
          timer.cancel();
        }
      },
    );

    _percentTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) {
        if (!mounted) return;
        if (_percent >= 100) {
          timer.cancel();
          Future.delayed(const Duration(milliseconds: 600), () async {
            if (!mounted) return;
            await ref.read(authProvider.notifier).checkStoredSession();
            if (!mounted) return;
            final authState = ref.read(authProvider);
            if (authState.status == AuthStatus.authenticated) {
              final role = authState.user?.role;
              if (role == 'HR_ADMIN') {
                context.go(AppRoutes.hrDashboard);
              } else {
                context.go(AppRoutes.employeeDashboard);
              }
            } else {
              context.go(AppRoutes.login);
            }
          });
          return;
        }
        setState(() {
          _percent =
              (_percent + (1 + (_percent < 80 ? 3 : 1))).clamp(0, 100);
        });
      },
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    _statusTimer?.cancel();
    _percentTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: Stack(
        children: [
          CustomPaint(
            painter: _CyberGridPainter(),
            size: Size.infinite,
          ),
          Center(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Theme.of(context).colorScheme.onTertiaryContainer.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: _fadeAnimation,
            child: SafeArea(
              child: Column(
                children: [
                  const Spacer(),
                  _buildLogoArea(),
                  const Spacer(),
                  _buildLoadingArea(),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoArea() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulse1,
                builder: (context, _) => _buildPulseRing(_pulse1.value),
              ),
              AnimatedBuilder(
                animation: _pulse2,
                builder: (context, _) => _buildPulseRing(_pulse2.value),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/worktrackr.png',
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'WorkTrackr',
          style: AppTextStyles.headlineXl.copyWith(
            color: Theme.of(context).colorScheme.surface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'SECURE IDENTITY PLATFORM',
          style: AppTextStyles.labelXs.copyWith(
            color: Theme.of(context).colorScheme.inversePrimary.withValues(alpha: 0.8),
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPulseRing(double value) {
    return Container(
      width: 72 + (value * 48),
      height: 72 + (value * 48),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: (1 - value) * 0.25),
          width: 1,
        ),
      ),
    );
  }

  Widget _buildLoadingArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _statuses[_statusIndex],
                style: AppTextStyles.labelXs.copyWith(
                  color: Theme.of(context).colorScheme.inversePrimary,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                '$_percent%',
                style: AppTextStyles.labelXs.copyWith(
                  color: Theme.of(context).colorScheme.inversePrimary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 3,
              width: double.infinity,
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
              child: AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, _) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progressAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.secondaryFixed,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDecorativeIcon(Icons.fingerprint),
              const SizedBox(width: 20),
              _buildDecorativeIcon(Icons.location_on_outlined),
              const SizedBox(width: 20),
              _buildDecorativeIcon(Icons.wifi),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDecorativeIcon(IconData icon) {
    return Icon(
      icon,
      size: 18,
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.4),
    );
  }
}

class _CyberGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 0.5;
    const step = 40.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
