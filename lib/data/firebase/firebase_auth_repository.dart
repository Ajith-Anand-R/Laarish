import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../repositories.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final GoogleSignIn _google;

  FirebaseAuthRepository({
    FirebaseAuth? auth,
    GoogleSignIn? google,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _google = google ??
            GoogleSignIn(
              serverClientId: '186388879740-lrkvf4n90gpaqm1astl91kmgp4m2ld8j.apps.googleusercontent.com',
            );

  @override
  Stream<bool> authStateChanges() => _auth.authStateChanges().map((u) => u != null);

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  Future<void> signInWithEmail(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'Please enter both email and password.',
      );
    }
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        try {
          await _auth.createUserWithEmailAndPassword(email: email, password: password);
        } catch (_) {
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    final account = await _google.signIn();
    if (account == null) {
      throw Exception('Sign in cancelled');
    }
    final auth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );
    await _auth.signInWithCredential(credential);
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    await _google.signOut();
  }
}
