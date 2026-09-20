import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/providers/onboarding_provider.dart';
import '../../features/auth/domain/models/app_user.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';

import '../../features/dashboard/presentation/screens/home_screen.dart';
import '../../features/dashboard/presentation/screens/admin_dashboard_screen.dart';

import '../../features/members/domain/models/member_profile.dart';
import '../../features/members/presentation/screens/profile_screen.dart';
import '../../features/members/presentation/screens/edit_profile_screen.dart';
import '../../features/members/presentation/screens/admin_members_screen.dart';
import '../../features/members/presentation/screens/member_detail_screen.dart';

import '../../features/campaigns/domain/models/campaign.dart';
import '../../features/campaigns/presentation/screens/campaign_detail_screen.dart';
import '../../features/campaigns/presentation/screens/admin_campaigns_screen.dart';
import '../../features/campaigns/presentation/screens/create_edit_campaign_screen.dart';

import '../../features/pledges/domain/models/pledge.dart';
import '../../features/pledges/presentation/screens/my_pledges_screen.dart';
import '../../features/pledges/presentation/screens/make_pledge_screen.dart';
import '../../features/pledges/presentation/screens/admin_pledges_screen.dart';

import '../../features/contributions/presentation/screens/submit_contribution_screen.dart';
import '../../features/contributions/presentation/screens/my_contributions_screen.dart';
import '../../features/contributions/presentation/screens/admin_verification_screen.dart';

import '../../features/receipts/presentation/screens/receipt_view_screen.dart';

import '../../features/transparency/presentation/screens/admin_transparency_settings_screen.dart';
import '../../features/transparency/presentation/screens/contributors_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/notifications/presentation/screens/admin_notifications_screen.dart';
import '../../features/notifications/presentation/screens/user_notifications_screen.dart';

