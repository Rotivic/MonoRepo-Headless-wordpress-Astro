import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tcg_platform_mobile/features/authentication/presentation/view/login_page.dart';

import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('App muestra LoginPage', (tester) async {
    final repo = MockAuthRepository();

    when(
      () => repo.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => makeLoginResult());

    await pumpLoginApp(tester, authRepository: repo);

    expect(find.byType(LoginPage), findsOneWidget);
  });
}
