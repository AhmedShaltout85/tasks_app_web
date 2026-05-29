import 'package:flutter/material.dart';
import 'package:tasks_app/common_widgets/custom_widgets/custom_text.dart';
import 'package:tasks_app/utils/app_assets.dart';
import 'package:tasks_app/utils/app_route.dart';

import '../../common_widgets/resuable_widgets/reusable_widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _pulseController;

  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _logoController.forward().then((_) {
      _textController.forward();
      _pulseController.repeat(reverse: true);
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        navigateToReplacementNamed(context, AppRoute.authWrapperRouteName);
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final kHeight = size.height;
    final kWidth = size.width;
    final isSmallScreen = kHeight < 600;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withOpacity(0.05),
              colorScheme.surface,
              colorScheme.primary.withOpacity(0.03),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _logoFadeAnimation.value,
                    child: Transform.scale(
                      scale: _logoScaleAnimation.value,
                      child: Image.asset(
                        AppAssets.taskSplashLogo,
                        height: isSmallScreen ? kHeight * 0.45 : kHeight * 0.5,
                        width: isSmallScreen ? kWidth * 0.6 : kWidth * 0.55,
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),
              const Spacer(flex: 1),
              SlideTransition(
                position: _textSlideAnimation,
                child: FadeTransition(
                  opacity: _textFadeAnimation,
                  child: Column(
                    children: [
                      CustomText(
                        text: 'قطاع التكنولوجيا والخدمات الرقمية',
                        fontSize: isSmallScreen ? 16 : 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      SizedBox(height: isSmallScreen ? 6 : 10),
                      CustomText(
                        text: 'إدارة البرامج وصيانتها',
                        fontSize: isSmallScreen ? 13 : 16,
                        fontWeight: FontWeight.normal,
                        color: colorScheme.onSurfaceVariant,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 2),
              FadeTransition(
                opacity: _textFadeAnimation,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: colorScheme.primary,
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: isSmallScreen ? 24 : 48),
            ],
          ),
        ),
      ),
    );
  }
}
