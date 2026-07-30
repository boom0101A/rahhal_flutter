import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rahhal_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:rahhal_flutter/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:rahhal_flutter/features/auth/presentation/screens/auth_screen.dart';
import 'package:rahhal_flutter/shared/widgets/gradient_button.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;

  setUp(() {
    repository = _MockAuthRepository();
  });

  Future<void> pumpScreen(WidgetTester tester, {bool isLogin = true}) async {
    // The form is taller than the default 800x600 test surface (especially
    // in register mode with extra fields), which would leave the mode-toggle
    // link unmounted/off-screen. A tall surface fits everything in one frame.
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar', 'AE'),
        supportedLocales: const [Locale('ar', 'AE'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: BlocProvider<AuthCubit>(
          create: (_) => AuthCubit(repository: repository),
          child: AuthScreen(isLogin: isLogin),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('login mode shows only email + password, no name/confirm fields',
      (tester) async {
    await pumpScreen(tester);

    expect(find.widgetWithText(TextFormField, 'البريد الإلكتروني'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'كلمة المرور'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'الاسم الكامل'), findsNothing);
    expect(find.widgetWithText(TextFormField, 'تأكيد كلمة المرور'), findsNothing);
    expect(find.text('تسجيل الدخول'), findsWidgets);
  });

  testWidgets('tapping "no account" switches to register mode and reveals name/confirm fields',
      (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('ليس لديك حساب؟'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, 'الاسم الكامل'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'تأكيد كلمة المرور'), findsOneWidget);
    expect(find.text('إنشاء حساب'), findsWidgets);
  });

  testWidgets('submitting with an invalid email shows a validation error and never calls the repository',
      (tester) async {
    await pumpScreen(tester);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'البريد الإلكتروني'), 'not-an-email');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'كلمة المرور'), 'validpass123');

    await tester.tap(find.byType(GradientButton));
    await tester.pump();

    expect(find.text('بريد إلكتروني غير صالح'), findsOneWidget);
    verifyNever(() => repository.signInWithEmail(any(), any()));
  });

  testWidgets('submitting with a too-short password shows a validation error',
      (tester) async {
    await pumpScreen(tester);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'البريد الإلكتروني'), 'user@example.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'كلمة المرور'), '123');

    await tester.tap(find.byType(GradientButton));
    await tester.pump();

    expect(find.text('كلمة مرور يجب أن تكون 6 أحرف على الأقل'), findsOneWidget);
    verifyNever(() => repository.signInWithEmail(any(), any()));
  });
}
