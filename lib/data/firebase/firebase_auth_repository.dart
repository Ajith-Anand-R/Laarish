import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../repositories.dart';

class FirebaseAuthRepository implements AuthRepository {
  final _auth = FirebaseAuth.instance;
  final _google = GoogleSignIn();

  @override
  Stream<bool> authStateChanges() => _auth.authStateChanges().map((u) => u != null);

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        await _auth.createUserWithEmailAndPassword(email: email, password: password);
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    final account = await _google.signIn();
    if (account == null) return; // user cancelled
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
