import 'package:flutter_test/flutter_test.dart';
import 'package:fitwithus/utils/validators.dart';

void main() {
  group('Username validation', () {
    test('Valid username', () {
      expect(Validators.isUsernameValid('TestUser123'), true);
    });

    test('Too short username', () {
      expect(Validators.isUsernameValid('abc'), false);
    });

    test('Invalid characters', () {
      expect(Validators.isUsernameValid('user@123'), false);
    });
  });

  group('Password validation', () {
    test('Valid password', () {
      expect(Validators.isPasswordValid('secret'), true);
    });

    test('Too short password', () {
      expect(Validators.isPasswordValid('123'), false);
    });
  });

  group('Weight validation', () {
    test('Valid weight', () {
      expect(Validators.isWeightValid('75'), true);
    });

    test('Too high weight', () {
      expect(Validators.isWeightValid('1000'), false);
    });

    test('Non-numeric weight', () {
      expect(Validators.isWeightValid('abc'), false);
    });
  });

  group('Height validation', () {
    test('Valid height', () {
      expect(Validators.isHeightValid('180'), true);
    });

    test('Too short height', () {
      expect(Validators.isHeightValid('50'), false);
    });

    test('Non-numeric height', () {
      expect(Validators.isHeightValid('tall'), false);
    });
  });

  group('Combined weight/height/birthdate validation', () {
    test('Valid input returns null', () {
      final result = Validators.validateWeightHeightAndBirthDate(
        weightText: '70',
        heightText: '180',
        birthDate: DateTime(2000, 1, 1),
      );
      expect(result, isNull);
    });

    test('Missing fields return error', () {
      final result = Validators.validateWeightHeightAndBirthDate(
        weightText: '',
        heightText: '',
        birthDate: null,
      );
      expect(result, 'All fields are required.');
    });

    test('Invalid weight returns error', () {
      final result = Validators.validateWeightHeightAndBirthDate(
        weightText: 'abc',
        heightText: '170',
        birthDate: DateTime(2000, 1, 1),
      );
      expect(result, contains('Weight'));
    });

    test('Invalid height returns error', () {
      final result = Validators.validateWeightHeightAndBirthDate(
        weightText: '70',
        heightText: '20',
        birthDate: DateTime(2000, 1, 1),
      );
      expect(result, contains('Height'));
    });
  });

  group('RegisterStep1 validation', () {
    test('Valid input returns null', () {
      final result = Validators.validateRegisterStep1(
        email: 'test@example.com',
        username: 'ValidUser',
        password: 'secret123',
        confirmPassword: 'secret123',
      );
      expect(result, isNull);
    });

    test('Invalid email returns error', () {
      final result = Validators.validateRegisterStep1(
        email: 'invalid',
        username: 'ValidUser',
        password: 'secret123',
        confirmPassword: 'secret123',
      );
      expect(result, contains('valid email'));
    });

    test('Password mismatch returns error', () {
      final result = Validators.validateRegisterStep1(
        email: 'test@example.com',
        username: 'ValidUser',
        password: 'secret123',
        confirmPassword: 'other123',
      );
      expect(result, contains('Passwords do not match'));
    });
  });
}
