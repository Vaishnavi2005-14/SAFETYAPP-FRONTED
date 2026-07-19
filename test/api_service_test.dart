import 'package:flutter_test/flutter_test.dart';
import 'package:safeher/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Test API Service Signup and Login Flow', () async {
    final email = 'test_${DateTime.now().millisecondsSinceEpoch}@example.com';
    final password = 'Password123';

    final signupSuccess = await ApiService.signup(email, password);
    expect(signupSuccess, isTrue);

    final token = await ApiService.getToken();
    expect(token, isNotNull);

    await ApiService.clearSession();
    final clearedToken = await ApiService.getToken();
    expect(clearedToken, isNull);

    final loginSuccess = await ApiService.login(email, password);
    expect(loginSuccess, isTrue);

    final loginToken = await ApiService.getToken();
    expect(loginToken, isNotNull);

    final profileSuccess = await ApiService.saveProfile(
      name: 'Test Name',
      age: '25',
      phone: '1234567890',
      aadhaar: '123456789012',
      customMessage: 'Help me!',
      shakeEnabled: true,
      shakeSensitivity: 'High',
    );
    expect(profileSuccess, isTrue);

    final contactsSuccess = await ApiService.saveContacts([
      {'name': 'Contact 1', 'phone': '9876543210'},
    ]);
    expect(contactsSuccess, isTrue);

    final syncSuccess = await ApiService.syncWithServer();
    expect(syncSuccess, isTrue);
  });
}
