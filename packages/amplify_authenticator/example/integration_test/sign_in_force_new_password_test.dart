import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_authenticator/amplify_authenticator.dart';
import 'package:amplify_authenticator/src/keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'config.dart';
import 'pages/confirm_sign_in_page.dart';
import 'pages/sign_in_page.dart';
import 'pages/test_utils.dart';
import 'utils/data_utils.dart';
import 'utils/mock_data.dart';

// This test follows the Amplify UI feature "sign-in-force-new-password"
// https://github.com/aws-amplify/amplify-ui/blob/main/packages/e2e/features/ui/components/authenticator/sign-in-force-new-password.feature

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // resolves issue on iOS. See: https://github.com/flutter/flutter/issues/89651
  binding.deferFirstFrame();

  final authenticator = MaterialApp(
    home: Authenticator(
      child: const SizedBox.shrink(),
    ),
  );

  group('Sign In with Force New Password flow', () {
    final username = generatePhone();
    final phoneNumber = username.substring(2); // without '+1'
    final password = generatePassword();

    // Background
    setUpAll(() async {
      // Given I'm running the example
      // "ui/components/authenticator/sign-in-with-phone"
      await loadConfiguration(
        'ui/components/authenticator/sign-in-with-phone',
        additionalConfigs: [AmplifyAPI()],
      );
      await adminCreateUser(username, password);
    });

    // Scenario: Sign in using a valid phone number and password and user is in
    // a FORCE_CHANGE_PASSWORD state
    testWidgets(
      'Sign in using a valid phone number and password and user is in a '
      'FORCE_CHANGE_PASSWORD state',
      (WidgetTester tester) async {
        final po = SignInPage(tester: tester);
        await loadAuthenticator(tester: tester, authenticator: authenticator);

        // When I select my country code with status "FORCE_CHANGE_PASSWORD"
        await po.selectCountryCode();

        // And I type my "phone number" with status "FORCE_CHANGE_PASSWORD"
        await po.enterUsername(phoneNumber);

        // And I type my password
        await po.enterPassword(password);

        // And I click the "Sign in" button
        await po.submitSignIn();

        // Then I should see the Force Change Password screen
        po.expectScreen(AuthScreen.confirmSigninNewPassword);
      },
    );

    // Scenario: User is in a FORCE_CHANGE_PASSWORD state and then enters an
    // invalid new password
    testWidgets(
      'Scenario: User is in a FORCE_CHANGE_PASSWORD state and then enters an '
      'invalid new password',
      (WidgetTester tester) async {
        final po = SignInPage(tester: tester);
        await loadAuthenticator(tester: tester, authenticator: authenticator);

        // When I select my country code with status "FORCE_CHANGE_PASSWORD"
        await po.selectCountryCode();

        // And I type my "phone number" with status "FORCE_CHANGE_PASSWORD"
        await po.enterUsername(phoneNumber);

        // And I type my password
        await po.enterPassword(password);

        // And I click the "Sign in" button
        await po.submitSignIn();

        po.expectScreen(AuthScreen.confirmSigninNewPassword);
        final cpo = ConfirmSignInPage(tester: tester);

        // And I type an invalid password
        await cpo.enterNewPassword('a');

        // And I confirm the invalid password
        await cpo.enterPasswordConfirmation('a');

        // And I click the "Change Password" button
        await cpo.submitConfirmSignIn();

        // Then I should see error text
        cpo.expectInputError(
          keyNewPasswordConfirmSignInFormField,
          'Password must include',
        );
      },
    );
  });
}
