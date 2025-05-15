import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitwithus/services/firebase_register_service.dart';

import 'firebase_register_service_test.mocks.dart';

@GenerateMocks([
  FirebaseAuth,
  UserCredential,
  User,
  CollectionReference,
  DocumentReference,
])
void main() {
  late MockFirebaseAuth mockAuth;
  late MockCollectionReference mockUsersCollection;
  late MockDocumentReference mockUserDoc;
  late MockUserCredential mockCredential;
  late MockUser mockUser;
  late FirebaseRegisterService registerService;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockUsersCollection = MockCollectionReference();
    mockUserDoc = MockDocumentReference();
    mockCredential = MockUserCredential();
    mockUser = MockUser();

    registerService = FirebaseRegisterService.test(
      auth: mockAuth,
      usersCollection: mockUsersCollection,
    );
  });

  test('registerUser creates user and saves data to Firestore', () async {
    when(mockAuth.createUserWithEmailAndPassword(
      email: anyNamed('email'),
      password: anyNamed('password'),
    )).thenAnswer((_) async => mockCredential);

    when(mockCredential.user).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('test_uid');
    when(mockUser.sendEmailVerification()).thenAnswer((_) async => null);
    when(mockUsersCollection.doc('test_uid')).thenReturn(mockUserDoc);
    when(mockUserDoc.set(any)).thenAnswer((_) async => null);

    final result = await registerService.registerUser(
      email: 'test@example.com',
      password: 'secret123',
      username: 'testuser',
      weight: 70,
      height: 170,
      gender: 'Male',
      birthDate: DateTime(2000, 1, 1),
    );

    expect(result, equals(mockUser));
    verify(mockAuth.createUserWithEmailAndPassword(
      email: 'test@example.com',
      password: 'secret123',
    )).called(1);

    verify(mockUser.sendEmailVerification()).called(1);
    verify(mockUsersCollection.doc('test_uid')).called(1);
    verify(mockUserDoc.set(any)).called(1);
  });
}
