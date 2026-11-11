import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gym_app_mobile/core/theme/app_theme.dart';
import 'package:gym_app_mobile/features/auth/models/auth_models.dart';
import 'package:gym_app_mobile/features/auth/screens/gym_picker_screen.dart';
import 'package:gym_app_mobile/features/auth/screens/sign_in_screen.dart';
import 'package:gym_app_mobile/features/auth/screens/welcome_screen.dart';
import 'package:gym_app_mobile/features/auth/services/auth_service.dart';
import 'package:gym_app_mobile/features/auth/widgets/auth_widgets.dart';

const _gyms = [
  Gym(id: 'g1', name: 'Iron Works'),
  Gym(id: 'g2', name: 'Modern Fitness Gym', primaryColor: '#FF7A00'),
  Gym(id: 'g3', name: 'Pulse Studio'),
];
const _gym = Gym(id: 'g1', name: 'Iron Works');

class _FakeAuthService implements AuthService {
  final Map<String, CheckMemberResult> accounts;
  final List<RequestOtpDto> otpRequests = [];

  _FakeAuthService({this.accounts = const {}});

  @override
  Future<List<Gym>> getGyms() async => _gyms;

  @override
  Future<CheckMemberResult> checkMember({
    required String gymId,
    String? email,
    String? phone,
  }) async =>
      accounts[email ?? phone] ??
      const CheckMemberResult(exists: false, hasPassword: false);

  @override
  Future<OtpResponse> requestOtp(RequestOtpDto dto) async {
    otpRequests.add(dto);
    return const OtpResponse(status: 'sent');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app(Widget home, [_FakeAuthService? auth]) => ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(auth ?? _FakeAuthService()),
      ],
      child: MaterialApp(theme: AppTheme.darkTheme, home: home),
    );

void _useSmallPhone(WidgetTester tester, {double keyboard = 0}) {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  addTearDown(tester.view.reset);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  group('AuthIdentifier', () {
    test('accepts an email or a phone number in one field', () {
      expect(AuthIdentifier.parse(' Sam@Gym.com ')!.email, 'sam@gym.com');
      expect(AuthIdentifier.parse('+254 712-345 678')!.phone, '+254712345678');
      expect(AuthIdentifier.parse('sam@'), isNull);
      expect(AuthIdentifier.parse('12ab'), isNull);
      expect(AuthIdentifier.looksLikePhone('+2547'), isTrue);
      expect(AuthIdentifier.looksLikePhone('sam'), isFalse);
    });
  });

  testWidgets('welcome offers the last gym first', (tester) async {
    SharedPreferences.setMockInitialValues({'auth.last_gym_id': 'g2'});
    _useSmallPhone(tester);

    await tester.pumpWidget(_app(const WelcomeScreen()));
    await _settle(tester);

    expect(find.text('Continue to'), findsOneWidget);
    expect(find.text('Modern Fitness Gym'), findsOneWidget);
    expect(find.text('Choose a different gym'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('welcome asks a new phone to find its gym', (tester) async {
    SharedPreferences.setMockInitialValues({});
    _useSmallPhone(tester);

    await tester.pumpWidget(_app(const WelcomeScreen()));
    await _settle(tester);

    expect(find.text('Find your gym'), findsOneWidget);
    expect(find.text('Continue to'), findsNothing);

    await tester.tap(find.text('Find your gym'));
    await _settle(tester);
    expect(find.text('Where do you\ntrain?'), findsOneWidget);
  });

  testWidgets('gym picker search filters and explains no match', (tester) async {
    SharedPreferences.setMockInitialValues({'auth.last_gym_id': 'g1'});
    _useSmallPhone(tester);

    await tester.pumpWidget(_app(const GymPickerScreen()));
    await _settle(tester);

    expect(find.text('Last used on this phone'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'pulse');
    await tester.pump();
    expect(find.text('Pulse Studio'), findsOneWidget);
    expect(find.text('Iron Works'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    expect(find.textContaining('No gym called'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sign in keeps the button above the keyboard on a small phone',
      (tester) async {
    _useSmallPhone(tester, keyboard: 280);

    await tester.pumpWidget(_app(const SignInScreen(gym: _gym)));
    await _settle(tester);

    final button = tester.getRect(find.text('Continue'));
    expect(button.bottom, lessThan(640 - 280));
    expect(tester.takeException(), isNull);
  });

  testWidgets('an email with a password goes to the password step', (tester) async {
    _useSmallPhone(tester);
    final auth = _FakeAuthService(accounts: {
      'coach@gym.com': const CheckMemberResult(exists: true, hasPassword: true),
    });

    await tester.pumpWidget(_app(const SignInScreen(gym: _gym), auth));
    await _settle(tester);
    await tester.enterText(find.byType(TextField), 'Coach@Gym.com');
    await tester.tap(find.text('Continue'));
    await _settle(tester);

    expect(find.text('Enter your password'), findsOneWidget);
    expect(find.text('coach@gym.com'), findsOneWidget);
    expect(auth.otpRequests, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a first-time email gets a sign-in link', (tester) async {
    _useSmallPhone(tester);
    final auth = _FakeAuthService(accounts: {
      'new@gym.com': const CheckMemberResult(exists: true, hasPassword: false),
    });

    await tester.pumpWidget(_app(const SignInScreen(gym: _gym), auth));
    await _settle(tester);
    await tester.enterText(find.byType(TextField), 'new@gym.com');
    await tester.tap(find.text('Continue'));
    await _settle(tester);

    expect(find.text('Check your email'), findsOneWidget);
    expect(auth.otpRequests.single.email, 'new@gym.com');
  });

  testWidgets('a phone number gets a text code', (tester) async {
    _useSmallPhone(tester);
    final auth = _FakeAuthService(accounts: {
      '+254712345678': const CheckMemberResult(exists: true, hasPassword: true),
    });

    await tester.pumpWidget(_app(const SignInScreen(gym: _gym), auth));
    await _settle(tester);
    await tester.enterText(find.byType(TextField), '+254 712 345 678');
    await tester.tap(find.text('Continue'));
    await _settle(tester);

    expect(find.text('Enter the 6-digit code'), findsOneWidget);
    expect(auth.otpRequests.single.phone, '+254712345678');
    expect(tester.takeException(), isNull);
  });

  testWidgets('an unknown contact explains what to do', (tester) async {
    _useSmallPhone(tester);

    await tester.pumpWidget(_app(const SignInScreen(gym: _gym)));
    await _settle(tester);
    await tester.enterText(find.byType(TextField), 'who@else.com');
    await tester.tap(find.text('Continue'));
    await _settle(tester);

    expect(find.textContaining('doesn\'t have who@else.com on file'), findsOneWidget);
  });
}
