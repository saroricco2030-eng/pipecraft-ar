// PipeCraft AR — 위젯 smoke test
//
// 실제 MyApp 부팅은 SplashScreen의 Future.delayed + AnimationController
// 때문에 위젯 테스트에서 Timer pending 에러가 발생한다. 통합 동작은
// integration_test 디렉토리에서 다루고, 여기선 단순 빌드 가능성만 본다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipe_craft_ar/core/theme/app_theme.dart';

void main() {
  testWidgets('AppTheme builds light/dark themes without errors',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
