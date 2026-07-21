import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../core/motion/laarish_motion.dart';
import '../features/auth/login_screen.dart';
import '../features/garden_home/garden_home_screen.dart';
import '../features/level_engine/checkpoint_screen.dart';
import '../features/level_engine/level_screen.dart';
import '../features/level_engine/plant_complete_screen.dart';
import '../features/mentor/mentor_screen.dart';
import '../features/onboarding/curiosity_questions_screen.dart';
import '../features/onboarding/profession_screen.dart';
import '../features/onboarding/qr_screen.dart';
import '../features/onboarding/splash_screen.dart';
import '../features/onboarding/story_video_screen.dart';
import '../features/onboarding/welcome_intro_screen.dart';
import '../features/profile/settings_screen.dart';
import '../features/progress/progress_screen.dart';
import '../features/roadmap/plant_levels_screen.dart';
import '../features/roadmap/plant_select_screen.dart';
import '../features/rewards/certificate_screen.dart';
import '../features/shell/vine_nav_bar.dart';

/// Stable navigator identities. The ShellRoute's nested navigator MUST have a
/// constant key — without it go_router regenerates the key when you enter the
/// shell from an outside route (e.g. a level's reward → /map), which corrupts
/// the element tree ("_elements.contains(element) is not true").
final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

/// Shared cinematic page transition — a true 3D camera move rather than a
/// flat Material slide (PLAN.md "AAA casual game" feel). Used for every route
/// so the whole app moves as one world.
///
/// Both halves of the transition are animated, which is what makes it read as
/// *depth* instead of a cross-fade:
///   • the **incoming** page swings in from the side, rises out of depth and
///     overshoots slightly into place (anticipation → follow-through);
///   • the **outgoing** page (driven by `secondaryAnimation`) recedes away
///     from the camera, tilts and dims — so at the midpoint you are looking
///     at two cards at different distances, not one dissolving into another.
///
/// The perspective entry (`setEntry(3, 2, …)`) is what gives the rotation real
/// foreshortening; without it a rotateY is just a horizontal squash.
CustomTransitionPage<void> _page(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: LaarishMotion.transition,
    reverseTransitionDuration: const Duration(milliseconds: 380),
    child: child,
    transitionsBuilder: (context, animation, secondary, child) {
      return AnimatedBuilder(
        animation: Listenable.merge([animation, secondary]),
        child: child,
        builder: (context, child) {
          final entering = animation.status != AnimationStatus.reverse;
          final t = (entering
                  ? LaarishMotion.overshoot.transform(
                      animation.value.clamp(0.0, 1.0))
                  : Curves.easeInCubic.transform(
                      animation.value.clamp(0.0, 1.0)))
              .toDouble();
          final inv = 1 - t;

          // How far this page has been pushed *back* by a newer one on top.
          final s = Curves.easeInOutCubic.transform(
            secondary.value.clamp(0.0, 1.0),
          );

          final scale = (0.86 + 0.14 * t) * (1 - 0.14 * s);

          return Opacity(
            opacity: (animation.value.clamp(0.0, 1.0)) * (1 - 0.55 * s),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015)
                // Incoming: swing + rise from depth. Outgoing: sink away.
                ..translateByDouble(90 * inv, 0, -320 * inv - 220 * s, 1)
                ..rotateY(0.45 * inv - 0.22 * s)
                ..rotateX(0.10 * s)
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
    // Post-video gate: photo upload + verification + level quiz, then reward.
    GoRoute(
      path: '/checkpoint/:plant/:n',
      pageBuilder: (c, s) => _page(
        CheckpointScreen(
          plantId: s.pathParameters['plant']!,
          level: int.parse(s.pathParameters['n']!),
        ),
        s,
      ),
    ),
    // Plant finished (all 5 levels) — vegetable-specific harvest celebration.
    GoRoute(
      path: '/plant-done/:plant',
      pageBuilder: (c, s) => _page(
        PlantCompleteScreen(plantId: s.pathParameters['plant']!),
        s,
      ),
    ),
    // Hub routes share the persistent Growing Vine Dock nav bar. Order MUST
    // match VineShell.routes (map · garden · mentor · progress · settings).
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) =>
          VineShell(location: state.uri.toString(), child: child),
      routes: [
        GoRoute(path: '/map', pageBuilder: (c, s) => _page(const PlantSelectScreen(), s)),
        GoRoute(
          path: '/plant/:plant',
          pageBuilder: (c, s) => _page(
            PlantLevelsScreen(plantId: s.pathParameters['plant']!),
            s,
          ),
        ),
        GoRoute(path: '/garden', pageBuilder: (c, s) => _page(const GardenHomeScreen(), s)),
        GoRoute(path: '/mentor', pageBuilder: (c, s) => _page(const MentorScreen(), s)),
        GoRoute(path: '/progress', pageBuilder: (c, s) => _page(const ProgressScreen(), s)),
        GoRoute(path: '/settings', pageBuilder: (c, s) => _page(const SettingsScreen(), s)),
      ],
    ),
  ],
);
