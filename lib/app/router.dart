import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../core/motion/laarish_motion.dart';
import '../features/auth/login_screen.dart';
import '../features/garden_home/garden_home_screen.dart';
import '../features/level_engine/level_screen.dart';
import '../features/mentor/mentor_screen.dart';
import '../features/onboarding/curiosity_questions_screen.dart';
import '../features/onboarding/profession_screen.dart';
import '../features/onboarding/qr_screen.dart';
import '../features/onboarding/splash_screen.dart';
import '../features/onboarding/story_video_screen.dart';
import '../features/onboarding/welcome_intro_screen.dart';
import '../features/profile/settings_screen.dart';
import '../features/roadmap/roadmap_screen.dart';
import '../features/rewards/badge_book_screen.dart';
import '../features/rewards/certificate_screen.dart';
import '../features/shell/vine_nav_bar.dart';

/// Stable navigator identities. The ShellRoute's nested navigator MUST have a
/// constant key — without it go_router regenerates the key when you enter the
/// shell from an outside route (e.g. a level's reward → /map), which corrupts
/// the element tree ("_elements.contains(element) is not true").
final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

/// Shared cinematic page transition — a subtle 3D perspective swing + depth
/// scale + fade, so every navigation feels like a card turning in space
/// rather than a flat Material slide (PLAN.md "AAA casual game" feel). Used
/// for every route so the whole app moves as one world.
CustomTransitionPage<void> _page(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: LaarishMotion.transition,
    reverseTransitionDuration: LaarishMotion.transition,
    child: child,
    transitionsBuilder: (context, animation, secondary, child) {
      return AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final curve = animation.status == AnimationStatus.reverse
              ? Curves.easeInCubic
              : Curves.easeOutCubic;
          final t = curve.transform(animation.value.clamp(0.0, 1.0));
          final rotateY = (1 - t) * 0.45; // swings in from the side
          final scale = 0.88 + 0.12 * t;
          return Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015)
                ..rotateY(rotateY)
                ..scaleByDouble(scale, scale, 1, 1),
              child: child,
            ),
          );
        },
      );
    },
  );
}

/// Route table frozen — ARCHITECTURE.md §3, PARALLEL_AGENTS.md §3.
/// Explicit navigation only (screens call context.go); no auth-redirect
/// middleware yet — speculative until a real gated flow needs it (YAGNI).
final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', pageBuilder: (c, s) => _page(const SplashScreen(), s)),
    GoRoute(path: '/login', pageBuilder: (c, s) => _page(const LoginScreen(), s)),
    GoRoute(path: '/qr', pageBuilder: (c, s) => _page(const QrScreen(), s)),
    GoRoute(path: '/profession', pageBuilder: (c, s) => _page(const ProfessionScreen(), s)),
    GoRoute(path: '/intro', pageBuilder: (c, s) => _page(const WelcomeIntroScreen(), s)),
    GoRoute(path: '/story', pageBuilder: (c, s) => _page(const StoryVideoScreen(), s)),
    GoRoute(path: '/questions', pageBuilder: (c, s) => _page(const CuriosityQuestionsScreen(), s)),
    GoRoute(
      path: '/level/:plant/:n',
      pageBuilder: (c, s) => _page(
        LevelScreen(
          plantId: s.pathParameters['plant']!,
          level: int.parse(s.pathParameters['n']!),
        ),
        s,
      ),
    ),
    GoRoute(path: '/certificate', pageBuilder: (c, s) => _page(const CertificateScreen(), s)),
    // Hub routes share the persistent Growing Vine Dock nav bar. Order MUST
    // match VineShell.routes (map · garden · mentor · badges · settings).
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) =>
          VineShell(location: state.uri.toString(), child: child),
      routes: [
        GoRoute(path: '/map', pageBuilder: (c, s) => _page(const RoadmapScreen(), s)),
        GoRoute(path: '/garden', pageBuilder: (c, s) => _page(const GardenHomeScreen(), s)),
        GoRoute(path: '/mentor', pageBuilder: (c, s) => _page(const MentorScreen(), s)),
        GoRoute(path: '/badges', pageBuilder: (c, s) => _page(const BadgeBookScreen(), s)),
        GoRoute(path: '/settings', pageBuilder: (c, s) => _page(const SettingsScreen(), s)),
      ],
    ),
  ],
);
