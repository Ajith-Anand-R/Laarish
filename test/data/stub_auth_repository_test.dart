import 'package:flutter_test/flutter_test.dart';
import 'package:laarish/data/firebase/stub_auth_repository.dart';

void main() {
  test('currentUserId is null before any sign-in (first frame, signed out)', () {
    final repo = StubAuthRepository();
    expect(repo.currentUserId, isNull);
  });

  test('currentUserId is non-null after sign-in, null again after sign-out', () async {
    final repo = StubAuthRepository();
    await repo.signInWithEmail('a@b.com', 'pw');
    expect(repo.currentUserId, isNotNull);

    await repo.signOut();
    expect(repo.currentUserId, isNull);
  });

  test('authStateChanges() first emission reflects signed-out state on first frame', () async {
    final repo = StubAuthRepository();
    final first = await repo.authStateChanges().first;
    expect(first, false);
  });

  test('signInWithGoogle also sets currentUserId', () async {
    final repo = StubAuthRepository();
    await repo.signInWithGoogle();
    expect(repo.currentUserId, isNotNull);
  });
}
