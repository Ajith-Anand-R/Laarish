import 'dart:async';
import '../repositories.dart';

/// Used only when Firebase isn't configured yet (no google-services.json /
/// GoogleService-Info.plist — run `flutterfire configure`, see AGENT.md).
/// Lets the app run and be play-tested offline in the meantime: any
/// email/password "signs in" instantly, no network call.
class StubAuthRepository implements AuthRepository {
  final _controller = StreamController<bool>.broadcast();
  bool _signedIn = false;

  @override
  Stream<bool> authStateChanges() async* {
    yield _signedIn;
    yield* _controller.stream;
  }

  @override
  String? get currentUserId => _signedIn ? 'local-child' : null;

  @override
  Future<void> signInWithEmail(String email, String password) async {
    _signedIn = true;
    _controller.add(_signedIn);
  }

  @override
  Future<void> signInWithGoogle() async {
    _signedIn = true;
    _controller.add(_signedIn);
  }

  @override
  Future<void> signOut() async {
    _signedIn = false;
    _controller.add(_signedIn);
  }
}
