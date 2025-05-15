import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fitwithus/services/firebase_auth_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_auth_service_test.mocks.dart';

@GenerateMocks([FirebaseAuth, GoogleSignIn, UserCredential, User])
void main() {
  late MockFirebaseAuth mockAuth;
  late MockUserCredential mockCredential;
  late FirebaseAuthService authService;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockCredential = MockUserCredential();
    authService = FirebaseAuthService.test(
      auth: mockAuth,
      googleSignIn: MockGoogleSignIn(),
    );
  });

  test('signIn returns UserCredential', () async {
    when(mockAuth.signInWithEmailAndPassword(
      email: 'test@example.com',
      password: 'password123',
    )).thenAnswer((_) async => mockCredential);

    final result = await authService.signIn('test@example.com', 'password123');
    expect(result, equals(mockCredential));
  });
}
