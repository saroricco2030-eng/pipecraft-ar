import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../shell/main_shell.dart';

/// 전체화면 스플래시 노출 시간. 너무 짧으면 사용자 인지 전에 사라지고,
/// 너무 길면 cold start 답답함. 2초가 일반적 균형점.
const _splashDuration = Duration(seconds: 2);
const _fadeOutDuration = Duration(milliseconds: 400);

/// 앱 시작 시 전체화면 스플래시.
///
/// 2초간 표시 후 [MainShell]로 전환됩니다.
/// 상태바·네비게이션바를 숨겨 완전 몰입형으로 표시합니다.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();

    // 전체화면 몰입 모드
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: _fadeOutDuration,
    );

    Future.delayed(_splashDuration, () {
      if (!mounted) return;
      _fadeCtrl.forward().then((_) {
        if (!mounted) return;
        // 시스템 UI 복원 후 메인 화면으로
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, _, _) => const MainShell(),
            transitionDuration: Duration.zero,
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeCtrl,
      builder: (context, child) {
        return Opacity(
          opacity: 1.0 - _fadeCtrl.value,
          child: child,
        );
      },
      child: Scaffold(
        backgroundColor: AppColors.dark.splashBg,
        body: Image.asset(
          'assets/splash/splash.png',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}