import '../widgets/app_shell.dart';
import '../widgets/admin_shell.dart';
import '../widgets/placeholder_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final hasSeenOnboarding = ref.watch(onboardingCompletedProvider);

  final initialRoute = kIsWeb
      ? (hasSeenOnboarding ? '/login' : '/welcome')
      : '/splash';

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: initialRoute,
    redirect: (context, state) {
      final user = authState.value;
      final isAuth = user != null;
      final path = state.uri.path;

      final unauthLanding = hasSeenOnboarding ? '/login' : '/welcome';

      if (path == '/') {
        if (isAuth) {
          return user.role == UserRole.MEMBER ? '/home' : '/admin/dashboard';
        }
        return kIsWeb ? unauthLanding : '/splash';
      }

      final isSplash = path == '/splash';
      final isVerify = path.startsWith('/verify');
      final isAuthRoute =
          path == '/welcome' ||
          path == '/login' ||
          path == '/register' ||
          path == '/forgot-password';

      // Allow public access to receipt verification
      if (isVerify) return null;

      // When auth is still loading, allow public routes and don't stall web on splash
      if (authState.isLoading) {
        if (kIsWeb && isSplash) return unauthLanding;
        return null;
      }

      // Not authenticated
      if (!isAuth) {
        if (isSplash || !isAuthRoute) return unauthLanding;
        if (path == '/welcome' && hasSeenOnboarding) return '/login';
        return null;
      }

      // If authenticated, also ensure onboarding is completed in preferences
      if (!hasSeenOnboarding) {
        ref.read(onboardingCompletedProvider.notifier).completeOnboarding();
      }

      // Authenticated — check email verification
      final isVerified = ref.read(authRepositoryProvider).isEmailVerified;
      final isVerifyRoute = path == '/email-verification';

      if (!isVerified) {
        return isVerifyRoute ? null : '/email-verification';
      }
      if (isVerifyRoute) {
        return user.role == UserRole.MEMBER ? '/home' : '/admin/dashboard';
      }

      // Redirect splash / auth screens away
      if (isSplash || isAuthRoute) {
        return user.role == UserRole.MEMBER ? '/home' : '/admin/dashboard';
      }

      // Members cannot access admin routes
      if (path.startsWith('/admin') && user.role == UserRole.MEMBER) {
        return '/home';
      }

      // Admins accessing /profile → redirect to /admin/profile
      if (path == '/profile' && user.role != UserRole.MEMBER) {
        return '/admin/profile';
      }

      return null;
    },
    routes: [
      // ── Auth screens (no bottom nav) ────────────────────────────────────
      GoRoute(path: '/splash', builder: (context, _) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (context, _) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (context, _) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/email-verification',
        builder: (context, _) => const EmailVerificationScreen(),
      ),
      GoRoute(
        path: '/verify/:receiptId',
        builder: (context, state) => ReceiptViewScreen(
          receiptId: state.pathParameters['receiptId']!,
        ),
      ),

      // ── Member shell: Home | Pledges | Profile ──────────────────────────
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, _, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, _) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'notifications',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, _) => const UserNotificationsScreen(),
                  ),
                  GoRoute(
                    path: 'campaign',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, _) => const CampaignDetailScreen(),
                    routes: [
                      GoRoute(
                        path: 'pledge',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) => MakePledgeScreen(
                          campaign: state.extra as Campaign,
                        ),
                      ),
                      GoRoute(
                        path: 'contributors',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) => ContributorsScreen(
                          campaignId: (state.extra as Campaign).id,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/pledges',
                builder: (context, _) => const MyPledgesScreen(),
                routes: [
                  GoRoute(
                    path: 'contributions',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => MyContributionsScreen(
                      pledge: state.extra as Pledge,
                    ),
                  ),
                  GoRoute(
                    path: 'submit',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => SubmitContributionScreen(
                      pledge: state.extra as Pledge,
                    ),
                  ),
                  GoRoute(
                    path: 'receipt/:receiptId',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => ReceiptViewScreen(
                      receiptId: state.pathParameters['receiptId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, _) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => EditProfileScreen(
                      profile: state.extra as MemberProfile,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // ── Admin shell: Dashboard | Members | Reports | Profile ─────────────
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, _, navigationShell) =>
            AdminShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/dashboard',
                builder: (context, _) => const AdminDashboardScreen(),
                routes: [
                  GoRoute(
                    path: 'campaigns',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, _) => const AdminCampaignsScreen(),
                    routes: [
                      GoRoute(
                        path: 'create',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, _) => const CreateEditCampaignScreen(),
                      ),
                      GoRoute(
                        path: 'edit',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) => CreateEditCampaignScreen(
                          campaign: state.extra as Campaign,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'contributors',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => ContributorsScreen(
                      campaignId: (state.extra as Campaign).id,
                    ),
                  ),
                  GoRoute(
                    path: 'verify',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, _) => const AdminVerificationScreen(),
                  ),
                  GoRoute(
                    path: 'transparency',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, _) => const AdminTransparencySettingsScreen(),
                  ),
                  GoRoute(
                    path: 'pledges',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, _) => const AdminPledgesScreen(),
                  ),
                  GoRoute(
                    path: 'payments',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, _) => const PlaceholderScreen(title: 'Admin Payments'),
                  ),
                  GoRoute(
                    path: 'receipts',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, _) => const PlaceholderScreen(title: 'Admin Receipts'),
                  ),
                  GoRoute(
                    path: 'notifications',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, _) => const AdminNotificationsScreen(),
                  ),
                  GoRoute(
                    path: 'audit-logs',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, _) => const PlaceholderScreen(title: 'Audit Logs'),
                  ),
                  GoRoute(
                    path: 'settings',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, _) => const PlaceholderScreen(title: 'Admin Settings'),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/members',
                builder: (context, _) => const AdminMembersScreen(),
                routes: [
                  GoRoute(
                    path: ':uid',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) =>
                        MemberDetailScreen(uid: state.pathParameters['uid']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/reports',
                builder: (context, _) => const ReportsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/profile',
                builder: (context, _) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => EditProfileScreen(
                      profile: state.extra as MemberProfile,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
